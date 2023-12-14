/*
This document holds SQL queries with brief comments.
Andreas Montelius 2023-12-14

Table of contents

    How many page views was generated for a specific day?
    How many users are active day by day?
    How many sessions?
    What is the time spent per page_url (hashed)?
    How many customers are active day by day?
    What is the activity for different user roles (user types)

*/



/*
    How many page views was generated for a specific day?
*/

  SELECT 
  EXTRACT(DATE FROM derived_tstamp) calendar_date,
  COUNT(*) counts
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  WHERE event_name = 'page_view'
  GROUP BY calendar_date
  ORDER BY calendar_date 



/*
    How many users are active day by day?
       Assuming all event types reflect user activity
*/
 
 SELECT 
  EXTRACT(DATE FROM derived_tstamp) calendar_date,
  COUNT(DISTINCT user_id) distinct_users
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  GROUP BY calendar_date
  ORDER BY calendar_date 


/*
    How many sessions?
        Count sessions per date 
*/

 SELECT 
  EXTRACT(DATE FROM derived_tstamp) calendar_date,
  COUNT(DISTINCT domain_sessionid) distinct_domain_sessionid
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  GROUP BY calendar_date
  ORDER BY calendar_date 


/*
    What is the time spent per page_url (hashed)?

      Here is a window function assuming that time spent is between page views. 
      I'm surprised to see that the time_spent_seconds valuse 0 and 1 dominate so much, 
      therefore I added a sorting on counts. This reveals local maxima:
      
      The same query but with: 
      ORDER BY count DESC  
           31 sec  and 30 sec stand out as very high counts compared to neighboring times, this calls for further investigation.
     
*/

WITH PageViews AS (
  SELECT
    user_id,
    domain_sessionid,
    hashed_page_url,
    derived_tstamp,
    LEAD(derived_tstamp) OVER (PARTITION BY user_id, domain_sessionid ORDER BY derived_tstamp) AS next_view_tstamp
  FROM   `snowplow-cto-office.snowplow_hackathonPI.events_hackathon`

),

TimeSpent AS (
  SELECT
    user_id,
    domain_sessionid,
    hashed_page_url,
    TIMESTAMP_DIFF(next_view_tstamp, derived_tstamp, SECOND) AS time_spent_seconds
  FROM
    PageViews
  WHERE
    next_view_tstamp IS NOT NULL
)

SELECT
  time_spent_seconds,
  COUNT(*) AS count
FROM
  TimeSpent
GROUP BY
  time_spent_seconds
ORDER BY
  time_spent_seconds;



/*
    How many customers are active day by day?
       Here hashed_customer_name is used to count customers
*/

 SELECT 
  EXTRACT(DATE FROM derived_tstamp) calendar_date,
  COUNT(DISTINCT hashed_customer_name) distinct_hashed_customer_name
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  GROUP BY calendar_date
  ORDER BY calendar_date 


/*
    What is the activity for different user roles (user types)
       Looking in user_type didn't yield other than 'admin',
       Exploring user_registered reveals many rows '1900-01-01' possibly reperenting a test class
       Short of other success, the last query unnests link_click_element_classes, a possible segmenting strategy
*/

--First try, using user_type
  SELECT 
  user_type, 
  COUNT(DISTINCT user_id) distinct_users
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  GROUP BY  user_type
  ORDER BY distinct_users

--looking at user_registered could give a hint
 SELECT 
  DISTINCT user_registered,
  COUNT (*) counts,
  FROM `snowplow-cto-office.snowplow_hackathonPI.events_hackathon` 
  GROUP BY user_registered
  ORDER BY user_registered

--Unnest link_click_element_classes in search for ways to segment users into types
SELECT
  element,
  COUNT(*) as occurrence
FROM
  `snowplow-cto-office.snowplow_hackathonPI.events_hackathon`,
  UNNEST(link_click_element_classes) as element
GROUP BY
  element
ORDER BY
  occurrence DESC







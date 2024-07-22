{{
  config({    
    "materialized": "table",
    "database": 'ntong',
    "schema": 'test'
  })
}}

WITH orders_data AS (

  SELECT * 
  
  FROM {{ ref('orders_data')}}

),

Lower_case AS (

  SELECT 
    order_id AS order_id,
    order_date AS order_date,
    lower(status) AS status,
    updated_date AS updated_date
  
  FROM orders_data AS in0

),

Set_Active_Flags AS (

  SELECT 
    order_id AS order_id,
    order_date AS order_date,
    status AS status,
    updated_date AS updated_date,
    CASE
      WHEN status = lower('ordered')
        THEN 'Y'
      WHEN status = lower('cancelled')
        THEN 'N'
      WHEN status = lower('in_transit')
        THEN 'Y'
      WHEN status = lower('completed')
        THEN 'N'
    END AS active_flag
  
  FROM Lower_case AS in0

)

SELECT *

FROM Set_Active_Flags

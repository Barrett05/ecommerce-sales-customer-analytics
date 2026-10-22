-- E-Commerce Sales & Customer Analytics
-- Tool: Google BigQuery
-- Dataset: bigquery-public-data.thelook_ecommerce

-- 1. Monthly Revenue and Order Performance
SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,

    COUNT(DISTINCT order_id) AS completed_orders,

    ROUND(SUM(sale_price), 2) AS total_revenue,

    ROUND(
        SAFE_DIVIDE(
            SUM(sale_price),
            COUNT(DISTINCT order_id)
        ),
        2
    ) AS average_order_value

FROM `bigquery-public-data.thelook_ecommerce.order_items`

WHERE status = 'Complete'

GROUP BY order_month

ORDER BY order_month;

-- 2. Product Category Performance
-- Calculate revenue, gross profit, and gross profit margin
-- by product category

SELECT
    p.category,

    ROUND(SUM(oi.sale_price), 2) AS total_revenue,

    ROUND(SUM(oi.sale_price - p.cost), 2) AS gross_profit,

    ROUND(
        SAFE_DIVIDE(
            SUM(oi.sale_price - p.cost),
            SUM(oi.sale_price)
        ) * 100,
        2
    ) AS gross_profit_margin

FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id

WHERE oi.status = 'Complete'

GROUP BY p.category

ORDER BY gross_profit_margin DESC;

-- 3. Customer Retention Analysis
-- Calculate total customers, repeat customers,
-- and the repeat customer rate

WITH customer_orders AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS order_count

    FROM `bigquery-public-data.thelook_ecommerce.order_items`

    WHERE status = 'Complete'

    GROUP BY user_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNTIF(order_count >= 2) AS repeat_customers,

    ROUND(
        COUNTIF(order_count >= 2) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate

FROM customer_orders;

-- 4. Customer Retention and Spending Analysis
-- Compare one-time and repeat customers
-- by customer count, revenue, and average spending

CREATE OR REPLACE VIEW
`case-study-2-472406.ecommerce_analytics.customer_retention`
AS

WITH customer_orders AS (
    SELECT
        user_id,
        COUNT(*) AS total_orders
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE status = 'Complete'
    GROUP BY user_id
),

customer_revenue AS (
    SELECT
        o.user_id,
        SUM(oi.sale_price) AS revenue
    FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
    JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'Complete'
      AND oi.status = 'Complete'
    GROUP BY o.user_id
)

SELECT
    CASE
        WHEN co.total_orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS total_customers,

    ROUND(SUM(cr.revenue), 2) AS total_revenue,

    ROUND(AVG(cr.revenue), 2) AS average_customer_spend

FROM customer_orders AS co

JOIN customer_revenue AS cr
    ON co.user_id = cr.user_id

GROUP BY customer_type;

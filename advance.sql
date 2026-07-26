-- Rank sellers by revenue using RANK() or DENSE_RANK()
select seller_id,total_revenue , dense_rank() over(order by total_revenue desc) from
(select seller_id ,round(sum(price),2) as total_revenue from olist_order_items_dataset
    GROUP BY seller_id) as seller_revenue;
    
-- Calculate Month-over-Month (MoM) revenue growth.
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)

SELECT
    order_year,
    order_month,
    total_revenue,
    LAG(total_revenue) OVER (
        ORDER BY order_year, order_month
    ) AS previous_month_revenue,
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER (
            ORDER BY order_year, order_month
        )) /
        LAG(total_revenue) OVER (
            ORDER BY order_year, order_month
        )) * 100,
        2
    ) AS mom_growth_percent
FROM monthly_revenue;

-- Calculate cumulative monthly revenue using window functions.
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)

SELECT
    order_year,
    order_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY order_year, order_month
    ) AS cumulative_revenue
FROM monthly_revenue;

-- Find each state's contribution to total revenue.
SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS state_revenue,
    ROUND(
        (SUM(oi.price) /
        (SELECT SUM(price) FROM olist_order_items_dataset)) * 100,
        2
    ) AS revenue_contribution_percent
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue_contribution_percent DESC;

-- Find the highest-selling product in each category.
WITH product_sales AS (
    SELECT
        p.product_category_name,
        oi.product_id,
        COUNT(oi.product_id) AS quantity_sold
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name,
        oi.product_id
)

SELECT
    product_category_name,
    product_id,
    quantity_sold
FROM (
    SELECT
        product_category_name,
        product_id,
        quantity_sold,
        RANK() OVER (
            PARTITION BY product_category_name
            ORDER BY quantity_sold DESC
        ) AS product_rank
    FROM product_sales
) AS ranked_products
WHERE product_rank = 1
ORDER BY product_category_name;

-- Find the most popular payment method in each state.
WITH payment_count AS (
    SELECT
        c.customer_state,
        op.payment_type,
        COUNT(*) AS total_payments
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
        ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset op
        ON o.order_id = op.order_id
    GROUP BY
        c.customer_state,
        op.payment_type
)

SELECT
    customer_state,
    payment_type,
    total_payments
FROM (
    SELECT
        customer_state,
        payment_type,
        total_payments,
        RANK() OVER (
            PARTITION BY customer_state
            ORDER BY total_payments DESC
        ) AS payment_rank
    FROM payment_count
) AS ranked_payment
WHERE payment_rank = 1
ORDER BY customer_state;

-- Compare weekday vs weekend sales.
select case when dayofweek(order_purchase_timestamp) in (1,7)
then 'weekend' else 'weekday'
end as data_type , round(sum(oi.price),2) as total_revenue 
from olist_orders_dataset o join olist_order_items_dataset oi
on o.order_id=oi.order_id 
group by data_type ;

-- Segment customers into High, Medium, and Low spenders using CASE WHEN.
select c.customer_unique_id, round(sum(op.payment_value),2) as total_spending,
case
when sum(op.payment_value)>=1000 then 'high spender'
when sum(op.payment_value)>=500 then 'medium spender'
else 'low spender'
end as customer_segement 
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spending DESC; 

-- Find repeat customers (customers who placed more than one order).
SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;

-- Create a sales summary report showing:
-- Total Revenue,Total Orders,Total Customers,Average Order Value,Average Delivery Time,Cancellation Rate

SELECT
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 2) AS average_delivery_time_days,
    ROUND(
        (COUNT(CASE
            WHEN o.order_status = 'canceled' THEN 1
        END) * 100.0) / COUNT(DISTINCT o.order_id),
        2
    ) AS cancellation_rate_percent
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
LEFT JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id;
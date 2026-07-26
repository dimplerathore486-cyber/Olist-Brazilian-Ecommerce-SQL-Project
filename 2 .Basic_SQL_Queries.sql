-- 1.Total number of customers.
SELECT 
    COUNT(*) AS total_customer
FROM
    olist_customers_dataset;

-- 2.Total number of orders.

SELECT 
    COUNT(*) AS total_order
FROM
    olist_orders_dataset;

-- 3. Total number of sellers.
SELECT 
    COUNT(*) AS total_seller
FROM
    olist_sellers_dataset;
    
-- 4.Total number of products.

SELECT 
    COUNT(*) AS total_product
FROM
    olist_products_dataset;
    
-- 5.Order status distribution.

SELECT 
    order_status, COUNT(*) AS total_orders
FROM
    olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- 6.Orders placed each month.
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    MONTHNAME(order_purchase_timestamp) as month_name ,
    COUNT(*) AS total_orders
FROM
    olist_orders_dataset
GROUP BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp) , MONTHNAME(order_purchase_timestamp)
ORDER BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp);

-- 7.Customers by state.

SELECT 
    customer_state, COUNT(*) AS total_customer
FROM
    olist_customers_dataset
GROUP BY customer_state
ORDER BY total_customer DESC;

-- 8.Average order value.

SELECT 
    ROUND(AVG(order_total), 2) AS avg_order_value
FROM
    (SELECT 
        order_id, SUM(payment_value) AS order_total
    FROM
        olist_order_payments_dataset
    GROUP BY order_id) AS order_payment;

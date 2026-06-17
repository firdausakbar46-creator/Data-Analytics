# Objective 2

-- 1. View the orders details_table 
SELECT *
FROM restaurant_db.order_details;

-- 2. What is the date range of the table
SELECT min(order_date), max(order_date) 
FROM restaurant_db.order_details;

-- 3. How many orders we made within this date range?
SELECT count(distinct order_id)
FROM restaurant_db.order_details;

-- 4. How many items were ordered within this date range?
SELECT COUNT(*)
FROM restaurant_db.order_details;

-- 5. Which orders had the most number of items?
SELECT order_id, count(item_id) AS num_items
FROM restaurant_db.order_details
GROUP BY order_id
ORDER BY num_items DESC;

-- 6. How many orders had more than 12 items?
SELECT count(*)
fROM 

(SELECT order_id, count(item_id) AS num_items
FROM restaurant_db.order_details
GROUP BY order_id
HAVING num_items > 12) AS num_orders;
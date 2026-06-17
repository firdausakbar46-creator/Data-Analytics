

-- 1. menampilkan order_details
SELECT *
FROM pizza_sales_db.order_details;

-- 2. mencari jumlah dari order_detaails
SELECT COUNT(*)
FROM pizza_sales_db.order_details;

-- 3. mencari jumlah kuantitas berdasarkan order_id
SELECT order_id, count(order_id) AS quntity_by_order_id
FROM pizza_sales_db.order_details
GROUP BY order_id;

-- 4. mencari mana order_id dengan kuantitas yang paling banyak
SELECT order_id, count(order_id) AS quantity_by_order_id
FROM pizza_sales_db.order_details
GROUP BY order_id
ORDER BY quantity_by_order_id DESC
LIMIT 10;

-- 5. Mencari berapa banyak pepperoni_m dan s semua ukuran pada pizza_id
SELECT count(*)
FROM pizza_sales_db.order_details
WHERE pizza_id= 'pepperoni_m';

SELECT count(*)
FROM pizza_sales_db.order_details
WHERE pizza_id= 'pepperoni_s';

-- 6. Berapa banyak setiap kategori pada pizza_id
SELECT pizza_id, count(quantity) AS quantity_each_category
FROM pizza_sales_db.order_details
GROUP BY pizza_id;

-- 7. Berapa min dan max kuantitas tiap kategori
SELECT pizza_id, count(quantity) AS quantity_each_category
FROM pizza_sales_db.order_details
GROUP BY pizza_id
ORDER BY quantity_each_category DESC
LIMIT 10;

SELECT pizza_id, count(quantity) AS quantity_each_category
FROM pizza_sales_db.order_details
GROUP BY pizza_id
ORDER BY quantity_each_category
LIMIT 10;
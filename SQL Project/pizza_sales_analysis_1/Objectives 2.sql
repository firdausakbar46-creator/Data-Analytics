-- 1. menampilkan pizzas tabel
SELECT *
FROM pizza_sales_db.pizzas;

-- 2. jangkauan (range) tabel harga pizzas
SELECT min(price), max(price)
FROM pizza_sales_db.pizzas;

-- 3. berapa banyak size yang terjual
SELECT size, COUNT(*)
FROM pizza_sales_db.pizzas
GROUP BY size;

-- 4. jumlah tipe pizza id yang paling banyak
SELECT pizza_type_id, COUNT(pizza_type_id) AS num_type_pizza
FROM pizza_sales_db.pizzas
GROUP BY pizza_type_id
ORDER BY num_type_pizza DESC
;

-- 5. Berapa banyak tipe pizza id yang harganya lebih dari 15
SELECT COUNT(*)
FROM

(SELECT pizza_type_id, SUM(price) AS num_price
FROM pizza_sales_db.pizzas
GROUP BY pizza_type_id
HAVING num_price > 45) AS num_order;
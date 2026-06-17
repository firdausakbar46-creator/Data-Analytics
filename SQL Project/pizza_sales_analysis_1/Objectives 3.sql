-- 1. menampilkan dan menggabungkan tabel order_details dan pizzas

SELECT *
FROM pizza_sales_db.order_details;

SELECT *
FROM pizza_sales_db.pizzas;

SELECT *
FROM order_details od LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id;
    
-- 2. jumlah paling banyak dan paling sedikit dari pizza_type_id
SELECT pizza_type_id, size, COUNT(price) AS num_price
FROM order_details od LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id
GROUP BY pizza_type_id, size
ORDER BY num_price;

-- 3 Top 5 yang paling banyak spend uang berdasarkan order_id
SELECT order_id, SUM(price) AS sum_price
FROM order_details od LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id
GROUP BY order_id
ORDER BY sum_price
LIMIT 5;

-- 4. Menampilkan salah satu spend order paling tinggi berdasarkan order_id
SELECT *
FROM order_details od LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id
WHERE order_id= 211;

-- 5. Menampilkan Top 5 spend order berdasarkan order_id
SELECT *
FROM order_details od LEFT JOIN pizzas p
	ON od.pizza_id = p.pizza_id
WHERE order_id IN (211, 112, 398, 132, 417);









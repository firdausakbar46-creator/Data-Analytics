-- 1. Menampilkan tabel orders

SELECT * 
FROM pizza_sales_2.orders;

-- 2. Jumlah tabel order
SELECT COUNT(*)
FROM pizza_sales_2.orders;

-- 3. Mengurutkan bagian tanggal dari yang terkecil dan sebaliknya pada tabel orders
SELECT *
FROM pizza_sales_2.orders
ORDER BY date DESC;

SELECT *
FROM pizza_sales_2.orders
ORDER BY date;

-- 4. Menampilkan order_id diatas 15000
SELECT *
FROM pizza_sales_2.orders
HAVING order_id > 15000;

-- 5. order_id yang lebih dari 15000 diurutkan secara desc
SELECT *
FROM pizza_sales_2.orders
HAVING order_id > 15000
ORDER BY order_id DESC;
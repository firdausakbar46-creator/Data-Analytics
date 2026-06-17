-- 1. Menampilkan tabel pizza_types
SELECT *
FROM pizza_sales_2.pizza_types;

-- 2. menghitung jumlah tabel pizza_types
SELECT COUNT(*)
FROM pizza_sales_2.pizza_types;

-- 3. Mengelompokkan kolom kategori dan menghitung jumlahnya
SELECT category, COUNT(category) AS num_category
FROM pizza_sales_2.pizza_types

-- 4. Menampilkan makanan
GROUP BY category;

-- 4. Menampilkan nama makanan berdasarkan kategori supreme
SELECT*
FROM pizza_sales_2.pizza_types
WHERE category IN ('Supreme','Classic');


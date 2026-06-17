-- 1. Menampilkan dictionary playoffs
SELECT *
FROM jordan_lebron_playoffs.playoffs_data_dictionary;

-- 2. Menampilkan tabel jordan playoffs
SELECT *
FROM jordan_lebron_playoffs.jordan_playoffs;

-- 3. Menampilkan jumlah data tabel
SELECT COUNT(*)
FROM jordan_lebron_playoffs.jordan_playoffs;

-- 4. Menampilkan rata-rata orb, drb, trb, ast, stl, blk, tov
SELECT SUM(orb), SUM(drb), SUM(trb), SUM(ast), SUM(stl), SUM(blk), SUM(tov)
FROM jordan_lebron_playoffs.jordan_playoffs;

-- 5. Menampilkan jumlah minute play jordan
SELECT SUM(mp)
FROM jordan_lebron_playoffs.jordan_playoffs;

-- 6. Jumlah series game diatas 3
SELECT *
FROM jordan_lebron_playoffs.jordan_playoffs
HAVING series_game > 3;

-- 7. Menampilkan kategori series dan jumlahnya
SELECT series, COUNT(series) AS num_series
FROM jordan_lebron_playoffs.jordan_playoffs
GROUP BY series;

-- 8. Menampilkan opp CLE dan MIA dan mengurutkan berdasarkan series game
SELECT *
FROM jordan_lebron_playoffs.jordan_playoffs
WHERE opp IN ('CLE', 'MIA')
ORDER BY series_game;

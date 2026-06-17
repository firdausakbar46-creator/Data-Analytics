-- 1. Menaampilkan dictionary playoffs
SELECT *
FROM jordan_lebron_playoffs.playoffs_data_dictionary;

-- 2. Menampilkan tabel lebron_playoffs
SELECT *
FROM jordan_lebron_playoffs.lebron_playoffs;

-- 3. Menampilkan jumlah data tabel 
SELECT COUNT(*)
FROM jordan_lebron_playoffs.lebron_playoffs;

-- 4. Menampilkan rata-rata orb, drb, trb, ast, stl, blk
SELECT AVG(orb), AVG(drb), AVG(trb), AVG(ast), AVG(stl), AVG(blk), AVG(blk)
FROM jordan_lebron_playoffs.lebron_playoffs;

-- 5. Menampilkan jumlah minute play Lebron
SELECT SUM(mp)
FROM jordan_lebron_playoffs.lebron_playoffs;

-- 6. Jumlah series game diatas 3
SELECT *
FROM jordan_lebron_playoffs.lebron_playoffs
HAVING series_game > 3;

-- 7. Menampilkan kategori series dan jumlahnya
SELECT series, COUNT(series) AS num_series
FROM jordan_lebron_playoffs.lebron_playoffs
GROUP BY series;

-- 8. Menampilkan opp CHI dan WAS
SELECT *
FROM jordan_lebron_playoffs.lebron_playoffs
WHERE opp IN ('CHI', 'WAS')
ORDER BY series_game;

SELECT *
FROM jordan_lebron_playoffs.lebron_playoffs
WHERE opp IN ('CHI', 'WAS')
ORDER BY series_game DESC;

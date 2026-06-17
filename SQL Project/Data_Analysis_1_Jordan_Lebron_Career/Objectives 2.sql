-- 1. Menampilkan data dictionary
SELECT *
FROM jordan_lebron_data.career_data_dictionary;

-- 2. Menampilkan data tabel lebron_career
SELECT *
FROM jordan_lebron_data.lebron_career;

-- 3. Jumlah data pada tabel lebron_career
SELECT COUNT(*)
FROM jordan_lebron_data.lebron_career;

-- 4. Total minute play pada lebron_career
SELECT SUM(mp)
FROM jordan_lebron_data.lebron_career; #Total minute play 46619

-- 5. Ada berapa tim yang pernah dibela oleh Lebron dan berapa pertandingan setiap timnya
SELECT team
FROM jordan_lebron_data.lebron_career
GROUP BY team; #terdapat 3 tim yang pernah dibela

SELECT team, COUNT(team) AS num_match
FROM jordan_lebron_data.lebron_career
GROUP BY team;

-- 6. Total ada berapa jumlah per tim yang pernah dilawan Lebron
SELECT opp, COUNT(OPP) AS num_opp
FROM jordan_lebron_data.lebron_career
GROUP BY opp;

-- 7. Menampilkan rata-rata dari orb, drb, trb, ast, stl, blk, tov
SELECT AVG(orb), AVG(drb), AVG(ast), AVG(stl), AVG(blk), AVG(tov)
FROM jordan_lebron_data.lebron_career;

-- 8. Jumlah permainan pada opp CHI dan WAS
SELECT opp, result
FROM jordan_lebron_data.lebron_career
WHERE opp IN ('CHI', 'WAS')
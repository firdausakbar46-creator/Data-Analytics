-- 1. Menampilkan data dictionary
SELECT *
FROM jordan_lebron_data.career_data_dictionary;

-- 2. Menampilkan tabel jordan_career
SELECT *
FROM jordan_lebron_data.jordan_career;

-- 3. Jumlah data tabel jordan_career
SELECT COUNT(*)
FROM jordan_lebron_data.jordan_career;

-- 4. Total Minute play jordan_career
SELECT SUM(mp)
FROM jordan_lebron_data.jordan_career; #Total menit bermain 40061

-- 5. Ada berapa tim yang pernah dibela jordan dan total pertangdingan pada tiap tim
SELECT team
FROM jordan_lebron_data.jordan_career
GROUP BY team; #Ada 2 tim yaitu Chicago Bulls dan Washington DC

SELECT team, COUNT(team) AS num_match
FROM jordan_lebron_data.jordan_career
GROUP BY team; #Total Match, Chi = 916 dan Was = 126


-- 6. Total ada berapa jumlah per tim yang pernah dilawan oleh jordan
SELECT opp, COUNT(opp) AS num_opp
FROM jordan_lebron_data.jordan_career
group by opp;

SELECT team, opp, COUNT(opp) AS num_opp
FROM jordan_lebron_data.jordan_career
group by team, opp;

-- 7. Menampilkan rata-rata dari orb, drb, trb, ast, stl, blk, tov
SELECT AVG(orb), AVG(drb), AVG(trb), AVG(ast), AVG(stl), AVG(blk), AVG(tov)
FROM jordan_lebron_data.jordan_career;


-- 8. Jumlah permainan pada opp CLE dan MIA
SELECT opp, result
FROM jordan_lebron_data.jordan_career
WHERE opp IN ('CLE', 'MIA')



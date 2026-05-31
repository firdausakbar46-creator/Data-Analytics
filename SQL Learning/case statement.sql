-- CASE STATEMENT

SELECT first_name,
last_name,
age,

CASE
	WHEN age <= 30 THEN 'Young'
    WHEN age BETWEEN 31 AND 50 THEN 'Old'
    WHEN age >= 50 THEN 'hell is coming'
END AS age_bracket

FROM employee_demographics
;




-- Pay Increase and bonus
-- < 5000 = 5%
-- > 5000 = 7%
-- Finance = 10%

SELECT first_name, last_name, salary,

CASE
	WHEN salary < 50000 THEN salary + (salary * 0.05)
    WHEN salary > 50000 THEN salary + (salary * 0.07)
END AS new_salary,
CASE
	WHEN dept_id = 6 THEN salary * 0.1
END AS finance_dept_salary
FROM employee_salary;

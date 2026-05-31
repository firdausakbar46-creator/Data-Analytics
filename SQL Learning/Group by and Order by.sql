-- Group by

select *
from employee_demographics;

select gender, avg(age), max(age), min(age), count(age)
from employee_demographics
group by gender
;

-- order by
select *
from employee_demographics
order by gender, age
;
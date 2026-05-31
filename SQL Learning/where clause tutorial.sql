-- where clause

select *
from employee_salary
where first_name = 'leslie'
;

select *
from employee_salary
where salary <= 50000
;

select *
from employee_demographics
where birth_date > '1987-01-01'
;


-- AND OR NOT - Logical Operators

select *
from employee_demographics
where (first_name = 'leslie' and age = 44) or age > 55 
;


-- LIKE Statement
-- % and _
select *
from employee_demographics
where birth_date LIKE '1989%'
;
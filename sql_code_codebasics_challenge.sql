#CODEBASICS_SQL_PROJECT_CHALLENGE

#TASK 1 : 
SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";


#TASK 2
WITH unique_products AS (
    SELECT 
        fiscal_year, 
        COUNT(DISTINCT Product_code) as unique_products 
    FROM 
        fact_gross_price 
    GROUP BY 
        fiscal_year
)
SELECT 
    up_2020.unique_products as unique_products_2020,
    up_2021.unique_products as unique_products_2021,
    round((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) as percentage_change
FROM 
    unique_products up_2020
CROSS JOIN 
    unique_products up_2021
WHERE 
    up_2020.fiscal_year = 2020 
    AND up_2021.fiscal_year = 2021;


#TASK 3
SELECT segment, count(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


#TASK 4
with cte1 as (
with cte as (SELECT 
    p.segment,
    COUNT(DISTINCT p.product_code) AS product_count_2020
FROM
    dim_product p
        JOIN
    fact_sales_monthly s ON p.product_code = s.product_code
WHERE
    s.fiscal_year = 2020
GROUP BY p.segment
ORDER BY product_count_2020 DESC)

SELECT 
    c.*, COUNT(DISTINCT p.product_code) AS product_count_2021
FROM
    cte c
        JOIN
    dim_product p ON c.segment = p.segment
        JOIN
    fact_sales_monthly s ON p.product_code = s.product_code
WHERE
    s.fiscal_year = 2021
GROUP BY p.segment
ORDER BY product_count_2021 DESC)

SELECT 
    *, product_count_2021 - product_count_2020 AS difference
FROM
    cte1
ORDER BY difference DESC;


#TASK 5
SELECT m.product_code, concat(product," (",variant,")") AS product, cost_year,manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
WHERE manufacturing_cost= 
(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
or 
manufacturing_cost = 
(SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY manufacturing_cost DESC;


#TASK 6
SELECT 
    c.customer_code,
    c.customer,
    ROUND(AVG(i.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions i
        JOIN
    dim_customer c ON c.customer_code = i.customer_code
WHERE
    market = 'India' AND fiscal_year = 2021
GROUP BY customer , customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


#TASK 7
WITH temp_table AS (
    SELECT 
    customer,
    MONTHNAME(date) AS months,
    MONTH(date) AS month_number,
    YEAR(date) AS year,
    (sold_quantity * gross_price) AS gross_sales
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    customer = 'Atliq exclusive'
)
SELECT 
    months,
    year,
    CONCAT(ROUND(SUM(gross_sales) / 1000000, 2),
            'M') AS gross_sales
FROM
    temp_table
GROUP BY year , months
ORDER BY year , months;

#TASK 8
WITH temp_table AS (
  SELECT date,month(date_add(date,interval 4 month)) AS period, fiscal_year,sold_quantity 
FROM fact_sales_monthly
)
SELECT CASE 
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" END quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quanity_in_millions FROM temp_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quanity_in_millions DESC ;


#TASK 9
with temp_table as (SELECT 
    c.channel,
    sum(s.sold_quantity * g.gross_price) AS gross_sales_mln
FROM
    fact_gross_price g
        JOIN
    fact_sales_monthly s ON s.product_code = g.product_code
        JOIN
    dim_customer c ON c.customer_code = s.customer_code
WHERE
    s.fiscal_year = 2021
GROUP BY channel
ORDER BY gross_sales_mln DESC
)

Select 
	channel,
	round(gross_sales_mln/1000000,2) AS gross_sales_in_millions,
    round(gross_sales_mln/(sum(gross_sales_mln) OVER())*100,2) AS percentage
 from temp_table;
 
 
 #TASK 10
With temp_table  as (
select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity, 
rank() OVER (PARTITION BY p.division ORDER BY sum(s.sold_quantity) desc) AS rank_order
from dim_product p
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by division, product, product_code)

select * from temp_table  where rank_order <= 3
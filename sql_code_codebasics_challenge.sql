select * from final_table;

-- Q1: Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct(market) from dim_customer

where customer="Atliq Exclusive" and
region="APAC";

-- Q2 What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields
-- unique_products_2020
-- unique_products_2021
-- percentage_chg


with 
cte20 as
(select count(distinct(product_code)) as unique_products_2020
from fact_manufacturing_cost as f 
where cost_year=2020),
cte21 as
(select count(distinct(product_code)) as unique_products_2021
from fact_manufacturing_cost as f 
where cost_year=2021)

select *,
		round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as percentage_chg		
from cte20
cross join
cte21;

-- Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields, 
-- segment 
-- product_count

SELECT 
    segment, COUNT(DISTINCT product_code) AS count
FROM
    dim_product
GROUP BY segment
ORDER BY count DESC;


-- Q4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference

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
ORDER BY difference DESC


-- Q5. Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost

SELECT 
    m.product_code,
    CONCAT(product, ' (', variant, ')') AS product,
    manufacturing_cost
FROM
    fact_manufacturing_cost m
        JOIN
    dim_product p ON m.product_code = p.product_code
WHERE
    manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;



-- Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage

SELECT 
    c.customer_code,
    c.customer,
    ROUND(AVG(i.pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions i
        JOIN
    dim_customer c ON c.customer_code = i.customer_code
WHERE
    market = 'India' AND fiscal_year = 2021
GROUP BY customer , customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- Q7. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity,
-- Quarter 
-- total_sold_quantity

WITH temp_table AS (
  SELECT date,month(date_add(date,interval 4 month)) AS period, fiscal_year,sold_quantity 
FROM fact_sales_monthly
)

SELECT CASE 
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" END quarter,
 sum(sold_quantity) as total_sold_quantity FROM temp_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC ;



-- Q8. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage

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

-- Q9. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code

With temp_table  as (
select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity, 
rank() OVER (PARTITION BY p.division ORDER BY sum(s.sold_quantity) desc) AS rank_order
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by division, product, product_code)

select division, product_code, product, total_sold_quantity from temp_table  where rank_order <= 3	








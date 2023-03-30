select * from dim_customer;
select * from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;	
select * from fact_sales_monthly;

/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

SELECT DISTINCT market as Markets_list, customer as Customer_name, region as Region FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
*/

WITH unique_products_2020 AS(
SELECT count(DISTINCT p.product_code) AS unique_products_2020 FROM dim_product p
JOIN fact_gross_price f
ON p.product_code=f.product_code
WHERE f.fiscal_year=2020
),
unique_products_2021 AS(
SELECT count(DISTINCT p.product_code) AS unique_products_2021 FROM dim_product p
JOIN fact_gross_price f
ON p.product_code=f.product_code
WHERE f.fiscal_year=2021
)
SELECT unique_products_2020,unique_products_2021,
round(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2) AS percentage_chg
FROM unique_products_2021,unique_products_2020;

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

SELECT p.segment,count(DISTINCT p.product_code) AS product_count FROM dim_product p
GROUP BY p.segment
ORDER BY product_count DESC;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

WITH y2020 AS(
SELECT  segment,count(DISTINCT p.product_code) AS unique_products_count_2020 FROM dim_product p
JOIN fact_gross_price f
ON p.product_code=f.product_code
WHERE f.fiscal_year=2020
GROUP BY segment
),
y2021 AS(
SELECT  segment,count(DISTINCT p.product_code) AS unique_products_count_2021 FROM dim_product p
JOIN fact_gross_price f
ON p.product_code=f.product_code
WHERE f.fiscal_year=2021
GROUP BY segment
)
SELECT y2020.segment,unique_products_count_2020,unique_products_count_2021,
(unique_products_count_2021-unique_products_count_2020) as diff
FROM y2020
JOIN y2021 ON y2020.segment=y2021.segment
ORDER BY diff DESC;


/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

WITH max_min AS(
SELECT p.product_code, p.product, m.manufacturing_cost, 
rank() over(order by m.manufacturing_cost) as rank_no from dim_product p
join fact_manufacturing_cost m on p.product_code=m.product_code
)
SELECT product_code, product, manufacturing_cost FROM max_min
WHERE rank_no=1 OR rank_no = (SELECT count(rank_no) FROM max_min);


/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

SELECT c.customer_code,c.customer,ROUND((d.pre_invoice_discount_pct*100),0) as average_discount_percentage 
FROM dim_customer c
JOIN fact_pre_invoice_deductions d ON c.customer_code=d.customer_code
WHERE d.fiscal_year=2021 AND c.market="India" 
AND d.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions)
ORDER BY d.pre_invoice_discount_pct DESC
LIMIT 5;

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross Sales Amount*/

SELECT MONTH(s.date) as Month,s.fiscal_year as Year,ROUND(SUM(s.sold_quantity*g.gross_price),0) as Gross_Sales_Amount
FROM fact_gross_price g
JOIN fact_sales_monthly s ON g.product_code=s.product_code
JOIN dim_customer c ON s.customer_code=c.customer_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY Month,Year
ORDER BY Month,Year;

/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

SELECT e.Quarters,SUM(e.sold_quantity) AS total_sold_quantity FROM
(SELECT *,
CASE WHEN MONTH(date) IN(09,10,11) THEN "Q1"
	WHEN MONTH(date) IN(12,01,02) THEN "Q2"
	WHEN MONTH(date) IN(03,04,05) THEN "Q3"
ELSE "Q4"
END AS Quarters
FROM fact_sales_monthly) AS e
WHERE fiscal_year = 2020
GROUP BY e.Quarters
ORDER BY total_sold_quantity DESC;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/

SELECT * FROM(
SELECT d.division,d.product_code,d.product,
SUM(f.sold_quantity) as total_sold_quantity,
rank() over(partition by d.division order by SUM(f.sold_quantity)) as rnk FROM dim_product d
JOIN fact_sales_monthly f ON d.product_code=f.product_code
WHERE f.fiscal_year = 2021
GROUP BY d.division,d.product_code,d.product
)e
WHERE e.rnk<=3;

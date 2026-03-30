
--EXPLORE ALL OBJECTS IN THE DATABASE

SELECT * FROM INFORMATION_SCHEMA.TABLES

--Explore all columns in the database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

--Check a specific table to see the meta data
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

/*================================================================================*/

--Dimension Exploration, Identify the unique values, categories in each dimension. 
--Check how data might be grouped ornsegmented for later analysis

--Use DISTINCT (dimension)
select distinct country from gold.dim_customers

--Explore All categories in the major divisions

SELECT DISTINCT category,
subcategory,
product_name
FROM gold.dim_products
ORDER BY 1,2,3

/*=================================================================================7
*/
--DATES. understand the bounderies use min and max. datediff
SELECT 
MIN(order_date) AS first_order,
MAX(order_date) AS last_order_date
FROM gold.fact_sales

--How many years
SELECT 
MIN(order_date) AS first_order,
MAX(order_date) AS last_order_date,
DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range
FROM gold.fact_sales

SELECT 
MIN(birth_date)AS youngest,
MAX(birth_date) As oldest,
DATEDIFF(year, MIN(birth_date),  GETDATE()) AS oldest_age,
DATEDIFF(year, MAX(birth_date),  GETDATE()) AS youngest_age
FROM gold.dim_customers

/*============================================================================================*/

--MEASUREs SUM, AVG, COUNT

--Find toal sales

SELECT 
SUM(sales_amount) AS totla_sales
FROM gold.fact_sales
--Find how amnmy items are sold
SELECT 
SUM(quantity) AS totla_quantity
FROM gold.fact_sales
--Find the average sales price
SELECT 
AVG(price) AS avg_price
FROM gold.fact_sales

--Find the total number of orders
SELECT
COUNT(order_number) AS total_orders,
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales
SELECT * FROM gold.fact_sales
--Find total number of products 
SELECT COUNT (product_key) AS toatal_prodcuts

SELECT COUNT(DISTINCT product_name) as product_name_total
FRom gold.dim_products

--Find total number of customers 

SELECT COUNT (customer_key) as total_customers
from gold.dim_customers;

--Find total number of customers that placed an order

SELECT COUNT (DISTINCT customer_key) as total_customers
from gold.fact_sales;

--Generate a report that shows all key metrics
--Create the columns 

SELECT 'Total Sales' AS measure_name,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name,SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name,AVG(price) AS measure_vale FROM gold.fact_sales
Union All 
SELECT 'Total NR Orders' AS measure_name,COUNT(DISTINCT order_number) AS measure_vale FROM gold.fact_sales
UNION ALL
SELECT 'Total NR Products' AS measure_name,COUNT(product_name) AS measure_vale FROM gold.dim_products
UNION ALL
SELECT 'Total NR Customers' AS measure_name,COUNT(DISTINCT customer_key) AS measure_vale FROM gold.dim_customers

/*==============================================================================================================*/

--MAGNITUDE

--Compare the measure values by categories
--it helps to understand the importance of different categories

--Find total customers by countries


SELECT country,
Count(customer_key) AS total_customers
FRom gold.dim_customers 
GROUP BY country 
ORDER BY total_customers DESC


--Find total customers by gender
SELECT gender,
Count(customer_key) AS total_customers
FRom gold.dim_customers 
GROUP BY gender
ORDER BY total_customers DESC

--Find total products by category
SELECT
category,
Count(product_key) as total_products
from gold.dim_products 
GROUP BY category
ORDER by total_products DESC
--What is the average cost in each category?

SELECT
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost desc
--What si the total revenue generated for each category?  

SELECT 
p.category,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
Left join gold.dim_products p 
On p.product_key = f.product_key
group by category
order by total_revenue desc


--Find total revenue is genreated by each customer?

SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue desc 


--What is the distribution of sold items across countries? total quantity by countries

SELECT 
c.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key
GROUP BY 
c.country
ORDER BY total_sold_items desc 

/*===========================================================================================*/

--Ranking

--order the value of our dimensions by measure. Identify top and bottom performares

--Which 5 products generate the highest revenue
--or subcategory
SELECT TOP 5
p.subcategory,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
Left join gold.dim_products p 
On p.product_key = f.product_key
group by p.subcategory
order by total_revenue desc


--What are the top 5 worst perfroming products
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
Left join gold.dim_products p 
On p.product_key = f.product_key
group by p.product_name
order by total_revenue 


--Window function
SELECT*
FROM(

SELECT 
p.product_name,
SUM(f.sales_amount) total_revenue, 
ROW_NUMBER() OVER (order by sum(f.sales_amount) desc) as rank_products
FROM gold.fact_sales f
Left join gold.dim_products p 
On p.product_key = f.product_key
group by p.product_name)
t WHERE rank_products <= 5

-- top 5 customers with the most orders placed 
SELECT TOP 5
c.customer_key,
c.first_name,
c.last_name,
COUNT (DISTINCT order_number) as total_orders
FROM gold.fact_sales f
Left join gold.dim_customers c
On c.customer_key = f.customer_key
group by c.customer_key,
c.first_name,
c.last_name
order by total_orders desc

/*====================================================================================================================================================
This query is the process of my thinking, and the queries that I applied during data cleaning and normalisation before loading into the silver layer 
Table :
 bronze.crm_cust_info
======================================================================================================================================================
*/



select 
* 
from 
bronze.crm_cust_info
-- Check for nulls or duplicates in the primary key 
-- Expect no results 
SELECT cst_id,
Count(*)
from bronze.crm_cust_info
Group by cst_id
Having Count(*) > 1 OR cst_id IS NULL;

-- Pick one of the duplicates 
-- Rank the duplicates and find the latest record, most likely the most accurate 
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info 
WHERE cst_id = 29466;

-- Check everything, with the query below, we get everything,g and duplicates ranked 
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info;

-- To get the list of duplicate records
SELECT *
FROM (
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info )
t
WHERE flag_last != 1;

-- To get all of the unique and flagged as 1 
-- To get the list of duplicate records
SELECT *
FROM (
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info )
t
WHERE flag_last = 1;

/* Primary key has null value, and we need to filter that out, if there are more values not null 
Report to the  data source controller to see if the missing data can be populated or just ignored

*/
SELECT *
FROM (
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info )
t
WHERE flag_last = 1 AND cst_id IS NOT NULL;


-- Check for unwanted spaces
--Expectation: No result 
SELECT 
cst_firstname 
FROM bronze.crm_cust_info;

SELECT 
cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)
/*This query gives the values with spaces after trimming, meaning there are still extra spaces
Using this query with string values just changes the column names to check for extra unwanted 
spaces, I ran the query to check each column with string values */

-- To get the result without unwanted spaces
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
FROM
(SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info )
t
WHERE flag_last = 1 AND cst_id IS NOT NULL;

--Data Standardization & Consistency
--Checking for possible unique values
SELECT DISTINCT
cst_gndr
FROM 
bronze.crm_cust_info;
--We want to change the name of the value 

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,

CASE 
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER((cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
	END cst_martial_status,


CASE 
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER((cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a'
	END
	cst_gndr,
cst_create_date
FROM
(SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info )
t
WHERE flag_last = 1 AND cst_id IS NOT NULL;

-- Check if the created date is a date not a varchar
/*Table: bronze.crm_cust_info
is cleaned and transformed, ready to be uploaded into the silver layer*/

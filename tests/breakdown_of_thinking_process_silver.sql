/*====================================================================================================================================================
This query is the process of my thinking, and the queries that I applied during data cleaning and normalisation before loading into the silver layer 
from the bronze layer
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

-- Check everything, with the query below we get everything and duplicates ranked 
SELECT 
* ,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info;

-- To get the list of the duplicate records
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
in the row export tothe  data source controller to see if the missing data can be populated or just ignored

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

-- Check if the created date is a date not varchar
/*Table: bronze.crm_cust_info
is cleaned and transformed, ready to be uploaded into sthe ilver layer*/
/******************************************************************************************
*******************************************************************************************
*/


SELECT 
*
FROM
bronze.crm_prd_info


SELECT 
prd_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

-- Check for duplicates or nulls in the primary key
SELECT prd_id, 
COUNT(*)
FROM  bronze.crm_prd_info
Group BY prd_id 
Having Count(*) > 1 OR prd_id IS NULL
/* no duplicates or nulls */


/* prd_key to be divided to be able to connect to other tables in the gold layer */

SELECT 
prd_id,
prd_key,
SUBSTRING(prd_key,1, 5) AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

/*---------------------------------------------------------------
Check if we can connect the table later to bronze.erp_px_cat_g1v2 */
SELECT 
prd_id,
prd_key,
SUBSTRING(prd_key,1, 5) AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2
/*--------------------------------------------------------------------------------*/
--We need to fix the id with replacement 
SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1, 5) ,'-', '_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2
/*-----------------------------------------------------------------------------------*/

SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1, 5) ,'-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN (prd_key)) AS prd_key,
/* use LEN as we dont know how many characters after extracting from character 7 */ 
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

/* We needed to extract the prd_key in order to be able to connect to sls_prd_key in gold layer */ 

SELECT sls_prd_key
FROM 
bronze.crm_sales_details
/*  Check for extra spaces in product name */
 SELECT prd_nm
  FROM
  bronze.crm_prd_info
  WHERE prd_nm != TRIM(prd_nm)
  --No result 
 


 --Check for NULLS or NEGATIVE NUMBERS in prices 
 SELECT prd_cost
  FROM
  bronze.crm_prd_info
  WHERE prd_cost < 0 OR prd_cost IS NULL
  --Nulls check with the data source controller if you are allowed to replace Null with zero



SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1, 5) ,'-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN (prd_key)) AS prd_key,
/* use LEN as we don't know how many characters after extracting from character 7 */ 
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info


/* Product Line we have the abbreviation, but want the full name in this case,e we ask if we can
Add the full name, and what are the acceptable values
*/

SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1, 5) ,'-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN (prd_key)) AS prd_key,
/* use LEN as we don't know how many characters after extracting from character 7 */ 
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,


CASE WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'n/a'
	END AS prd_line,

CAST(prd_start_dt AS DATE ) AS prd_start_dt,

CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)- 1 AS DATE) AS prd_end_dt

FROM bronze.crm_prd_info

-- Check the quality of the start and end date 
SELECT 
*
from bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt
/* Some end dates are earlier than the start date; in this case, we need the data controller
to double-check what to do with them. Log in data quality issue log.
In this case swaping does not make sense as the price does not match, so take the start date 
and recreate the end date based on the price, where the end date will be the start 
of the following record -1 day*/

/*SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)- 1 as test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

/**************************************************************************************************
********************************************************************************************* */

*/
Select 
*
FROM 
bronze.crm_sales_details 

SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM
bronze.crm_sales_details
WHERE sls_cust_id not in (select cst_id from  silver.crm_cust_info)
Check if the sls_cust_id got loaded into silver.crm_cust_info, turned out
was not, re-ran the script to insert.
*/



SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price

FROM 
bronze.crm_sales_details 

-- sls_ord_num,sls_prd_key, sls_cust_id no need for attention, has been standardised
-- can be used to connect other tables in the gold layer

--dates required formatting as it is numbers, change from itn to date

--check for invalid date 
SELECT 
sls_order_dt
FROM
bronze.crm_sales_details
WHERE sls_order_dt <= 0

SELECT 
NULLIF (sls_order_dt,0) sls_order_dt
FROM
bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt)!= 8 
OR sls_due_dt > 20270101
OR sls_due_dt < 19000101
--check if date is 0 or more than 8 numbers, or before business started, in future date 
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
/*Order date needs to be converted from int into varchar and into date */

CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
END sls_order_dt,
/* ship and due date needs the same processing */

CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
END sls_ship_dt,

CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
END sls_due_dt,

/* Check if any logical date sequence is higher than it should be 

SELECT 
*
from bronze.crm_sales_details
WHERE sls_ship_dt > sls_due_dt


--Sales must be equal to sls_quantity*sls_price
SELECT distinct
sls_sales,
sls_quantity,
sls_price
from bronze.crm_sales_details
WHERE 
sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL
OR sls_quantity IS NULL
OR sls_price IS NULL

OR sls_sales <=0 
OR sls_quantity <=0 
OR sls_price <=0 
ORDER BY sls_quantity, sls_price

all sorts of incorrect calculations. Check with the data source Controller what to do with the 
 incorrect calculations, in this case,e I decided to use the correct calculation to get the 
 right price and turn negatives into positives, but some numbers look like a refund.
 */


 --Final query 
 SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
END sls_order_dt,
/* ship and due date needs the same processing */

CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
END sls_ship_dt,

CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
END sls_due_dt,


sls_sales as old_sales,
sls_quantity,
sls_price as old_price,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_price * ABS(sls_quantity)
THEN sls_quantity* ABS(sls_price)
ELSE sls_sales 
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price  <=0
THEN sls_sales / NULLIF(sls_quantity,0)
ELSE sls_price
END sls_price
FROM 
bronze.crm_sales_details 
WHERE 
sls_sales!= sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price 

-- Final query 
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
END sls_order_dt,


CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
END sls_ship_dt,

CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
END sls_due_dt,

CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_price * ABS(sls_quantity)
THEN sls_quantity * ABS(sls_price)
ELSE sls_sales 
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price  <=0
THEN sls_sales / NULLIF(sls_quantity,0)
ELSE sls_price
END AS sls_price,

FROM 
bronze.crm_sales_details 



/* 
**************************************************************************************************
**************************************************************************************************
*/
.erp_cust_12
SELECT *
FROM bronze.erp_cust_az12


SELECT 
cid,
bdate,
gen
FROM
bronze.erp_cust_az12;
SELECT * FROM [silver].[crm_cust_info];
-- Check if cid and cst_key can be connected. There are extra characters. Column to be split 
SELECT 
cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END cid,
bdate,
gen
FROM
bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)
/*------------------------------------------------------------------------------*/

SELECT 


CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END cid,
bdate,
CASE WHEN bdate > GETDATE() THEN 0
ELSE bdate
END AS bdate,

CASE WHEN UPPER(gen) LIKE 'F%' THEN 'Female'
		WHEN UPPER(gen) LIKE 'M%' THEN 'Male'
		ELSE 'n/a'
		END AS gen
FROM
bronze.erp_cust_az12

SELECT DISTINCT bdate
FROM
bronze.erp_cust_az12
WHERE bdate>'2026-01-01'OR bdate<'1924-01-01'
/*some bdate is in the futer, invalid or customer is over 100 years old */

--FINAL QUERRY

SELECT DISTINCT 
gen 
FROM bronze.erp_cust_az12

SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid))
	ELSE cid
	END cid,

	CASE WHEN bdate > GETDATE()  then NULL 
	ELSE bdate 
	END AS bdate,

	CASE WHEN UPPER(gen) LIKE 'F%' THEN 'Female'
		WHEN UPPER(gen) LIKE 'M%' THEN 'Male'
		ELSE 'n/a'
		END AS gen
	FROM bronze.erp_cust_az12;
	/*
	************************************************************************************************
	*********************************************************************************************
	*/

	--.erp_loc_a101

	SELECT *
	FROM bronze.erp_loc_a101

	SELECT 
	cid,
	cntry
	FROM bronze.erp_loc_a101

	SELECT DISTINCT cntry
	FROM bronze.erp_loc_a101;

	SELECT 
	REPLACE (cid, '-','') AS cid,
	/* cid is compatible to connect table, country needs to be standardised 
	by trimming extra spaces 
	*/
	--Final Query 

	CASE WHEN UPPER(cntry) LIKE 'DE%' THEN 'Germany'
		WHEN UPPER(cntry) LIKE 'US%' THEN 'United States'
		WHEN LEN(TRIM(cntry)) <2 OR cntry IS NULL THEN 'n/a'
		else trim (cntry)
		END AS cntry
	FROM 
	bronze.erp_loc_a101;

/*I started explanatory analysis after finalising the gold layer and the distinct country value indicated hidden spaces after some country names 
So I had to run a few checks to end up inserting the following 
WHEN UPPER(TRIM(cntry)) LIKE 'United%' THEN 'United States'
WHEN UPPER(TRIM(cntry)) LIKE 'Germany%' THEN 'Germany'

The check to see where the hidden spaces are 
SELECT DISTINCT '['+cntry +']' as visibility_check,
LEN(cntry) as actual_lenght
FROM silver.erp_loc_a101
WHERE cntry like 'United%'
--I just used all of the country names that came up as duplicates
-- I have updated the main script for loading the table 
*/

	/***********************************************************************************
	************************************************************************
	*/
	--.erp_px_cat_g1v2

	SELECT *
	FROM
	bronze.erp_px_cat_g1v2

	SELECT 
	id,
	cat,
	subcat,
	maintenance
	FROM
		bronze.erp_px_cat_g1v2;
--FINAL QUERY


SELECT 
	id,
	cat,
	subcat,
	--Remove extra hidden characters 

	CASE WHEN UPPER(TRIM(maintenance))
	LIKE 'Y%' THEN 'Yes'
	WHEN UPPER(TRIM(maintenance)) LIKE 'N%' THEN 'No'
	ELSE 'n/a'
	END AS maintenance
	FROM
		bronze.erp_px_cat_g1v2;

		/********************************************************************************
		*******************************************************************************
		*/

-- Check if the created date is a date not a varchar
/*Table: bronze.crm_cust_info
is cleaned and transformed, ready to be uploaded into the silver layer*/

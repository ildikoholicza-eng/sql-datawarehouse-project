


/*
============================================================================================

Stored Procedure: Load Silver Layer (Source-> Silver)

============================================================================================

Script Purpose:
	It performs the following actions:
	- Truncates the silver tables before loading data
	- Uses the 'BULK INSERT' command to load from bronze tables into silver tables 
	- Data is cleaned and standardized 

	Parameters:
		None.
	This stored procedure does not accept any parameters or return any values.

	Usage Example:
	EXEC silver.load_silver;

	========================================================================================
	*/


CREATE OR ALTER PROCEDURE silver.load_silver AS BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME ,@batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
	SET @batch_start_time = GETDATE();
	PRINT '==================================================================================';
	PRINT 'LOADING SILVER LAYER';
	PRINT '==================================================================================';

	PRINT '----------------------------------------------------------------------------------';
	PRINT ' LOADING CRM TABLES ;
	PRINT '----------------------------------------------------------------------------------';



	/*loadin.crm_cust_info*/
	SET @start_time = GETDATE();
	PRINT '** Tuncating Table silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

	SELECT 
	cst_id, 
	cst_key,
	TRIM (cst_firstname) AS cst_firstname,
	TRIM (cst_lastname) AS cst_lastname,

	CASE WHEN  cst_marital_status IS NULL THEN 'n/a'
		WHEN UPPER (TRIM (cst_marital_status)) = 'S'THEN 'Single' 
		WHEN UPPER (TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
	END cst_marital_status,

	CASE WHEN UPPER (TRIM (cst_gndr)) = 'F'THEN 'Female'
		WHEN UPPER (TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a'
	END cst_gndr,
	cst_create_date
	FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	)t
	WHERE flag_last =1 AND cst_id IS NOT NULL;

	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	/*.crm_prd_info*/
	SET @start_time = GETDATE();
	PRINT '** Tuncating Table silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;


	INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	)

	   SELECT 
	   prd_id,
   
	   REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id,
	   SUBSTRING(prd_key, 7,len(prd_key)) AS prd_key,
	   prd_nm,
	  ISNULL (prd_cost, 0) AS prd_cost,

	   CASE WHEN UPPER(TRIM( prd_line)) = 'M' THEN 'Mountain'
		   WHEN UPPER(TRIM( prd_line ))= 'R' THEN 'Road'
		   WHEN UPPER(TRIM( prd_line)) = 'S' THEN 'Other Sales'
		   WHEN UPPER(TRIM( prd_line)) = 'T' THEN 'Touring'
		   ELSE 'n/a'
	   END AS prd_line, 
   
	  CAST(prd_start_dt AS DATE) AS prd_start_dt,
	  CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
	   FROM bronze.crm_prd_info;
	   SET @end_time = GETDATE();
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'


	   /*.crm_sales_details*/
	   SET @start_time = GETDATE();
	   PRINT '** Tuncating Table silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;


	   INSERT INTO silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
	)

	SELECT 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,

	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST (sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,


	CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST (sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,

	CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	ELSE CAST(CAST (sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,

	CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
		END AS sls_sales,

	sls_quantity,

	CASE WHEN sls_price IS NULL OR sls_price<0 
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
		END AS sls_price

	FROM bronze.crm_sales_details;
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	PRINT '----------------------------------------------------------------------------------';
	PRINT ' LOADING ERP TABLES ;
	PRINT '----------------------------------------------------------------------------------';

	/*erp_cust_az12*/
	SET @start_time = GETDATE();
	PRINT '** Tuncatingsilver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;


	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen)
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

	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'



	/* .erp_loc_a101*/
	SET @start_time = GETDATE();
	PRINT '** Tuncating Table silver.crm_cust_info';
	TRUNCATE TABLE silver.erp_loc_a101;

	INSERT INTO silver.erp_loc_a101(
	cid,
	cntry)
	SELECT 
	REPLACE (cid, '-','') AS cid,

	CASE WHEN UPPER(cntry) LIKE 'DE%' THEN 'Germany'
		WHEN UPPER(cntry) LIKE 'US%' THEN 'United States'
		WHEN LEN(TRIM(cntry)) <2 OR cntry IS NULL THEN 'n/a'
		else trim (cntry)
		END AS cntry
	FROM 
	bronze.erp_loc_a101;
	
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'


	/* .erp_px_cat_g1v2*/
	SET @start_time = GETDATE();
	PRINT '** Tuncating Table silver.erp_px_cat_g1v2 ';
	TRUNCATE TABLE silver.erp_px_cat_g1v2 ;

	INSERT INTO silver.erp_px_cat_g1v2(id,
	cat,
	subcat,
	maintenance)

	SELECT 
	id,
	cat,
	subcat,

	CASE WHEN UPPER(TRIM(maintenance))
	LIKE 'Y%' THEN 'Yes'
	WHEN UPPER(TRIM(maintenance)) LIKE 'N%' THEN 'No'
	ELSE 'n/a'
	END AS maintenance
	FROM
	bronze.erp_px_cat_g1v2;
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'
	SET @batch_end_time = GETDATE();
	PRINT '=========================================================================================';
	PRINT 'Loading Silver Layer is Completed';
		PRINT '- Total Duration: '+ CAST(DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT '========================================================================================================';
	
	END TRY

	BEGIN CATCH 
PRINT '==========================================================';
PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER ';
PRINT'Error Message' + CAST( ERROR_MESSAGE() AS NVARCHAR);
PRINT'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
PRINT '==========================================================';
END CATCH

END

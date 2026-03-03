
/*
============================================================================================

Stored Procedure: Load Bronze Layer (Source-> Bronze)

============================================================================================

Script Purpose:
	It performs the following actions:
	- Truncates the bronze tables before loading data
	- Uses the 'BULK INSERT' command to load from csv files to bronze tables.

	Parameters:
		None.
	This stored procedure does not accept any parameters or return any values.

	Usage Example:
	EXEC bronze.load_bronze;

	========================================================================================
	*/



CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME;_
BEGIN TRY

	PRINT '=========================================================================================';
	PRINT 'Loading Bronze Layer';
	PRINT' =========================================================================================';

	PRINT '-----------------------------------------------------------------------------------------';
	PRINT 'Loading CRM Tables';
	PRINT' -----------------------------------------------------------------------------------------';
	SET @start_time = GETDATE ();
	SET DATEFORMAT dmy;
		PRINT ' >> Tuncate the table bronze.crm_cust_info << ';
	TRUNCATE TABLE bronze.crm_cust_info;

	PRINT ' >> Inserting Data In Table bronze.crm_cust_info << ' ;
	BULK INSERT bronze.crm_cust_info
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_crm\cust_info.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK
	);
		SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'
	SELECT 
	COUNT (*)AS total_rows,
	SUM (CASE WHEN cst_id IS NULL THEN 1  ELSE 0 END ) as missing_ids,
	SUM ( CASE WHEN cst_create_date IS NULL THEN 1 ELSE 0 END ) AS missing_dates
	FROM bronze.crm_cust_info;

	SELECT *FROM bronze.crm_cust_info;

	SET @start_time = GETDATE ();
	PRINT ' >> Tuncate the table bronze.crm_prd_info << ';

	TRUNCATE TABLE bronze.crm_prd_info;
	PRINT ' >> Inserting Data In Table bronze.crm_prd_info <<';
	BULK INSERT bronze.crm_prd_info
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_crm\prd_info.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK);
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	SELECT *
	FROM bronze.crm_prd_info

	SELECT 

	COUNT (*)AS total_rows,

	SUM (CASE WHEN prd_id IS NULL THEN 1  ELSE 0 END ) as missing_ids,

	SUM ( CASE WHEN prd_sart_dt IS NULL THEN 1 ELSE 0 END ) AS missing_dates
	FROM bronze.crm_prd_info;

	SET @start_time = GETDATE ();
	PRINT ' >> Tuncate the table bronze.crm_sales_details << ';
	
	TRUNCATE TABLE bronze.crm_sales_details;
	PRINT ' >> Inserting Data In Table bronze.crm_sales_details <<';
	BULK INSERT bronze.crm_sales_details
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_crm\sales_details.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK);
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	SELECT * FROM bronze.crm_sales_details

	select
	COUNT (*)AS total_rows,

	SUM (CASE WHEN sls_ord_num IS NULL THEN 1  ELSE 0 END ) as missing_ids,

	SUM ( CASE WHEN sls_order_dt IS NULL THEN 1 ELSE 0 END ) AS missing_dates
	FROM bronze.crm_sales_details;

	PRINT' -----------------------------------------------------------------------------------------';
	PRINT 'Loading ERP Tables';
	PRINT '-----------------------------------------------------------------------------------------';
	
	SET @start_time = GETDATE ();
	PRINT ' >> Tuncate the table bronze.crm_sales_details << ';
	TRUNCATE TABLE bronze.erp_cust_az12;
	PRINT ' >> Inserting Data In Table bronze.crm_sales_details <<';
	BULK INSERT bronze.erp_cust_az12
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_erp\CUST_AZ12.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK);
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	SELECT * FROM bronze.erp_cust_az12;

	SET @start_time = GETDATE ();
	PRINT ' >> Tuncate the table bronze.erp_loc_a101 << ';
	TRUNCATE TABLE bronze.erp_loc_a101;
	PRINT ' >> Inserting Data In Table bronze.erp_loc_a101 <<';
	BULK INSERT bronze.erp_loc_a101
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_erp\LOC_A101.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK);
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	SELECT * FROM bronze.erp_loc_a101;

	SET @start_time = GETDATE ();
	PRINT ' >> Tuncate the table bronze.erp_px_cat_g1v2 << ';
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	PRINT ' >> Inserting Data In Table bronze.erp_px_cat_g1v2 <<';
	BULK INSERT bronze.erp_px_cat_g1v2
	FROM
	'C:\Users\User1\Downloads\DataWarehouseBuildingProject\source_erp\PX_CAT_G1V2.csv'
	WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a' ,
	CODEPAGE = '65001',
	TABLOCK);
	SET @end_time = GETDATE ();
		PRINT'>> Load Duration:'+ CAST (DATEDIFF( second, @start_time, @end_time) AS VARCHAR ) + 'seconds';
		PRINT'>>--------------------------------------------------------------------------------------<<'

	SELECT * FROM bronze.erp_px_cat_g1v2;
END TRY
BEGIN CATCH 
PRINT '==========================================================';
PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER ';
PRINT'Error Message' + CAST( ERROR_MESSAGE() AS NVARCHAR);
PRINT'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
PRINT '==========================================================';
END CATCH
END 

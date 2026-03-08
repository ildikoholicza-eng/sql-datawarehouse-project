/*
====================================================================================================
Quality Checks 
===================================================================================================
Script Purpose:
This script performs quality checks to validate the integrity, consistency,
and accuracy of the Gold Layer. 
These checks ensure:
- Uniqueness of surrogate keys in dimension tables.
- Referential integrity between fact and dimension tables.
- Validation of relationships in the data model for analytical purposes.

Usage Note:
- Run these checks after dat loading Silver Layer.
- Investigate and resolve any discrepancies found during checks.
=========================================================================
*/
/*
-----------------------------------------------------------------------------

Checking gold.dim_customers 
-------------------------------------------------------------------------------
*/

SELECT 
*
FROM
gold.dim_customers;

SELECT DISTINCT 
gender
FROM
gold.dim_customers;

SELECT *
FROM 
gold.dim_products

SELECT *
*/--------------------------------------------------------------------------
  */
-- Check if all dimension tables can successfully connect to the fact tables 
/*----------------------------------------------------------------------------*/
-- Foreign Key Integrity (dimensions )
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key 
WHERE c.customer_key 
IS NULL 
 /*------------------------------------------------------------------------------------*/ 
--Checking gold.fact_sales
  /*-----------------------------------------------------------------------------*/
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key 
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERe p.product_key 
IS NULL 

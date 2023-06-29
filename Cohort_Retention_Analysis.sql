-- Cohort Retention Analysis - SQL.
-- Performed Cohort Retention Analysis using MS SQL Server for an Online Retail platform, 
-- demonstrating expertise in data cleaning, data wrangling, and advanced SQL analysis to determine
-- the cohort retention rate. Developed a visually compelling dashboard in Tableau to effectively visualize the results.



-- Data Cleaning

-- Total Records = 541909
-- Null values in [CustomerID] = 135080
-- Records with [CustomerID] = 406829

With not_null_data AS 
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [firstdb].[dbo].[Online Retail_CSV]
		Where [CustomerID] is not null
)
, quantity_unitpirce AS (
	-- 397884 Data with proper Quantity and UnitPrice.
		Select * 
		From not_null_data
		Where Quantity > 0 And UnitPrice > 0
)
, dup_check As 
(
	-- Duplicate check
	Select * , ROW_NUMBER() Over (partition by [InvoiceNo],[StockCode],[Quantity]  Order By [InvoiceDate]) AS dup_value
	From quantity_unitpirce
)
, clean_data As
(
	-- 5215 Duplicates
	-- 392669 Data after removing Duplication
	-- Clean Data
Select *
From dup_check
Where dup_value = 1
)
Select *
Into #clean_data_temp
From clean_data


-- CLEAN DATA 
-- COHORT ANALYSIS BEGIN
Select *
From #clean_data_temp


-- Points Required to do Cohort Retention Analysis
-- 1. Unique Identifier (CustomerID)
-- 2. Initial Start Date (First Invoice Date)
-- 3. Revenue Data


-- Creating Cohort Groups

Select 
	CustomerID, 
	min(InvoiceDate) As first_purchase, 
	DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)),1) As cohort_date
Into #cohort
From #clean_data_temp
Group BY CustomerID

Select * 
From #cohort

-- Create Cohort Index

Select 
	mmm.*, 
	cohort_index = year_diff * 12 + month_diff + 1
Into #cohort_retention
From (
	Select 
		mm.*, 
		year_diff = invoice_year-cohort_year ,
		month_diff= invoice_month-cohort_month
	From (
			Select 
			m.*, 
			c.cohort_date,
			year(m.InvoiceDate) As invoice_year,
			month(m.InvoiceDate) As invoice_month, 
			year(c.cohort_date) As cohort_year,
			MONTH(c.cohort_date) AS cohort_month
			From #clean_data_temp m
			Left Join #cohort c On m.CustomerID=c.CustomerID
		) mm
) mmm


-- Pivoting Data to see the cohort table
-- Cohort Retetion 

Select *
Into #cohort_pivot
From (
	Select 
		Distinct CustomerID,
		Cohort_date,
		cohort_index
	From #cohort_retention
) tble
Pivot (
	Count(CustomerID)
	For cohort_index In 
	(  [1],
		[2],
		[3],
		[4],
		[5],
		[6],
		[7],
		[8],
		[9],
		[10],
		[11],
		[12],
		[13] )
	) 
AS Pivot_table


-- Cohort Retention Rate
Select 
		1.0 * [1]/[1] * 100 As [1],
		1.0 * [2]/[1] * 100 As [2],
		1.0 * [3]/[1] * 100 As [3],
		1.0 * [4]/[1] * 100 As [4],
		1.0 * [5]/[1] * 100 As [5],
		1.0 * [6]/[1] * 100 As [6],
		1.0 * [7]/[1] * 100 As [7],
		1.0 * [8]/[1] * 100 As [8],
		1.0 * [9]/[1] * 100 As [9],
		1.0 * [10]/[1] * 100 As [10],
		1.0 * [11]/[1] * 100 As [11],
		1.0 * [12]/[1] * 100 As [12],
		1.0 * [13]/[1] * 100 As [13]
From #cohort_pivot
Order By cohort_date


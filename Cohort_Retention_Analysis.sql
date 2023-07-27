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
-- 3. User activity Data

-- Step 1: Creating Cohort Groups
WITH cohort_group AS (
    -- Identify the first purchase date for each customer and create cohorts based on the month and year of their first purchase
    SELECT
        [CustomerID],
        MIN([InvoiceDate]) AS first_purchase_date,
        DATEPART(YEAR, MIN([InvoiceDate])) AS cohort_year,
        DATEPART(MONTH, MIN([InvoiceDate])) AS cohort_month
    FROM
        #clean_data_temp
    GROUP BY
        [CustomerID]
),

-- Step 2: Calculating User Activity
user_activity AS (
    -- Joining cohort groups with the original transaction data to identify customer activity within their cohort
    SELECT
        c.[CustomerID],
        c.cohort_year,
        c.cohort_month,
        DATEPART(YEAR, o.[InvoiceDate]) AS order_year,
        DATEPART(MONTH, o.[InvoiceDate]) AS order_month,
        order_year_diff = DATEPART(YEAR, o.[InvoiceDate]) - cohort_year,
        order_month_diff = DATEPART(MONTH, o.[InvoiceDate]) - cohort_month
    FROM
        cohort_group c
    LEFT JOIN
        #clean_data_temp o ON c.[CustomerID] = o.[CustomerID]
),

-- Step 3: Create Cohort Index
cohort_period AS (
    -- Calculate a cohort index (period index) representing the number of months since the cohort's first purchase
    SELECT 
        [CustomerID],
        cohort_year,
        cohort_month,
        order_year,
        order_month,
        order_year_diff,
        order_month_diff,
        cohort_index_akaPeriod = order_year_diff * 12 + order_month_diff + 1
    FROM 
        user_activity
)

-- Step 4: Building Cohort Table
SELECT 
    DISTINCT CustomerID AS customer_number,
    DATEFROMPARTS(cohort_year, cohort_month, 1) AS cohort_date,
    cohort_index_akaPeriod
INTO #cohorttable
FROM 
    cohort_period
GROUP BY 
    DATEFROMPARTS(cohort_year, cohort_month, 1),
    cohort_index_akaPeriod,
    CustomerID
ORDER BY 
    2, 3

-- Step 5: Pivot and Calculate Retention
SELECT * 
FROM #cohorttable
PIVOT 
(
    COUNT(customer_number)
    FOR cohort_index_akaPeriod 
    IN (
        [1],
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
        [13]
    )
) AS pivot_table
ORDER BY cohort_date;

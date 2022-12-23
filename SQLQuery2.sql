/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (1000) [InvoiceNo]
--      ,[StockCode]
--      ,[Description]
--      ,[Quantity]
--      ,[InvoiceDate]
--      ,[UnitPrice]
--      ,[CustomerID]
--      ,[Country]
--  FROM Online_Retail
  ---------CLEANING DATA---------
  --------- TOTAL RECORDS = 541909
  --------- CustomerID's are NULL = 135080
  --------- CustomerID's are NOT NULL = 406829
  
 -- SELECT *
 --FROM Online_Retail
 --WHERE CustomerID IS NULL

 --SELECT *
 --FROM Online_Retail
 --WHERE CustomerID IS NOT NULL

 -----CTE-----

 ;with online_retailCTE as
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM Online_Retail 
	  Where CustomerID IS NOT NULL
)
, quantity_unit_price as 
(

	---397882 records with quantity and Unit price
	select *
	from online_retailCTE
	where Quantity > 0 and UnitPrice > 0
)
, dup_check as
(
	---duplicate check
	select * , ROW_NUMBER() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceDate)dup_flag
	from quantity_unit_price

)
---392669 clean data

select *
into #online_retail_ma -----TEMP TABLE---
from dup_check
where dup_flag = 1

---------- Clean data
--------BEGIN  COHORT ANALYSIS
SELECT *
FROM #online_retail_ma

-----UNIQUE IDENTIFIER---(CUSTOMERID)
---- INTIAL START DATE (FIRST INVOICE DATE)
---- REVENUE DATA 

select
	CustomerID,
	min(InvoiceDate) first_purchase_date,
	DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)), 1) Cohort_Date
into #cohort1
from #online_retail_ma
group by CustomerID 

SELECT*
FROM #cohort1

----CREATE COHORT INDEX-----
---NUMBER OF MONTHS PASSED SINCE 1ST PURCHASE 
Select
mmm.*,
cohort_index = year_diff*12+month_diff+1
into #cohort_retention
from 
(
Select 
mm.*,
year_diff = invoice_year - cohort_year,
month_diff = invoice_month - cohort_month
from 
(
SELECT 
m.*, c.Cohort_Date,
year(m.InvoiceDate) invoice_year,
month(m.InvoiceDate) invoice_month,
year(c.Cohort_Date) cohort_year,
month(c.Cohort_Date) cohort_month 

FROM #online_retail_ma m
left join #cohort1 c
on m.CustomerID = c.CustomerID 
)mm
)mmm

---where CustomerID = 17850
---------PIVOT DATA TO SEE THE COHORT TABLE
SELECT  *
into #cohort_pivot
FROM( 
select distinct
CustomerID,
Cohort_Date,
cohort_index
from #cohort_retention

)TBL
PIVOT(
COUNT(CUSTOMERID)
FOR Cohort_Index IN 

(       [1], 
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
		[13])

) as pivot_table


Select *, 1.0* [1]/[1]*100 as [1],
 1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot
order by Cohort_Date




 



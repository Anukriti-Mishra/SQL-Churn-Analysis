--Changing Table Name to "TelcoCustomer"
ALTER TABLE "WA_Fn-UseC_-Telco-Customer-Churn"
RENAME TO TelcoCustomer;
SELECT *
FROM TelcoCustomer
LIMIT 10;

--Inspecting datatypes and null values
PRAGMA table_info(TelcoCustomer);

--Filtering down the Not null values for Total Charges
SELECT *
FROM TelcoCustomer
WHERE TRIM(TotalCharges)=''OR TotalCharges IS NULL;

--CASTING total charges to Numeric value
SELECT 
  *,
  CAST(TotalCharges AS REAL) AS TotalCharges_Num
FROM TelcoCustomer
WHERE TRIM(TotalCharges) != '';

--Creating a new view for working that excludes null values for Totalcharges
CREATE VIEW CleanTelcoCustomer AS
SELECT *,
       CAST(TotalCharges AS REAL) AS TotalCharges_Num
FROM TelcoCustomer
WHERE TRIM(TotalCharges) != '' AND TotalCharges IS NOT NULL;

--Checking the differnce of row count between original data and created view
SELECT *
FROM CleanTelcoCustomer;
SELECT *
FROM TelcoCustomer;

--Getting total churned and not-churned customers(Both SELECT Statements dont run together in DBSQLlite hence using UNION ALL)
SELECT Churn, count(*) AS ChurnedCustomers
FROM CleanTelcoCustomer
WHERE Churn='Yes'

UNION ALL

SELECT Churn, count(*) AS ChurnedCustomers
FROM CleanTelcoCustomer
WHERE Churn='No';

--How to get both the queries run together (ALTERNATIVE METHOD)
SELECT 
  Churn, 
  COUNT(*) AS CustomerCount
FROM CleanTelcoCustomer
GROUP BY Churn;

-- Business Question 2: wat is the overall churn rate (% of customers who have churned)?
 SELECT 
  ROUND(
    100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) 
    / COUNT(*), 
    2
  ) AS ChurnRatePercent
FROM CleanTelcoCustomer;

--Business Question 3:What is the average tenure of churned vs. non-churned customers?
SELECT 
	CASE WHEN Churn='Yes' THEN 'Churned' ELSE 'Non-Churned' END,
	ROUND(AVG(Tenure),2) AS AvgTenure
FROM CleanTelcoCustomer
GROUP BY Churn;

--Business Question 4:How does churn vary by contract type (Month-to-Month, One Year, Two Year)?
SELECT 
Contract,
Count(*) AS TotalCustomer,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS ChurnedCustomer,
ROUND(100.0* SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)/Count(*),2) AS ChurnRate
FROM CleanTelcoCustomer
GROUp BY Contract;

--Business Question 5:Do churn rates vary based on the payment method?
SELECT 
PaymentMethod,
SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS ChurnedCustomer,
ROUND(100.0* SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)/Count(*),2) AS ChurnRate
FROM CleanTelcoCustomer
GROUp BY PaymentMethod
ORDER BY ChurnRate DESC;
/*Customers using electronic checks churn at 45%, while credit card users churn at only 20%*/

--COMPLEX QUERY 1: Churn Rate by Senior Status + Gender (Multiple Groupings)
SELECT 
Gender,
SeniorCitizen,
ROUND(100.0* SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)/Count(*),2) AS ChurnRate
FROM CleanTelcoCustomer
GROUP BY gender,SeniorCitizen
ORDER BY gender,SeniorCitizen DESC;

--COMPLEX QUERY 2: Churn Rate by Tenure BucketLet’s group customers into custom-defined tenure segments (e.g., "New", "Mid", "Loyal") and calculate churn rate per group.
SELECT
CASE WHEN tenure<=12 THEN 'New(0-12mo)'
	WHEN tenure BETWEEN 13 AND 24 THEN 'Mid(13-24mo)'
	WHEN tenure BETWEEN 25 AND 48 THEN 'Established(26-48mo)'
	ELSE 'Loyal(49+mo)'
	END AS TenureBucket,
ROUND(100.0*SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)/Count(*),2) AS ChurnRate
FROM CleanTelcoCustomer
GROUP BY TenureBucket
ORDER BY ChurnRate DESC;

--COMPLEX QUERY 3: Churn by Internet Service + Streaming + Phone Service Combination
SELECT
  InternetService,
  StreamingTV,
  StreamingMovies,
  PhoneService,
  COUNT(*) AS TotalCustomers,
  SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS ChurnedCustomers,
  ROUND(
    100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) || '%' AS ChurnRate
FROM CleanTelcoCustomer
GROUP BY InternetService, StreamingTV, StreamingMovies, PhoneService
ORDER BY ChurnRate DESC, TotalCustomers DESC;

/*COHORT ANALYSIS
	Cohort = a group of customers who started around the same time.
	In TelcoCustomer dataset:We do not have an explicit StartDate.But we do have tenure = number of months with company.
	So we will generate StartDate using that.*/
	
WITH AddStartMonth AS
	(
	SELECT *,
	date('2025-06-01','-'|| tenure||' months') AS StartDate
	--date(base_date, modifier) Note: Space before months then it will be "2025-06-01-12 months".
	FROM CleanTelcoCustomer
	)
--👉 WITH introduces a Common Table Expression (CTE).CTE = a temporary result (like a temporary table)
--👉 SELECT * → Select all columns from CleanTelcoCustomer. 
--👉 StartDate is additional column in this CTE.


--Business Question:Are customers who joined in different months behaving differently in terms of churn?
SELECT 
CASE strftime('%m',StartDate)
	WHEN '01' THEN 'January'
    WHEN '02' THEN 'February'
    WHEN '03' THEN 'March'
    WHEN '04' THEN 'April'
    WHEN '05' THEN 'May'
    WHEN '06' THEN 'June'
    WHEN '07' THEN 'July'
    WHEN '08' THEN 'August'
    WHEN '09' THEN 'September'
    WHEN '10' THEN 'October'
    WHEN '11' THEN 'November'
    WHEN '12' THEN 'December'
  END AS Startmonth,
SUM(CASE WHEN Churn='Yes'THEN 1 ELSE 0 END) AS Totalchurnedcustomer,
ROUND(100.0*SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)/Count(*),2) AS Churnrate
FROM AddStartMonth
GROUP BY Startmonth;





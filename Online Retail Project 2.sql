CREATE DATABASE retail_db;
USE retail_db;

CREATE TABLE retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    Price FLOAT,
    CustomerID FLOAT,
    Country VARCHAR(50),
    TotalAmount FLOAT,
    Year INT,
    Month INT,
    YearMonth VARCHAR(10),
    DayOfWeek VARCHAR(20)
);

drop table retail;

SHOW VARIABLES LIKE 'secure_file_priv';

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/cleaned_retail.csv'
INTO TABLE retail
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from retail
limit 10;

CREATE VIEW customer_spending AS
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    SUM(TotalAmount) AS total_spent
FROM retail
GROUP BY CustomerID;

CREATE VIEW monthly_revenue AS
SELECT 
    YearMonth,
    SUM(TotalAmount) AS revenue
FROM retail
GROUP BY YearMonth;

WITH rfm_base AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(TotalAmount) AS monetary
    FROM retail
    GROUP BY CustomerID
)

SELECT *,
DATEDIFF((SELECT MAX(InvoiceDate) FROM retail), last_purchase) AS recency
FROM rfm_base;

CREATE VIEW rfm_view AS
WITH rfm AS (
    SELECT
        CustomerID,
        DATEDIFF((SELECT MAX(InvoiceDate) FROM retail), MAX(InvoiceDate)) AS recency,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(TotalAmount) AS monetary
    FROM retail
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,
    CASE 
        WHEN monetary > 5000 THEN 'High Value'
        WHEN monetary > 2000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM rfm;

SELECT
    CustomerID,
    SUM(TotalAmount) AS total_spent,
    RANK() OVER (ORDER BY SUM(TotalAmount) DESC) AS customer_rank
FROM retail
GROUP BY CustomerID;

SELECT
    YearMonth,
    SUM(TotalAmount) AS monthly_revenue,
    SUM(SUM(TotalAmount)) OVER (ORDER BY YearMonth) AS running_total
FROM retail
GROUP BY YearMonth;


CREATE VIEW cohort_view AS
WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(YearMonth) AS cohort_month
    FROM retail
    GROUP BY CustomerID
),
cohort_data AS (
    SELECT
        r.CustomerID,
        f.cohort_month,
        r.YearMonth
    FROM retail r
    JOIN first_purchase f 
    ON r.CustomerID = f.CustomerID
)
SELECT 
    cohort_month,
    YearMonth,
    COUNT(DISTINCT CustomerID) AS customers
FROM cohort_data
GROUP BY cohort_month, YearMonth
ORDER BY cohort_month, YearMonth;
-- --------------------------------------------------------------
-- 05_customer_value.sql
-- Project: UK Online Retail Revenue Analysis (PostgreSQL)
-- Purpose: top customers by spend, repeat orders and average order value.
-- --------------------------------------------------------------

-- Top 10 customers by total spend (nulls excluded — these represent 
-- transactions with no CustomerID recorded, not a real customer)
SELECT "CustomerID", SUM("Quantity"*"UnitPrice") AS "TopCustomerSpend"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]' AND "CustomerID" IS NOT NULl
GROUP BY "CustomerID"
ORDER BY "TopCustomerSpend" DESC
LIMIT 10;

-- Verify top 2 customers' spend comes from many repeat orders, 
-- not one large wholesale purchase
SELECT "CustomerID", COUNT(DISTINCT("InvoiceNo" )) AS "Numorders"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]' AND "CustomerID" IN('14646','18102')
GROUP BY "CustomerID"

-- Average order value per top customer (TotalSpend / NumOrders)
-- Note: AVG(Quantity*UnitPrice) would average per product line, not per 
-- order, since each order spans multiple rows — this gives the wrong metric
SELECT "CustomerID", 
    SUM("Quantity"*"UnitPrice") AS "TotalSpend",
    COUNT(DISTINCT "InvoiceNo") AS "NumOrders",
    SUM("Quantity"*"UnitPrice") / COUNT(DISTINCT "InvoiceNo") AS "AvgOrderValue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]' AND "CustomerID" IS NOT NULL
GROUP BY "CustomerID"
ORDER BY "TotalSpend" DESC
LIMIT 10;

-- Average line item spend
SELECT "CustomerID", 
    SUM("Quantity"*"UnitPrice") AS "TotalSpend",
    COUNT(DISTINCT "InvoiceNo") AS "NumOrders",
    AVG("Quantity"*"UnitPrice") AS "AvgLineItemSpend"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]' AND "CustomerID" IS NOT NULL
GROUP BY "CustomerID"
ORDER BY "TotalSpend" DESC
LIMIT 10;

-- ===== Part 2: Missing customer IDs =====

-- Baseline for rows with a customer ID: total spend, number of orders and average line-item spend
SELECT 
    SUM("Quantity"*"UnitPrice") AS "TotalSpend",
    COUNT(DISTINCT "InvoiceNo") AS "NumOrders",
    AVG("Quantity"*"UnitPrice") AS "AvgLineItemSpendWithID"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]' AND "CustomerID" IS NOT NULL;

-- How many product rows have a customer ID, and how many do not
-- (COUNT(*) counts every row; COUNT("CustomerID") skips NULLs)
SELECT
  COUNT(*) AS "AllRows",
  COUNT("CustomerID") AS "RowsWithCustomerID",
  COUNT(*) - COUNT("CustomerID") AS "RowsWithoutID"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]';

-- Share of revenue from rows with and without a customer ID
SELECT
  ROUND(100.0 * SUM(CASE WHEN "CustomerID" IS NOT NULL THEN "Quantity" * "UnitPrice" END)
        / SUM("Quantity" * "UnitPrice"), 2) AS "PctRevenueWithID",
  ROUND(100.0 * SUM(CASE WHEN "CustomerID" IS  NULL THEN "Quantity" * "UnitPrice" END)
        / SUM("Quantity" * "UnitPrice"), 2) AS "PctRevenueNoID"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]';

-- Compare rows with and without a customer ID: row count and average line value
SELECT
  (CASE WHEN "CustomerID" IS NULL THEN 'True' ELSE 'False' END) AS "NoID",
  COUNT(*) AS "Rows",
  AVG("Quantity" * "UnitPrice") AS "AvgLineValue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "NoID";

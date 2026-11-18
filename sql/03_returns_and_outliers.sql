-- --------------------------------------------------------------
-- 03_returns_and_outliers.sql
-- Project: UK Online Retail Revenue Analysis (PostgreSQL)
-- Purpose: apparent return losses, the PAPER CRAFT outlier, and order-size buckets based on percentiles.
-- --------------------------------------------------------------

-- ===== Part 1: Return losses and the PAPER CRAFT outlier =====

-- Total lost revenue from returns (Quantity is negative)
SELECT "Description",SUM("Quantity"*"UnitPrice") AS "LostRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~'[0-9]' AND "Quantity" <0
GROUP BY "Description"
ORDER BY "LostRevenue" ASC
LIMIT 10;

-- Check the product which had Highest LossRevenue(Here that product is 'PAPER CRAFT , LITTLE BIRDIE')
SELECT "InvoiceNo", "Quantity", "UnitPrice", "InvoiceDate"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'PAPER CRAFT , LITTLE BIRDIE' AND "Quantity" < 0
ORDER BY "Quantity" ASC
LIMIT 10;

--Investigate the outlier: confirm this was a genuine order later cancelled, not a data anomaly
SELECT "InvoiceNo", "Quantity", "UnitPrice", "InvoiceDate"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'PAPER CRAFT , LITTLE BIRDIE' AND "Quantity" = 80995

-- exclude extreme outliers and re-check the lost Revenue
-- Rough cutoff to exclude wholesale-scale cancellations; not a precise threshold
SELECT "Description",SUM("Quantity"*"UnitPrice") AS "LostRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~'[0-9]' AND "Quantity" <0 AND "Quantity">-1000
GROUP BY "Description"
ORDER BY "LostRevenue" ASC
LIMIT 10;

-- ===== Part 2: Order-size distribution and buckets =====

-- Quantity distribution of sale rows (median, 90th and 99th percentile, max, average),
-- used to choose the Small / Medium / Bulk cutoffs
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY "Quantity") AS "Median",
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY "Quantity") AS "P90",
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY "Quantity") AS "P99",
  MAX("Quantity") AS "Max",
  AVG("Quantity") AS "Avg"
FROM retail_project."OnlineRetailCSV"
WHERE "Quantity" > 0
  AND "StockCode" ~ '[0-9]';

-- Preview: label each sale row as Small (under 24 units), Medium (24-99) or Bulk (100+)
SELECT
  "Quantity",
  CASE
    WHEN "Quantity" >= 100 THEN 'Bulk'
    WHEN "Quantity" >= 24  THEN 'Medium'
    ELSE 'Small'
  END AS "OrderSize"
FROM retail_project."OnlineRetailCSV"
WHERE "Quantity" > 0
  AND "StockCode" ~ '[0-9]'
LIMIT 20;

-- Number of sale rows in each order-size bucket
SELECT
  CASE
    WHEN "Quantity" >= 100 THEN 'Bulk'
    WHEN "Quantity" >= 24  THEN 'Medium'
    ELSE 'Small'
  END AS "OrderSize",
  COUNT(*) AS "No.of Rows"
FROM retail_project."OnlineRetailCSV"
WHERE "Quantity" > 0
  AND "StockCode" ~ '[0-9]'
GROUP BY "OrderSize"
ORDER BY "No.of Rows" DESC;

-- Split the Bulk bucket (100+ units) into slices to see where the extreme quantities sit
SELECT
  CASE
    WHEN "Quantity" >= 10000 THEN '10000+'
    WHEN "Quantity" >= 1000  THEN '1000-9999'
    WHEN "Quantity" >= 100   THEN '100-999'
  END AS "BulkSlice",
  COUNT(*) AS "Rows"
FROM retail_project."OnlineRetailCSV"
WHERE "Quantity" >= 100
  AND "StockCode" ~ '[0-9]'
GROUP BY "BulkSlice"
ORDER BY "BulkSlice";

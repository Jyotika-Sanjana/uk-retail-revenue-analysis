-- --------------------------------------------------------------
-- 02_revenue_trends_and_orders.sql
-- Project: UK Online Retail Revenue Analysis (PostgreSQL)
-- Purpose: monthly revenue trend, data-coverage checks and order-level concentration in November 2011.
-- --------------------------------------------------------------

--Revenue by month
SELECT TO_CHAR(TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI'),'YYYY-MM') AS "Month",
SUM("Quantity"*"UnitPrice") AS "MonthlyRevenue"
FROM  retail_project."OnlineRetailCSV"
WHERE  "StockCode" ~'[0-9]'
GROUP BY "Month"
ORDER BY "Month";

-- Revenue of each month according to the nummber of days the month has
SELECT
  TO_CHAR(TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI'), 'YYYY-MM') AS "Month",
  SUM("Quantity" * "UnitPrice") AS "MonthlyRevenue",
  COUNT(DISTINCT TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "DaysWithData",
  SUM("Quantity" * "UnitPrice")
    / COUNT(DISTINCT TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "RevenuePerDay"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Month"
ORDER BY "Month";

-- Latest invoice timestamp in Dec 2011 (shows which day the data stops)
SELECT MAX("InvoiceDate")
FROM retail_project."OnlineRetailCSV"
WHERE "InvoiceDate" LIKE '12/%/2011%';

-- List the distinct days with data between Sept and Nov 2011 (check for missing days)
SELECT DISTINCT(TO_CHAR(TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI'),'MM/DD/YYYY')) AS "Days"
FROM retail_project."OnlineRetailCSV"
WHERE TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI') BETWEEN '2011-09-01' AND '2011-11-30'
ORDER BY "Days";

-- Top 10 individual orders by revenue in November 2011
-- (grouped by InvoiceNo, not Description, to check order-level concentration 
-- rather than product-level totals)
SELECT "InvoiceNo",SUM("Quantity"*"UnitPrice") as "NovRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI') BETWEEN '2011-11-01' AND '2011-11-30' AND "StockCode" ~'[0-9]'
GROUP BY "InvoiceNo"
ORDER BY "NovRevenue" DESC
LIMIT 10;

-- Combined value of the top 2 orders, to check what % of November's 
-- total revenue they represent (verifying the spike isn't order-concentrated)
SELECT SUM("Quantity"*"UnitPrice") AS "TopordersTotal"
FROM retail_project."OnlineRetailCSV"
WHERE "InvoiceNo" IN ('574941', '576365')
AND "StockCode" ~ '[0-9]';


-- Total revenue by day of week (0 = Sunday ... 6 = Saturday); Saturday has no rows in this dataset
SELECT
  EXTRACT(DOW FROM TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "DayOfWeek",
  SUM("Quantity" * "UnitPrice") AS "Revenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "DayOfWeek"
ORDER BY "DayOfWeek";


-- Revenue per day with sales, by day of week (total revenue / number of distinct days with sales)
SELECT
  EXTRACT(DOW FROM TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "DayOfWeek",
  COUNT(DISTINCT TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "DaysWithSales",
  SUM("Quantity" * "UnitPrice")
    / COUNT(DISTINCT TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "RevenuePerDay"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "DayOfWeek"
ORDER BY "DayOfWeek";

-- Revenue by hour of day (as recorded in InvoiceDate); no rows exist for hours 0-5 and 21-23.
-- Hour 6 is negative because it contains only returns/cancellations.
SELECT
  EXTRACT(HOUR FROM TO_TIMESTAMP("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "Hour",
  SUM("Quantity" * "UnitPrice") AS "Revenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Hour"
ORDER BY "Hour";

-- Monthly revenue using DATE_TRUNC (returns the first day of each month, with the session time zone attached);
-- totals match the TO_CHAR 'YYYY-MM' version above
SELECT
  DATE_TRUNC('month', TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI')) AS "Month",
  SUM("Quantity" * "UnitPrice") AS "MonthlyRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Month"
ORDER BY "Month";

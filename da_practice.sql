-- Total revenue for each product(Description)
SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;

-- Check the Stock code which do not have number in their code
SELECT DISTINCT("StockCode"),"Description"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"!~ '[0-9]' ;
-- WHERE "StockCode" NOT SIMILAR TO '%[0-9]%' Can also be used;

-- Total revenue without the messy/junk data (POSTAGE,DISCOUNT codes)
SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;

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


-- Revenue by country
SELECT "Country",SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~'[0-9]'
GROUP BY "Country"
ORDER BY "TotalRevenue" DESC;


--Revenue by month
SELECT TO_CHAR(TO_DATE("InvoiceDate", 'MM/DD/YYYY HH24:MI'),'YYYY-MM') AS "Month",
SUM("Quantity"*"UnitPrice") AS "MonthlyRevenue"
FROM  retail_project."OnlineRetailCSV"
WHERE  "StockCode" ~'[0-9]'
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

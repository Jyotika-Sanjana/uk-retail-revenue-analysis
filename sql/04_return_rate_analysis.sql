-- --------------------------------------------------------------
-- 04_return_rate_analysis.sql
-- Project: UK Online Retail Revenue Analysis (PostgreSQL)
-- Purpose: return rate by product, order counts behind each rate, and checks on suspicious products.
-- --------------------------------------------------------------

-- ===== Part 1: Return rate by product =====

-- Return rate by product (returned value / sold value), top 10.
-- Excludes quantities beyond +/-999 and products with sales of 1,000 or less
SELECT "Description",
SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END) AS "SoldValue",
-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END) AS "ReturnedValue",
ROUND(
	100*COALESCE(-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END),0)/SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END),2
	) AS "ReturnRatePact"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"~ '[0-9]'  AND "Quantity" BETWEEN -999 AND 999
GROUP BY "Description"
HAVING SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END)>1000
ORDER BY "ReturnRatePact" DESC
LIMIT 10;

-- How many products pass the sales filter, and how many of them have any returns
SELECT COUNT(*) AS "ProductsResult",
COUNT(*) FILTER(WHERE "ReturnRatePact">0) AS "ProductsWithReturns"
FROM(SELECT "Description",
SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END) AS "SoldValue",
-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END) AS "ReturnedValue",
ROUND(
	100*COALESCE(-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END),0)/SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END),2
	) AS "ReturnRatePact"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"~ '[0-9]'  AND "Quantity" BETWEEN -999 AND 999
GROUP BY "Description"
HAVING SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END)>1000
ORDER BY "ReturnRatePact" DESC) AS t;

-- Same top 10, with the number of sales orders and return orders behind each return rate
SELECT "Description",
COUNT(DISTINCT CASE WHEN "Quantity">0 THEN "InvoiceNo" END) AS "SoldOrders",
COUNT(DISTINCT CASE WHEN "Quantity"<0 THEN "InvoiceNo" END) AS "ReturnedOrders",
SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END) AS "SoldValue",
-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END) AS "ReturnedValue",
ROUND(
	100*COALESCE(-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END),0)/SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END),2
	) AS "ReturnRatePact"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"~ '[0-9]'  AND "Quantity" BETWEEN -999 AND 999
GROUP BY "Description"
HAVING SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END)>1000
ORDER BY "ReturnRatePact" DESC
LIMIT 10;

-- Adds order rate (return orders / sales orders) next to the value-based return rate
SELECT 
    "Description", 
    COUNT(DISTINCT CASE WHEN "Quantity" > 0 THEN "InvoiceNo" END) AS "SoldOrders", 
    COUNT(DISTINCT CASE WHEN "Quantity" < 0 THEN "InvoiceNo" END) AS "ReturnedOrders", 
    SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END) AS "SoldValue", 
    -SUM(CASE WHEN "Quantity" < 0 THEN "Quantity" * "UnitPrice" END) AS "ReturnedValue", 
    ROUND(
	100*COALESCE(-SUM(CASE WHEN "Quantity"<0 THEN "Quantity"*"UnitPrice" END),0)/SUM(CASE WHEN "Quantity">0 THEN "Quantity"*"UnitPrice" END),2
	)  AS "ReturnRatePact", 
    ROUND(
        100.0 * COALESCE(COUNT(DISTINCT CASE WHEN "Quantity" < 0 THEN "InvoiceNo" END), 0) 
        / COALESCE(COUNT(DISTINCT CASE WHEN "Quantity" > 0 THEN "InvoiceNo" END), 0), 
        2
    ) AS "OrderRate" 
FROM retail_project."OnlineRetailCSV" 
WHERE "StockCode" ~ '[0-9]' 
  AND "Quantity" BETWEEN -999 AND 999 
GROUP BY "Description" 
HAVING SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END) > 1000 
ORDER BY "ReturnRatePact" DESC 
LIMIT 10;

-- ===== Part 2: Checking products with a very high return rate =====

-- Distinct unit prices of the top 10 products by return rate,
-- to check whether a product was sold at more than one price
SELECT DISTINCT "Description", "UnitPrice"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" IN (
    SELECT "Description"
    FROM retail_project."OnlineRetailCSV"
    WHERE "StockCode" ~ '[0-9]' AND "Quantity" BETWEEN -999 AND 999
    GROUP BY "Description"
    HAVING SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END) > 1000
    ORDER BY ROUND(
        100 * COALESCE(-SUM(CASE WHEN "Quantity" < 0 THEN "Quantity" * "UnitPrice" END), 0) / 
        SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END), 2
    ) DESC
    LIMIT 10
);

-- Babushka stacking tins: all return rows (quantity -999 to -1)
SELECT "InvoiceNo", "InvoiceDate", "Quantity", "UnitPrice",
       "Quantity" * "UnitPrice" AS "Value"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'SET OF 3 BABUSHKA STACKING TINS'
  AND "Quantity" BETWEEN -999 AND -1
ORDER BY "Quantity";

-- Babushka stacking tins: the 10 largest sale rows (quantity 1 to 999)
SELECT "InvoiceNo", "InvoiceDate", "Quantity", "UnitPrice",
       "Quantity" * "UnitPrice" AS "Value"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'SET OF 3 BABUSHKA STACKING TINS'
  AND "Quantity" BETWEEN 1 AND 999
ORDER BY "Quantity" DESC
LIMIT 10;

-- Babushka stacking tins: the 240-unit sale and credit note, to compare their timestamps
SELECT "InvoiceNo", "InvoiceDate", "Quantity", "UnitPrice",
       "Quantity" * "UnitPrice" AS "Value"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'SET OF 3 BABUSHKA STACKING TINS'
  AND ABS("Quantity") = 240
ORDER BY "InvoiceDate";

-- Babushka stacking tins: return rate after excluding the 240-unit pair
SELECT
	"Description",
	SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END) AS "SoldValue",
	-SUM(CASE WHEN "Quantity" < 0 THEN "Quantity" * "UnitPrice" END) AS "ReturnedValue",
	ROUND(
		100.0 * -SUM(CASE WHEN "Quantity" < 0 THEN "Quantity" * "UnitPrice" END)
		/ SUM(CASE WHEN "Quantity" > 0 THEN "Quantity" * "UnitPrice" END), 2
	) AS "ReturnRatePct"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'SET OF 3 BABUSHKA STACKING TINS'
  AND "StockCode" ~ '[0-9]'
  AND "Quantity" BETWEEN -999 AND 999
  AND ABS("Quantity") <> 240
GROUP BY "Description";

SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;

SELECT DISTINCT("StockCode"),"Description"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"!~ '[0-9]' ;
-- WHERE "StockCode" NOT SIMILAR TO '%[0-9]%' Can also be used;

SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;
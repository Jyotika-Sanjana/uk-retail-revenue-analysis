SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;

-- To check the Stock code which do not have number in their code
SELECT DISTINCT("StockCode"),"Description"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode"!~ '[0-9]' ;
-- WHERE "StockCode" NOT SIMILAR TO '%[0-9]%' Can also be used;

-- Total reveneue without the POSTAGE,DISCOUNT charges
SELECT "Description", SUM("Quantity"*"UnitPrice") AS "TotalRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~ '[0-9]'
GROUP BY "Description"
ORDER BY "TotalRevenue" DESC
LIMIT 10;

-- Total revenue for returns(lost revenue) in this case -- Quantity is negative
SELECT "Description",SUM("Quantity"*"UnitPrice") AS "LostRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~'[0-9]' AND "Quantity" <0
GROUP BY "Description"
ORDER BY "LostRevenue" ASC
LIMIT 10;

-- Big ReturnLoss
SELECT "InvoiceNo", "Quantity", "UnitPrice", "InvoiceDate"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'PAPER CRAFT , LITTLE BIRDIE' AND "Quantity" < 0
ORDER BY "Quantity" ASC
LIMIT 10;

--Check whether the same amount of product that is returned is bought or not
SELECT "InvoiceNo", "Quantity", "UnitPrice", "InvoiceDate"
FROM retail_project."OnlineRetailCSV"
WHERE "Description" = 'PAPER CRAFT , LITTLE BIRDIE' AND "Quantity" = 80995

-- exclude extreme outliers and re-check the lost Revenue
SELECT "Description",SUM("Quantity"*"UnitPrice") AS "LostRevenue"
FROM retail_project."OnlineRetailCSV"
WHERE "StockCode" ~'[0-9]' AND "Quantity" <0 AND "Quantity">-1000
GROUP BY "Description"
ORDER BY "LostRevenue" ASC
LIMIT 10;

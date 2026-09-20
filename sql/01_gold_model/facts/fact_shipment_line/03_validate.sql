USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_shipment_line;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.shipment_lines;

SELECT 'Duplicate shipment_line_id' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT shipment_line_id
    FROM gold.fact_shipment_line
    GROUP BY shipment_line_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Orphan shipment header' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_shipment_line l
LEFT JOIN gold.fact_shipment h
    ON l.shipment_id = h.shipment_id
WHERE h.shipment_id IS NULL;

SELECT 'Invalid shipped quantity' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_shipment_line
WHERE quantity_shipped <= 0;
GO

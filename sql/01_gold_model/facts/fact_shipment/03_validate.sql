USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_shipment;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.shipments;

SELECT 'Duplicate shipment_id' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT shipment_id
    FROM gold.fact_shipment
    GROUP BY shipment_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Orphan sales_order_id vs Silver' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_shipment s
LEFT JOIN silver.sales_orders o
    ON s.sales_order_id = o.sales_order_id
WHERE o.sales_order_id IS NULL;

SELECT 'Delivery before ship date' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_shipment
WHERE actual_delivery_date < ship_date;
GO

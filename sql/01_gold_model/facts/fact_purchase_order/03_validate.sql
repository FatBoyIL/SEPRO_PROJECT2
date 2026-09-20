USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_purchase_order;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.purchase_orders;

SELECT 'Duplicate purchase_order_id' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT purchase_order_id
    FROM gold.fact_purchase_order
    GROUP BY purchase_order_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Invalid PO date sequence' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_purchase_order
WHERE expected_receipt_date < po_date
   OR (actual_receipt_date IS NOT NULL AND actual_receipt_date < po_date);

SELECT 'Non-positive FX rate' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_purchase_order
WHERE fx_rate_to_vnd <= 0;
GO

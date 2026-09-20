USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_purchase_order_line;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.purchase_order_lines;

SELECT 'Duplicate PO line' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT purchase_order_line_id
    FROM gold.fact_purchase_order_line
    GROUP BY purchase_order_line_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Orphan PO header' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_purchase_order_line l
LEFT JOIN gold.fact_purchase_order h
    ON l.purchase_order_id = h.purchase_order_id
WHERE h.purchase_order_id IS NULL;

SELECT 'Invalid quantity/cost' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_purchase_order_line
WHERE quantity_ordered <= 0
   OR unit_price_local < 0
   OR merchandise_value_vnd < 0
   OR freight_cost_vnd < 0
   OR customs_cost_vnd < 0
   OR expedite_cost_vnd < 0
   OR contract_lead_time_days < 0;
GO

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'PO lines in supplier mart' AS validation_check, COUNT_BIG(*) AS result
FROM gold.mart_supplier_performance;

SELECT 'PO lines in fact' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_purchase_order_line;

SELECT 'Duplicate PO-line grain' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT purchase_order_line_id
    FROM gold.mart_supplier_performance
    GROUP BY purchase_order_line_id
    HAVING COUNT(*) > 1
) x;

SELECT 'Landed cost arithmetic mismatch' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_supplier_performance
WHERE ABS
(
    landed_cost_vnd
    - (merchandise_cost_vnd
       + freight_cost_vnd
       + customs_cost_vnd
       + expedite_cost_vnd
       + quality_cost_vnd)
) > 0.01;

SELECT 'TCO arithmetic mismatch' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_supplier_performance
WHERE estimated_tco_vnd IS NOT NULL
  AND ABS(estimated_tco_vnd - (landed_cost_vnd + estimated_holding_cost_vnd)) > 0.01;

SELECT 'Negative lead/late days' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_supplier_performance
WHERE actual_lead_time_days < 0
   OR late_receipt_days < 0
   OR holding_days < 0;

SELECT 'Supplier OTIF proxy note' AS validation_check,
       'True In-Full quantity evidence is unavailable; use supplier_otif_proxy_flag only as timeliness proxy.' AS result;
GO

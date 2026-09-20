USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - DATA COVERAGE CHECKS

   These are not business KPIs.
   They indicate whether missing source evidence may affect
   later analytical conclusions.
   ============================================================ */

SELECT
    SUM(CASE WHEN availability_group = 'Missing snapshot' THEN 1 ELSE 0 END)
        AS orders_with_missing_inventory_snapshot,
    COUNT(*) AS total_orders
FROM gold.mart_order_availability_otif;

SELECT
    SUM(CASE WHEN avg_inventory_value_vnd IS NULL THEN 1 ELSE 0 END)
        AS po_lines_missing_inventory_value,
    SUM(CASE WHEN annual_holding_rate_decimal IS NULL THEN 1 ELSE 0 END)
        AS po_lines_missing_holding_rate,
    COUNT(*) AS total_po_lines
FROM gold.mart_supplier_performance;
GO

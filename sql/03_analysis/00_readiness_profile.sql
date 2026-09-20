USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - READINESS & DATA PROFILE

   Prerequisite:
   Existing Project 2 KPI validation must PASS.

   Mart grains:
   inventory_risk              = 1 product + 1 month
   order_availability_otif     = 1 sales order
   supplier_performance        = 1 purchase order line
   ============================================================ */

-- 1. Inventory-risk time and population coverage
SELECT
    MIN(month_start_date) AS first_month,
    MAX(month_start_date) AS last_month,
    COUNT(DISTINCT month_start_date) AS month_count,
    COUNT(*) AS product_month_rows,
    COUNT(DISTINCT product_key) AS product_count
FROM gold.mart_inventory_risk;

-- 2. Order availability / OTIF population
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN complete_flag = 1 THEN 1 ELSE 0 END) AS complete_orders,
    SUM(CASE WHEN missing_snapshot_line_count > 0 THEN 1 ELSE 0 END)
        AS orders_with_missing_inventory_snapshot,
    SUM(CASE WHEN availability_group = 'No stock' THEN 1 ELSE 0 END)
        AS no_stock_orders,
    SUM(CASE WHEN availability_group = 'Partially available' THEN 1 ELSE 0 END)
        AS partially_available_orders
FROM gold.mart_order_availability_otif;

-- 3. Availability-group sample size
SELECT
    availability_group,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders
FROM gold.mart_order_availability_otif
GROUP BY availability_group
ORDER BY total_orders DESC;

-- 4. Supplier-performance coverage
SELECT
    COUNT(*) AS po_lines,
    COUNT(DISTINCT supplier_key) AS supplier_count,
    SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END) AS received_po_lines,
    SUM(CASE WHEN actual_receipt_date IS NULL THEN 1 ELSE 0 END) AS unreceived_po_lines,
    SUM(CASE WHEN avg_inventory_value_vnd IS NULL THEN 1 ELSE 0 END)
        AS po_lines_missing_inventory_value,
    SUM(CASE WHEN annual_holding_rate_decimal IS NULL THEN 1 ELSE 0 END)
        AS po_lines_missing_holding_rate,
    SUM(CASE WHEN estimated_tco_vnd IS NULL THEN 1 ELSE 0 END)
        AS po_lines_without_estimated_tco
FROM gold.mart_supplier_performance;
GO

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - WAREHOUSE / SKU RISK DIAGNOSTIC

   Requirement alignment:
   Analyze stockout by Product, Category, Warehouse and Month.
   fact_inventory_snapshot grain = Date x Product x Warehouse.
   ============================================================ */

-- 1. Product x Warehouse x Month
;WITH SnapshotBase AS
(
    SELECT
        DATEFROMPARTS(YEAR(d.[date]), MONTH(d.[date]), 1) AS month_start_date,
        s.product_key,
        s.warehouse_key,
        s.on_hand_qty,
        s.available_qty,
        s.backlog_qty,
        s.inventory_value_vnd,
        CAST(s.stockout_flag AS INT) AS stockout_flag
    FROM gold.fact_inventory_snapshot s
    INNER JOIN gold.dim_date d
        ON s.snapshot_date_key = d.date_key
)
SELECT
    b.month_start_date,
    b.warehouse_key,
    w.warehouse_name,
    w.city,
    b.product_key,
    p.sku,
    p.product_name,
    p.category,
    COUNT(*) AS observed_sku_days,
    SUM(b.stockout_flag) AS stockout_days,
    CAST(SUM(b.stockout_flag) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(12,6))
        AS stockout_rate,
    CAST(AVG(CAST(b.on_hand_qty AS DECIMAL(18,4))) AS DECIMAL(18,4))
        AS avg_on_hand_qty,
    CAST(AVG(CAST(b.available_qty AS DECIMAL(18,4))) AS DECIMAL(18,4))
        AS avg_available_qty,
    CAST(AVG(CAST(b.backlog_qty AS DECIMAL(18,4))) AS DECIMAL(18,4))
        AS avg_backlog_qty,
    CAST(AVG(b.inventory_value_vnd) AS DECIMAL(18,2))
        AS avg_inventory_value_vnd
FROM SnapshotBase b
LEFT JOIN gold.dim_warehouse w
    ON b.warehouse_key = w.warehouse_key
LEFT JOIN gold.dim_product p
    ON b.product_key = p.product_key
GROUP BY
    b.month_start_date,
    b.warehouse_key,
    w.warehouse_name,
    w.city,
    b.product_key,
    p.sku,
    p.product_name,
    p.category
ORDER BY stockout_rate DESC, stockout_days DESC, b.month_start_date;

-- 2. Warehouse-level exposure across all SKUs
SELECT
    s.warehouse_key,
    w.warehouse_name,
    w.city,
    COUNT(*) AS observed_sku_days,
    SUM(CAST(s.stockout_flag AS INT)) AS stockout_sku_days,
    CAST(
        SUM(CAST(s.stockout_flag AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(12,6)
    ) AS weighted_stockout_rate,
    CAST(AVG(s.inventory_value_vnd) AS DECIMAL(18,2)) AS avg_daily_inventory_value_vnd
FROM gold.fact_inventory_snapshot s
LEFT JOIN gold.dim_warehouse w
    ON s.warehouse_key = w.warehouse_key
GROUP BY s.warehouse_key, w.warehouse_name, w.city
ORDER BY weighted_stockout_rate DESC, stockout_sku_days DESC;
GO

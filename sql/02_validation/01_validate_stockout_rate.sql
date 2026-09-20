USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - STOCKOUT RATE

   Stockout Rate
   = Stockout SKU-Warehouse-Days / Observed SKU-Warehouse-Days
   ============================================================ */

SELECT
    SUM(stockout_sku_warehouse_days) AS stockout_sku_warehouse_days,
    SUM(observed_sku_warehouse_days) AS observed_sku_warehouse_days,
    CAST
    (
        SUM(stockout_sku_warehouse_days) * 1.0
        / NULLIF(SUM(observed_sku_warehouse_days), 0)
        AS DECIMAL(12,6)
    ) AS stockout_rate
FROM gold.mart_inventory_risk;
GO

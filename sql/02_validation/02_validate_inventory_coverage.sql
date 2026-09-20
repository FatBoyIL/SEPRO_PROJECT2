USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - INVENTORY COVERAGE

   Coverage uses:
   Average Network On-Hand / Average Daily Demand (60 days)
   ============================================================ */

SELECT
    month_start_date,
    product_key,
    avg_network_on_hand_qty,
    avg_daily_demand_60d,
    inventory_coverage_days,
    stockout_rate,
    fulfillment_risk_rate
FROM gold.mart_inventory_risk
ORDER BY month_start_date, product_key;
GO

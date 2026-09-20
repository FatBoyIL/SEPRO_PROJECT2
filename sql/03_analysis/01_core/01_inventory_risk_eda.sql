USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - INVENTORY RISK EDA

   Analyze distributions before setting risk thresholds.
   ============================================================ */

;WITH Base AS
(
    SELECT
        stockout_rate,
        inventory_coverage_days,
        avg_daily_demand_60d,
        avg_network_inventory_value_vnd,
        fulfillment_risk_rate
    FROM gold.mart_inventory_risk
),
Pct AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_p90,

        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_p90,

        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_daily_demand_60d) OVER () AS demand_median,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY avg_daily_demand_60d) OVER () AS demand_p90,

        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_network_inventory_value_vnd) OVER () AS inventory_value_median,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY avg_network_inventory_value_vnd) OVER () AS inventory_value_p90,

        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY fulfillment_risk_rate) OVER () AS fulfillment_risk_median,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY fulfillment_risk_rate) OVER () AS fulfillment_risk_p90
    FROM Base
)
SELECT
    COUNT(*) AS product_month_rows,
    MIN(stockout_rate) AS stockout_min,
    AVG(stockout_rate) AS stockout_avg,
    MAX(stockout_rate) AS stockout_max,
    CAST(p.stockout_p25 AS DECIMAL(18,4)) AS stockout_p25,
    CAST(p.stockout_median AS DECIMAL(18,4)) AS stockout_median,
    CAST(p.stockout_p75 AS DECIMAL(18,4)) AS stockout_p75,
    CAST(p.stockout_p90 AS DECIMAL(18,4)) AS stockout_p90,

    CAST(p.coverage_p25 AS DECIMAL(18,4)) AS coverage_p25,
    CAST(p.coverage_median AS DECIMAL(18,4)) AS coverage_median,
    CAST(p.coverage_p75 AS DECIMAL(18,4)) AS coverage_p75,
    CAST(p.coverage_p90 AS DECIMAL(18,4)) AS coverage_p90,

    CAST(p.demand_median AS DECIMAL(18,4)) AS demand_median,
    CAST(p.demand_p90 AS DECIMAL(18,4)) AS demand_p90,

    CAST(p.inventory_value_median AS DECIMAL(18,2)) AS inventory_value_median,
    CAST(p.inventory_value_p90 AS DECIMAL(18,2)) AS inventory_value_p90,

    CAST(p.fulfillment_risk_median AS DECIMAL(18,4)) AS fulfillment_risk_median,
    CAST(p.fulfillment_risk_p90 AS DECIMAL(18,4)) AS fulfillment_risk_p90
FROM Base
CROSS JOIN Pct p
GROUP BY
    p.stockout_p25, p.stockout_median, p.stockout_p75, p.stockout_p90,
    p.coverage_p25, p.coverage_median, p.coverage_p75, p.coverage_p90,
    p.demand_median, p.demand_p90,
    p.inventory_value_median, p.inventory_value_p90,
    p.fulfillment_risk_median, p.fulfillment_risk_p90;

-- Monthly trend: use weighted rates from raw counts
SELECT
    month_start_date,
    SUM(observed_sku_warehouse_days) AS observed_sku_warehouse_days,
    SUM(stockout_sku_warehouse_days) AS stockout_sku_warehouse_days,
    CAST(
        SUM(stockout_sku_warehouse_days) * 1.0
        / NULLIF(SUM(observed_sku_warehouse_days), 0)
        AS DECIMAL(12,6)
    ) AS weighted_stockout_rate,
    AVG(inventory_coverage_days) AS avg_inventory_coverage_days,
    SUM(eligible_fulfillment_line_count) AS eligible_fulfillment_lines,
    SUM(late_or_incomplete_line_count) AS late_or_incomplete_lines,
    CAST(
        SUM(late_or_incomplete_line_count) * 1.0
        / NULLIF(SUM(eligible_fulfillment_line_count), 0)
        AS DECIMAL(12,6)
    ) AS weighted_fulfillment_risk_rate
FROM gold.mart_inventory_risk
GROUP BY month_start_date
ORDER BY month_start_date;
GO

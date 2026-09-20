USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - SKU RISK SEGMENTATION & PARETO

   Thresholds use dataset percentiles, not arbitrary cutoffs.
   Flags are intentionally non-exclusive.
   ============================================================ */

;WITH Base AS
(
    SELECT *
    FROM gold.mart_inventory_risk
),
Thresholds AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stockout_rate) OVER () AS stockout_p75,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inventory_coverage_days) OVER () AS coverage_p75,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_daily_demand_60d) OVER () AS demand_p75
    FROM Base
)
SELECT
    b.month_start_date,
    b.product_key,
    p.sku,
    p.product_name,
    p.category,
    b.stockout_rate,
    b.inventory_coverage_days,
    b.avg_daily_demand_60d,
    b.avg_network_inventory_value_vnd,
    b.fulfillment_risk_rate,

    CASE
        WHEN b.stockout_rate >= t.stockout_p75
         AND b.inventory_coverage_days <= t.coverage_p25
        THEN 1 ELSE 0
    END AS shortage_risk_flag,

    CASE
        WHEN b.stockout_rate >= t.stockout_p75
         AND b.avg_daily_demand_60d >= t.demand_p75
        THEN 1 ELSE 0
    END AS priority_replenishment_flag,

    CASE
        WHEN b.inventory_coverage_days >= t.coverage_p75
         AND b.avg_daily_demand_60d < t.demand_p75
        THEN 1 ELSE 0
    END AS working_capital_risk_flag,

    CASE
        WHEN b.stockout_rate <= t.stockout_p25
         AND b.inventory_coverage_days >= t.coverage_p75
        THEN 1 ELSE 0
    END AS possible_overstock_flag

FROM Base b
CROSS JOIN Thresholds t
LEFT JOIN gold.dim_product p
    ON b.product_key = p.product_key
ORDER BY
    shortage_risk_flag DESC,
    priority_replenishment_flag DESC,
    working_capital_risk_flag DESC,
    b.stockout_rate DESC;

-- Pareto: which products create most stockout exposure?
;WITH ProductAgg AS
(
    SELECT
        product_key,
        SUM(stockout_sku_warehouse_days) AS stockout_days,
        SUM(observed_sku_warehouse_days) AS observed_days
    FROM gold.mart_inventory_risk
    GROUP BY product_key
),
Ranked AS
(
    SELECT
        product_key,
        stockout_days,
        observed_days,
        ROW_NUMBER() OVER (ORDER BY stockout_days DESC, product_key) AS entity_rank,
        COUNT(*) OVER () AS entity_count,
        SUM(stockout_days) OVER () AS total_stockout_days,
        SUM(stockout_days) OVER
        (
            ORDER BY stockout_days DESC, product_key
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_stockout_days
    FROM ProductAgg
)
SELECT
    r.product_key,
    p.sku,
    p.product_name,
    p.category,
    r.entity_rank,
    r.entity_count,
    r.stockout_days,
    r.observed_days,
    CAST(r.stockout_days * 1.0 / NULLIF(r.observed_days, 0) AS DECIMAL(12,6))
        AS weighted_stockout_rate,
    CASE
        WHEN r.entity_rank <= CEILING(r.entity_count * 0.20)
        THEN 1 ELSE 0
    END AS top_20_product_flag,
    CAST(r.cumulative_stockout_days * 1.0
         / NULLIF(r.total_stockout_days, 0) AS DECIMAL(12,6))
        AS cumulative_stockout_share
FROM Ranked r
LEFT JOIN gold.dim_product p
    ON r.product_key = p.product_key
ORDER BY r.entity_rank;
GO

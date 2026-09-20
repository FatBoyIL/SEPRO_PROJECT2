USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Duplicate product-month grain' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT month_start_date, product_key
    FROM gold.mart_inventory_risk
    GROUP BY month_start_date, product_key
    HAVING COUNT(*) > 1
) x;

SELECT 'Invalid stockout rate' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_inventory_risk
WHERE stockout_rate < 0 OR stockout_rate > 1;

SELECT 'Invalid fulfillment risk rate' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_inventory_risk
WHERE fulfillment_risk_rate < 0 OR fulfillment_risk_rate > 1;

SELECT 'Negative coverage' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_inventory_risk
WHERE inventory_coverage_days < 0;

/* Reconcile mart stockout numerator/denominator back to snapshot fact. */
SELECT
    m.month_start_date,
    SUM(m.stockout_sku_warehouse_days) AS mart_stockout_days,
    SUM(m.observed_sku_warehouse_days) AS mart_observed_days
FROM gold.mart_inventory_risk m
GROUP BY m.month_start_date
ORDER BY m.month_start_date;
GO

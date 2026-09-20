USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* Validate grain, row reconciliation and basic inventory rules. */

SELECT 'Gold row count' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_inventory_snapshot;

SELECT 'Silver row count' AS validation_check, COUNT_BIG(*) AS result
FROM silver.inventory_daily_snapshot;

SELECT 'Duplicate Gold grain' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT snapshot_date_key, product_key, warehouse_key
    FROM gold.fact_inventory_snapshot
    GROUP BY snapshot_date_key, product_key, warehouse_key
    HAVING COUNT(*) > 1
) x;

SELECT 'Negative inventory/value fields' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_inventory_snapshot
WHERE on_hand_qty < 0
   OR on_order_qty < 0
   OR backlog_qty < 0
   OR inventory_value_vnd < 0;

SELECT 'Stockout flag inconsistent with source rule' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_inventory_snapshot
WHERE stockout_flag = 1
  AND NOT (on_hand_qty = 0 AND backlog_qty > 0);
GO

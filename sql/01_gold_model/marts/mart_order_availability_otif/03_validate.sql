USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Sales orders in mart' AS validation_check, COUNT_BIG(*) AS result
FROM gold.mart_order_availability_otif;

SELECT 'Sales orders in Silver' AS validation_check, COUNT_BIG(*) AS result
FROM silver.sales_orders;

SELECT 'Duplicate order grain' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT sales_order_id
    FROM gold.mart_order_availability_otif
    GROUP BY sales_order_id
    HAVING COUNT(*) > 1
) x;

SELECT 'OTIF=1 but prerequisite failed' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_order_availability_otif
WHERE otif_flag = 1
  AND (delivered_flag <> 1
       OR complete_flag <> 1
       OR on_time_flag <> 1);

SELECT 'On-time populated for incomplete order' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_order_availability_otif
WHERE complete_flag = 0
  AND on_time_flag IS NOT NULL;

SELECT 'Availability line counts do not reconcile' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.mart_order_availability_otif
WHERE order_line_count <>
      missing_snapshot_line_count
    + available_in_full_line_count
    + partial_available_line_count
    + no_stock_line_count;

/* Customer OTIF denominator is delivered orders, not shipment rows. */
SELECT
    CAST(SUM(CASE WHEN delivered_flag = 1 THEN otif_flag ELSE 0 END) * 1.0
         / NULLIF(SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END), 0)
         AS DECIMAL(12,6)) AS customer_otif
FROM gold.mart_order_availability_otif;
GO

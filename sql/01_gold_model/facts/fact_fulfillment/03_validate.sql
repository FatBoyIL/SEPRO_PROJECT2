USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

SELECT 'Gold fulfillment rows' AS validation_check, COUNT_BIG(*) AS result
FROM gold.fact_fulfillment;

SELECT 'Silver sales order line rows' AS validation_check, COUNT_BIG(*) AS result
FROM silver.sales_order_lines;

SELECT 'Missing order lines in fulfillment' AS validation_check, COUNT_BIG(*) AS issue_count
FROM
(
    SELECT sales_order_line_id FROM silver.sales_order_lines
    EXCEPT
    SELECT sales_order_line_id FROM gold.fact_fulfillment
) x;

SELECT 'Complete flag mismatch' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_fulfillment
WHERE line_complete_flag <>
      CASE WHEN quantity_shipped_total >= quantity_ordered THEN 1 ELSE 0 END;

SELECT 'On-time populated for incomplete line' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_fulfillment
WHERE line_complete_flag = 0
  AND line_on_time_flag IS NOT NULL;

SELECT 'Negative late days' AS validation_check, COUNT_BIG(*) AS issue_count
FROM gold.fact_fulfillment
WHERE late_delivery_days < 0;
GO

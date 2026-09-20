USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - AVAILABILITY AT ORDER VS CUSTOMER OTIF

   Availability groups:
   - Available in full
   - Partially available
   - No stock
   - Missing snapshot
   ============================================================ */

SELECT
    availability_group,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END) AS otif_orders,
    CAST
    (
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(12,6)
    ) AS customer_otif
FROM gold.mart_order_availability_otif
GROUP BY availability_group
ORDER BY availability_group;
GO

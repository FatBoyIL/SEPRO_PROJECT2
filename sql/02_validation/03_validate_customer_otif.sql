USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - CUSTOMER OTIF

   IMPORTANT:
   Denominator = Delivered Orders
   Grain = Sales Order
   NOT Shipment.
   ============================================================ */

SELECT
    SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END) AS otif_orders,
    CAST
    (
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(12,6)
    ) AS customer_otif
FROM gold.mart_order_availability_otif;
GO

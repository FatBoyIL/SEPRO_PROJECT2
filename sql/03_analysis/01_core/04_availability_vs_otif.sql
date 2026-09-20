USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - AVAILABILITY AT ORDER VS CUSTOMER OTIF

   Customer OTIF denominator = Delivered Orders.
   Grain = Sales Order, not Shipment.
   Association != causation.
   ============================================================ */

;WITH GroupMetrics AS
(
    SELECT
        availability_group,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END)
            AS otif_orders,
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 0 THEN 1 ELSE 0 END)
            AS non_otif_delivered_orders,
        SUM(CASE WHEN complete_flag = 0 THEN 1 ELSE 0 END)
            AS incomplete_orders
    FROM gold.mart_order_availability_otif
    GROUP BY availability_group
)
SELECT
    availability_group,
    total_orders,
    delivered_orders,
    otif_orders,
    non_otif_delivered_orders,
    incomplete_orders,
    CAST(otif_orders * 1.0 / NULLIF(delivered_orders, 0) AS DECIMAL(12,6))
        AS customer_otif
FROM GroupMetrics
ORDER BY total_orders DESC;

-- Effect-size style comparison versus Available in full
;WITH GroupMetrics AS
(
    SELECT
        availability_group,
        SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END)
            AS otif_orders
    FROM gold.mart_order_availability_otif
    GROUP BY availability_group
),
Rates AS
(
    SELECT
        availability_group,
        delivered_orders,
        CAST(otif_orders * 1.0 / NULLIF(delivered_orders, 0) AS DECIMAL(12,6))
            AS otif_rate
    FROM GroupMetrics
),
Baseline AS
(
    SELECT otif_rate AS baseline_otif
    FROM Rates
    WHERE availability_group = 'Available in full'
)
SELECT
    r.availability_group,
    r.delivered_orders,
    r.otif_rate,
    CAST((r.otif_rate - b.baseline_otif) * 100.0 AS DECIMAL(12,2))
        AS otif_gap_pp_vs_available_in_full
FROM Rates r
CROSS JOIN Baseline b
ORDER BY r.otif_rate DESC;

-- Diagnostic list: delivered orders that failed OTIF
SELECT TOP (200)
    o.sales_order_id,
    c.customer_name,
    c.segment,
    c.industry,
    o.order_date,
    o.requested_delivery_date,
    o.availability_group,
    o.order_line_count,
    o.partial_available_line_count,
    o.no_stock_line_count,
    o.order_quantity_ordered,
    o.order_quantity_shipped,
    o.complete_flag,
    o.final_delivery_date,
    o.days_late
FROM gold.mart_order_availability_otif o
LEFT JOIN gold.dim_customer c
    ON o.customer_key = c.customer_key
WHERE o.delivered_flag = 1
  AND o.otif_flag = 0
ORDER BY
    CASE WHEN o.complete_flag = 0 THEN 1 ELSE 0 END DESC,
    o.days_late DESC;
GO

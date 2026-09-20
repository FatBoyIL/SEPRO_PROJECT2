USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - SKU AVAILABILITY -> LATE FULFILLMENT DIAGNOSTIC

   Goal:
   Trace Product / Order Line availability at order time to the
   line-level fulfillment outcome.

   Availability is network-level across warehouses because the Gold
   mart/source does not contain an allocated warehouse at order line.
   Association != causation.
   ============================================================ */

DROP TABLE IF EXISTS #LineEvidence;

;WITH NetworkInventory AS
(
    SELECT
        snapshot_date_key,
        product_key,
        SUM(available_qty) AS network_available_qty,
        SUM(on_hand_qty) AS network_on_hand_qty,
        SUM(backlog_qty) AS network_backlog_qty,
        SUM(CAST(stockout_flag AS INT)) AS stockout_warehouse_count
    FROM gold.fact_inventory_snapshot
    GROUP BY snapshot_date_key, product_key
)
SELECT
    o.sales_order_id,
    l.sales_order_line_id,
    o.order_date,
    o.customer_key,
    l.product_key,
    l.quantity_ordered,
    n.network_available_qty,
    n.network_on_hand_qty,
    n.network_backlog_qty,
    n.stockout_warehouse_count,
    CASE
        WHEN n.product_key IS NULL THEN 'Missing snapshot'
        WHEN n.network_available_qty <= 0 THEN 'No stock'
        WHEN n.network_available_qty < l.quantity_ordered THEN 'Partially available'
        ELSE 'Available in full'
    END AS line_availability_group,
    f.quantity_shipped_total,
    f.promised_delivery_date,
    f.completion_delivery_date,
    f.line_complete_flag,
    f.line_on_time_flag,
    f.late_delivery_days,
    CASE WHEN f.sales_order_line_id IS NULL THEN 1 ELSE 0 END
        AS missing_fulfillment_record_flag,
    CASE
        WHEN f.sales_order_line_id IS NULL THEN NULL
        WHEN f.line_complete_flag = 0 THEN 1
        WHEN f.line_on_time_flag = 0 THEN 1
        ELSE 0
    END AS late_or_incomplete_flag
INTO #LineEvidence
FROM gold.fact_sales_order_line l
INNER JOIN gold.fact_sales_order o
    ON l.sales_order_id = o.sales_order_id
LEFT JOIN NetworkInventory n
    ON n.snapshot_date_key = o.order_date_key
   AND n.product_key = l.product_key
LEFT JOIN gold.fact_fulfillment f
    ON l.sales_order_line_id = f.sales_order_line_id;

-- 1. Product-level relationship between availability and fulfillment risk
SELECT
    e.product_key,
    p.sku,
    p.product_name,
    p.category,
    e.line_availability_group,
    COUNT(*) AS order_lines,
    SUM(CASE WHEN e.missing_fulfillment_record_flag = 0 THEN 1 ELSE 0 END)
        AS lines_with_fulfillment_evidence,
    SUM(CASE WHEN e.late_or_incomplete_flag = 1 THEN 1 ELSE 0 END)
        AS late_or_incomplete_lines,
    CAST(
        SUM(CASE WHEN e.late_or_incomplete_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN e.missing_fulfillment_record_flag = 0 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(12,6)
    ) AS fulfillment_risk_rate
FROM #LineEvidence e
LEFT JOIN gold.dim_product p
    ON e.product_key = p.product_key
GROUP BY
    e.product_key,
    p.sku,
    p.product_name,
    p.category,
    e.line_availability_group
ORDER BY fulfillment_risk_rate DESC, late_or_incomplete_lines DESC;

-- 2. Investigation list: lines that were late / incomplete or had missing evidence
SELECT TOP (300)
    e.sales_order_id,
    e.sales_order_line_id,
    e.order_date,
    c.customer_name,
    p.sku,
    p.product_name,
    e.quantity_ordered,
    e.network_available_qty,
    e.network_on_hand_qty,
    e.network_backlog_qty,
    e.line_availability_group,
    e.quantity_shipped_total,
    e.promised_delivery_date,
    e.completion_delivery_date,
    e.line_complete_flag,
    e.line_on_time_flag,
    e.late_delivery_days,
    e.missing_fulfillment_record_flag
FROM #LineEvidence e
LEFT JOIN gold.dim_product p
    ON e.product_key = p.product_key
LEFT JOIN gold.dim_customer c
    ON e.customer_key = c.customer_key
WHERE e.late_or_incomplete_flag = 1
   OR e.missing_fulfillment_record_flag = 1
ORDER BY
    e.missing_fulfillment_record_flag DESC,
    e.late_delivery_days DESC,
    e.order_date;

DROP TABLE IF EXISTS #LineEvidence;
GO

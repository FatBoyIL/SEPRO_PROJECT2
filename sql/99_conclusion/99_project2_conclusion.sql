USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - DECISION-READY CONCLUSION

   Q1 SKU / warehouse stockout & fulfillment risk
   Q2 Availability at Order vs Customer OTIF
   Q3 Supplier reliability / total-cost trade-off
   ============================================================ */

-- A. Product-level stockout + fulfillment risk
;WITH ProductRisk AS
(
    SELECT
        product_key,
        SUM(stockout_sku_warehouse_days) AS stockout_days,
        SUM(observed_sku_warehouse_days) AS observed_days,
        AVG(inventory_coverage_days) AS avg_coverage_days,
        SUM(late_or_incomplete_line_count) AS late_or_incomplete_lines,
        SUM(eligible_fulfillment_line_count) AS eligible_fulfillment_lines,
        AVG(avg_network_inventory_value_vnd) AS avg_inventory_value_vnd
    FROM gold.mart_inventory_risk
    GROUP BY product_key
)
SELECT TOP (30)
    r.product_key,
    p.sku,
    p.product_name,
    p.category,
    CAST(r.stockout_days * 1.0 / NULLIF(r.observed_days, 0)
         AS DECIMAL(12,6)) AS weighted_stockout_rate,
    r.avg_coverage_days,
    CAST(r.late_or_incomplete_lines * 1.0
         / NULLIF(r.eligible_fulfillment_lines, 0)
         AS DECIMAL(12,6)) AS fulfillment_risk_rate,
    r.avg_inventory_value_vnd
FROM ProductRisk r
LEFT JOIN gold.dim_product p
    ON r.product_key = p.product_key
ORDER BY weighted_stockout_rate DESC, fulfillment_risk_rate DESC;

-- B. Warehouse stockout exposure
SELECT
    s.warehouse_key,
    w.warehouse_name,
    COUNT(*) AS observed_sku_days,
    SUM(CAST(s.stockout_flag AS INT)) AS stockout_sku_days,
    CAST(SUM(CAST(s.stockout_flag AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
         AS DECIMAL(12,6)) AS weighted_stockout_rate
FROM gold.fact_inventory_snapshot s
LEFT JOIN gold.dim_warehouse w
    ON s.warehouse_key = w.warehouse_key
GROUP BY s.warehouse_key, w.warehouse_name
ORDER BY weighted_stockout_rate DESC, stockout_sku_days DESC;

-- C. Availability at order vs Customer OTIF
SELECT
    availability_group,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END)
        AS otif_orders,
    CAST(
        SUM(CASE WHEN delivered_flag = 1 AND otif_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / NULLIF(SUM(CASE WHEN delivered_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(12,6)
    ) AS customer_otif
FROM gold.mart_order_availability_otif
GROUP BY availability_group
ORDER BY total_orders DESC;

-- D. Supplier overall trade-off
;WITH SupplierAgg AS
(
    SELECT
        supplier_key,
        COUNT(*) AS po_lines,
        SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END) AS received_po_lines,
        SUM(CASE WHEN received_flag = 1
                 THEN CAST(supplier_otif_proxy_flag AS INT) ELSE 0 END)
            AS on_time_received_lines,
        AVG(CASE WHEN received_flag = 1
                 THEN CAST(actual_lead_time_days AS DECIMAL(18,4)) END)
            AS avg_actual_lead_time_days,
        SUM(expedite_cost_vnd) AS expedite_cost_vnd,
        SUM(quality_cost_vnd) AS quality_cost_vnd,
        SUM(landed_cost_vnd) AS landed_cost_vnd,
        SUM(estimated_tco_vnd) AS estimated_tco_vnd,
        SUM(CASE WHEN estimated_tco_vnd IS NOT NULL THEN 1 ELSE 0 END)
            AS tco_available_lines
    FROM gold.mart_supplier_performance
    GROUP BY supplier_key
)
SELECT
    a.supplier_key,
    s.supplier_name,
    a.received_po_lines,
    CAST(a.on_time_received_lines * 1.0 / NULLIF(a.received_po_lines, 0)
         AS DECIMAL(12,6)) AS supplier_timeliness_proxy_rate,
    a.avg_actual_lead_time_days,
    a.expedite_cost_vnd,
    a.quality_cost_vnd,
    a.landed_cost_vnd,
    a.estimated_tco_vnd,
    a.tco_available_lines
FROM SupplierAgg a
LEFT JOIN gold.dim_supplier s
    ON a.supplier_key = s.supplier_key
ORDER BY a.received_po_lines DESC;

-- E. Scope / limitations
SELECT 'Inventory Coverage uses the project 60-day demand window.' AS limitation
UNION ALL
SELECT 'Availability at order is network-level across warehouses, not allocated-warehouse availability.'
UNION ALL
SELECT 'Customer OTIF denominator is Delivered Orders at Sales Order grain.'
UNION ALL
SELECT 'Supplier OTIF is a receipt-timeliness proxy because quantity-received evidence is not available.'
UNION ALL
SELECT 'Estimated TCO is a proxy and should be read together with its coverage rate.'
UNION ALL
SELECT 'Availability vs OTIF is an observational association, not causal proof.';
GO

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - SUPPLIER x PRODUCT DIAGNOSTIC

   Goal:
   A supplier can perform differently by product. Compare reliability
   and cost at Supplier x Product grain without inventing a composite
   supplier score.

   supplier_otif_proxy_flag is a receipt-timeliness proxy only.
   True In-Full cannot be calculated because quantity_received is not
   available in the supplied Gold purchase-order data.
   ============================================================ */

;WITH Received AS
(
    SELECT
        supplier_key,
        product_key,
        actual_lead_time_days,
        late_receipt_days
    FROM gold.mart_supplier_performance
    WHERE received_flag = 1
), Pct AS
(
    SELECT DISTINCT
        supplier_key,
        product_key,
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY actual_lead_time_days)
            OVER (PARTITION BY supplier_key, product_key)
            AS median_actual_lead_time_days,
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY actual_lead_time_days)
            OVER (PARTITION BY supplier_key, product_key)
            AS p90_actual_lead_time_days,
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY late_receipt_days)
            OVER (PARTITION BY supplier_key, product_key)
            AS p90_late_receipt_days
    FROM Received
), Agg AS
(
    SELECT
        supplier_key,
        product_key,
        COUNT(*) AS po_lines,
        SUM(quantity_ordered) AS quantity_ordered,
        SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END) AS received_po_lines,
        SUM(CASE
                WHEN received_flag = 1
                THEN CAST(supplier_otif_proxy_flag AS INT)
                ELSE 0
            END) AS on_time_received_lines,
        SUM(landed_cost_vnd) AS landed_cost_vnd,
        SUM(expedite_cost_vnd) AS expedite_cost_vnd,
        SUM(quality_cost_vnd) AS quality_cost_vnd,
        SUM(estimated_tco_vnd) AS estimated_tco_vnd,
        SUM(CASE WHEN estimated_tco_vnd IS NOT NULL THEN 1 ELSE 0 END)
            AS tco_available_lines,
        SUM(CASE WHEN estimated_tco_vnd IS NOT NULL THEN quantity_ordered ELSE 0 END)
            AS tco_covered_quantity
    FROM gold.mart_supplier_performance
    GROUP BY supplier_key, product_key
)
SELECT
    a.supplier_key,
    s.supplier_name,
    s.country,
    a.product_key,
    p.sku,
    p.product_name,
    p.category,
    a.po_lines,
    a.received_po_lines,
    CAST(a.on_time_received_lines * 1.0 / NULLIF(a.received_po_lines, 0)
         AS DECIMAL(12,6)) AS supplier_timeliness_proxy_rate,
    CAST(pc.median_actual_lead_time_days AS DECIMAL(18,4))
        AS median_actual_lead_time_days,
    CAST(pc.p90_actual_lead_time_days AS DECIMAL(18,4))
        AS p90_actual_lead_time_days,
    CAST(pc.p90_late_receipt_days AS DECIMAL(18,4))
        AS p90_late_receipt_days,
    a.quantity_ordered,
    CAST(a.landed_cost_vnd / NULLIF(CAST(a.quantity_ordered AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS landed_cost_per_ordered_unit_vnd,
    a.expedite_cost_vnd,
    a.quality_cost_vnd,
    CAST(a.tco_available_lines * 1.0 / NULLIF(a.po_lines, 0) AS DECIMAL(12,6))
        AS tco_line_coverage_rate,
    CAST(a.estimated_tco_vnd / NULLIF(CAST(a.tco_covered_quantity AS DECIMAL(18,4)), 0)
         AS DECIMAL(18,2)) AS estimated_tco_per_covered_unit_vnd
FROM Agg a
LEFT JOIN Pct pc
    ON a.supplier_key = pc.supplier_key
   AND a.product_key = pc.product_key
LEFT JOIN gold.dim_supplier s
    ON a.supplier_key = s.supplier_key
LEFT JOIN gold.dim_product p
    ON a.product_key = p.product_key
ORDER BY p.sku, a.received_po_lines DESC, s.supplier_name;
GO

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - SUPPLIER RELIABILITY & TCO

   supplier_otif_proxy_flag is a TIMELINESS proxy only.
   Source does not contain quantity-received evidence for true In-Full.
   No composite "best supplier" score is created.
   ============================================================ */

;WITH Received AS
(
    SELECT
        supplier_key,
        actual_lead_time_days,
        late_receipt_days
    FROM gold.mart_supplier_performance
    WHERE received_flag = 1
),
Pct AS
(
    SELECT DISTINCT
        supplier_key,
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY actual_lead_time_days)
            OVER (PARTITION BY supplier_key) AS median_lead_time_days,
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY actual_lead_time_days)
            OVER (PARTITION BY supplier_key) AS p90_lead_time_days,
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY late_receipt_days)
            OVER (PARTITION BY supplier_key) AS p90_late_receipt_days
    FROM Received
),
Agg AS
(
    SELECT
        supplier_key,
        COUNT(*) AS po_lines,
        SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END) AS received_po_lines,
        SUM(CASE
                WHEN received_flag = 1
                THEN CAST(supplier_otif_proxy_flag AS INT)
                ELSE 0
            END) AS on_time_received_lines,
        SUM(merchandise_cost_vnd) AS merchandise_cost_vnd,
        SUM(freight_cost_vnd) AS freight_cost_vnd,
        SUM(customs_cost_vnd) AS customs_cost_vnd,
        SUM(expedite_cost_vnd) AS expedite_cost_vnd,
        SUM(quality_cost_vnd) AS quality_cost_vnd,
        SUM(landed_cost_vnd) AS landed_cost_vnd,
        SUM(estimated_holding_cost_vnd) AS estimated_holding_cost_vnd,
        SUM(estimated_tco_vnd) AS estimated_tco_vnd,
        SUM(CASE WHEN estimated_tco_vnd IS NOT NULL THEN 1 ELSE 0 END)
            AS tco_available_lines
    FROM gold.mart_supplier_performance
    GROUP BY supplier_key
)
SELECT
    a.supplier_key,
    s.supplier_name,
    s.country,
    a.po_lines,
    a.received_po_lines,
    CAST(a.on_time_received_lines * 1.0
         / NULLIF(a.received_po_lines, 0) AS DECIMAL(12,6))
        AS supplier_timeliness_proxy_rate,
    CAST(p.median_lead_time_days AS DECIMAL(18,4)) AS median_actual_lead_time_days,
    CAST(p.p90_lead_time_days AS DECIMAL(18,4)) AS p90_actual_lead_time_days,
    CAST(p.p90_late_receipt_days AS DECIMAL(18,4)) AS p90_late_receipt_days,
    a.merchandise_cost_vnd,
    a.freight_cost_vnd,
    a.customs_cost_vnd,
    a.expedite_cost_vnd,
    a.quality_cost_vnd,
    a.landed_cost_vnd,
    a.estimated_holding_cost_vnd,
    a.estimated_tco_vnd,
    a.tco_available_lines
FROM Agg a
LEFT JOIN Pct p
    ON a.supplier_key = p.supplier_key
LEFT JOIN gold.dim_supplier s
    ON a.supplier_key = s.supplier_key
ORDER BY a.received_po_lines DESC, a.estimated_tco_vnd DESC;

-- Cost composition by supplier
SELECT
    m.supplier_key,
    s.supplier_name,
    SUM(m.landed_cost_vnd) AS landed_cost_vnd,
    SUM(m.estimated_holding_cost_vnd) AS estimated_holding_cost_vnd,
    SUM(m.estimated_tco_vnd) AS estimated_tco_vnd,
    SUM(m.expedite_cost_vnd) AS expedite_cost_vnd,
    SUM(m.quality_cost_vnd) AS quality_cost_vnd
FROM gold.mart_supplier_performance m
LEFT JOIN gold.dim_supplier s
    ON m.supplier_key = s.supplier_key
GROUP BY m.supplier_key, s.supplier_name
ORDER BY estimated_tco_vnd DESC;
GO

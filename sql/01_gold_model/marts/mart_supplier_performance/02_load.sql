USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.mart_supplier_performance

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
/* annual_holding_rate_pct is allowed either as decimal fraction
   (example 0.20) or percentage points (example 20).
   Values outside 0-100 are rejected. */
IF EXISTS
(
    SELECT 1
    FROM silver.inventory_policy_history
    WHERE annual_holding_rate_pct < 0
       OR annual_holding_rate_pct > 100
)
    THROW 62101, 'annual_holding_rate_pct is outside expected 0-100 range.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.mart_supplier_performance;

;WITH QAAgg AS
(
    SELECT
        purchase_order_line_id,
        COUNT(*) AS quality_event_count,
        SUM(defect_qty) AS defect_qty,
        SUM(estimated_quality_cost_vnd) AS quality_cost_vnd
    FROM silver.qa_events
    GROUP BY purchase_order_line_id
)
INSERT INTO gold.mart_supplier_performance
(
    purchase_order_line_id,
    purchase_order_id,
    supplier_key,
    product_key,
    po_date,
    expected_receipt_date,
    actual_receipt_date,
    received_flag,
    on_time_receipt_flag,
    supplier_otif_proxy_flag,
    supplier_otif_scope_note,
    actual_lead_time_days,
    late_receipt_days,
    contract_lead_time_days,
    quantity_ordered,
    merchandise_cost_vnd,
    freight_cost_vnd,
    customs_cost_vnd,
    expedite_cost_vnd,
    quality_cost_vnd,
    quality_event_count,
    defect_qty,
    landed_cost_vnd,
    avg_inventory_value_vnd,
    annual_holding_rate_raw,
    annual_holding_rate_decimal,
    holding_days,
    estimated_holding_cost_vnd,
    estimated_tco_vnd
)
SELECT
    l.purchase_order_line_id,
    l.purchase_order_id,
    h.supplier_key,
    l.product_key,
    h.po_date,
    h.expected_receipt_date,
    h.actual_receipt_date,

    CASE WHEN h.actual_receipt_date IS NOT NULL THEN 1 ELSE 0 END AS received_flag,

    CASE
        WHEN h.actual_receipt_date IS NULL THEN NULL
        WHEN h.actual_receipt_date <= h.expected_receipt_date THEN 1
        ELSE 0
    END AS on_time_receipt_flag,

    /* Full receipt quantity evidence is not present in the current source.
       Therefore this is intentionally marked as an OTIF proxy that measures
       receipt timeliness only. */
    CASE
        WHEN h.actual_receipt_date IS NULL THEN NULL
        WHEN h.actual_receipt_date <= h.expected_receipt_date THEN 1
        ELSE 0
    END AS supplier_otif_proxy_flag,

    'Proxy only: receipt timeliness; source does not contain quantity-received evidence for true In-Full test'
        AS supplier_otif_scope_note,

    CASE
        WHEN h.actual_receipt_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY, h.po_date, h.actual_receipt_date)
    END AS actual_lead_time_days,

    CASE
        WHEN h.actual_receipt_date IS NULL THEN NULL
        WHEN h.actual_receipt_date <= h.expected_receipt_date THEN 0
        ELSE DATEDIFF(DAY, h.expected_receipt_date, h.actual_receipt_date)
    END AS late_receipt_days,

    l.contract_lead_time_days,
    l.quantity_ordered,
    l.merchandise_value_vnd,
    l.freight_cost_vnd,
    l.customs_cost_vnd,
    l.expedite_cost_vnd,
    COALESCE(q.quality_cost_vnd, 0),
    COALESCE(q.quality_event_count, 0),
    COALESCE(q.defect_qty, 0),

    l.merchandise_value_vnd
    + l.freight_cost_vnd
    + l.customs_cost_vnd
    + l.expedite_cost_vnd
    + COALESCE(q.quality_cost_vnd, 0) AS landed_cost_vnd,

    inv.avg_inventory_value_vnd,
    pol.annual_holding_rate_pct AS annual_holding_rate_raw,

    CASE
        WHEN pol.annual_holding_rate_pct IS NULL THEN NULL
        WHEN pol.annual_holding_rate_pct > 1
            THEN pol.annual_holding_rate_pct / 100.0
        ELSE pol.annual_holding_rate_pct
    END AS annual_holding_rate_decimal,

    CASE
        WHEN h.actual_receipt_date IS NOT NULL
            THEN DATEDIFF(DAY, h.po_date, h.actual_receipt_date)
        ELSE l.contract_lead_time_days
    END AS holding_days,

    CASE
        WHEN inv.avg_inventory_value_vnd IS NULL
          OR pol.annual_holding_rate_pct IS NULL
            THEN NULL
        ELSE
            inv.avg_inventory_value_vnd
            * CASE
                WHEN pol.annual_holding_rate_pct > 1
                    THEN pol.annual_holding_rate_pct / 100.0
                ELSE pol.annual_holding_rate_pct
              END
            * CASE
                WHEN h.actual_receipt_date IS NOT NULL
                    THEN DATEDIFF(DAY, h.po_date, h.actual_receipt_date)
                ELSE l.contract_lead_time_days
              END
            / 365.0
    END AS estimated_holding_cost_vnd,

    CASE
        WHEN inv.avg_inventory_value_vnd IS NULL
          OR pol.annual_holding_rate_pct IS NULL
            THEN NULL
        ELSE
            (
                l.merchandise_value_vnd
                + l.freight_cost_vnd
                + l.customs_cost_vnd
                + l.expedite_cost_vnd
                + COALESCE(q.quality_cost_vnd, 0)
            )
            +
            (
                inv.avg_inventory_value_vnd
                * CASE
                    WHEN pol.annual_holding_rate_pct > 1
                        THEN pol.annual_holding_rate_pct / 100.0
                    ELSE pol.annual_holding_rate_pct
                  END
                * CASE
                    WHEN h.actual_receipt_date IS NOT NULL
                        THEN DATEDIFF(DAY, h.po_date, h.actual_receipt_date)
                    ELSE l.contract_lead_time_days
                  END
                / 365.0
            )
    END AS estimated_tco_vnd

FROM gold.fact_purchase_order_line l
INNER JOIN gold.fact_purchase_order h
    ON l.purchase_order_id = h.purchase_order_id
INNER JOIN gold.dim_product dp
    ON l.product_key = dp.product_key

LEFT JOIN QAAgg q
    ON l.purchase_order_line_id = q.purchase_order_line_id

OUTER APPLY
(
    SELECT TOP (1)
        iph.annual_holding_rate_pct
    FROM silver.inventory_policy_history iph
    WHERE iph.product_id = dp.product_id
      AND iph.effective_from <= h.po_date
      AND (iph.effective_to IS NULL OR iph.effective_to >= h.po_date)
    ORDER BY iph.effective_from DESC
) pol

OUTER APPLY
(
    SELECT
        AVG(CAST(day_inv.daily_inventory_value_vnd AS DECIMAL(18,2)))
            AS avg_inventory_value_vnd
    FROM
    (
        SELECT
            s.snapshot_date,
            SUM(s.inventory_value_vnd) AS daily_inventory_value_vnd
        FROM silver.inventory_daily_snapshot s
        WHERE s.product_id = dp.product_id
          AND s.snapshot_date >= h.po_date
          AND s.snapshot_date <=
              CASE
                  WHEN h.actual_receipt_date IS NOT NULL
                      THEN h.actual_receipt_date
                  ELSE DATEADD(DAY, l.contract_lead_time_days, h.po_date)
              END
        GROUP BY s.snapshot_date
    ) day_inv
) inv;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.mart_supplier_performance completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

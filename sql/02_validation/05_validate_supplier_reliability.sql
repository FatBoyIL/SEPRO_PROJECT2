USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - SUPPLIER RELIABILITY

   Current source supports receipt timeliness.
   supplier_otif_proxy_flag is NOT true quantity-based OTIF.
   ============================================================ */

SELECT
    supplier_key,
    COUNT(*) AS po_lines,
    SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END) AS received_po_lines,

    CAST
    (
        SUM
        (
            CASE
                WHEN received_flag = 1
                THEN CAST(supplier_otif_proxy_flag AS INT)
                ELSE 0
            END
        ) * 1.0
        / NULLIF(SUM(CASE WHEN received_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(12,6)
    ) AS supplier_otif_proxy_rate,

    AVG
    (
        CASE
            WHEN received_flag = 1
            THEN CAST(actual_lead_time_days AS DECIMAL(18,4))
        END
    ) AS avg_actual_lead_time_days,

    AVG
    (
        CASE
            WHEN received_flag = 1
            THEN CAST(late_receipt_days AS DECIMAL(18,4))
        END
    ) AS avg_late_receipt_days

FROM gold.mart_supplier_performance
GROUP BY supplier_key
ORDER BY supplier_key;
GO

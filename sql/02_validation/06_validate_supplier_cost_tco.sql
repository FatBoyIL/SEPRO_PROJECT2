USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 KPI - SUPPLIER COST / TCO

   Landed Cost:
   Merchandise + Freight + Customs + Expedite + Quality Cost

   Estimated TCO:
   Landed Cost + Estimated Holding Cost
   ============================================================ */

SELECT
    supplier_key,
    SUM(merchandise_cost_vnd) AS merchandise_cost_vnd,
    SUM(freight_cost_vnd) AS freight_cost_vnd,
    SUM(customs_cost_vnd) AS customs_cost_vnd,
    SUM(expedite_cost_vnd) AS expedite_cost_vnd,
    SUM(quality_cost_vnd) AS quality_cost_vnd,
    SUM(landed_cost_vnd) AS landed_cost_vnd,
    SUM(estimated_holding_cost_vnd) AS estimated_holding_cost_vnd,
    SUM(estimated_tco_vnd) AS estimated_tco_vnd
FROM gold.mart_supplier_performance
GROUP BY supplier_key
ORDER BY supplier_key;
GO

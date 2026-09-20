USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.mart_inventory_risk

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
DECLARE @DemandWindowDays INT = 60;
DECLARE @AnalysisCutoff DATE =
    (SELECT MAX(d.[date])
     FROM gold.fact_inventory_snapshot f
     INNER JOIN gold.dim_date d
         ON f.snapshot_date_key = d.date_key);

IF @AnalysisCutoff IS NULL
    THROW 62081, 'Inventory snapshot is empty; cannot build inventory risk mart.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.mart_inventory_risk;

DECLARE @DemandWindowDays INT = 60;
DECLARE @AnalysisCutoff DATE =
    (SELECT MAX(d.[date])
     FROM gold.fact_inventory_snapshot f
     INNER JOIN gold.dim_date d
         ON f.snapshot_date_key = d.date_key);

;WITH SnapshotBase AS
(
    SELECT
        d.[date] AS snapshot_date,
        DATEFROMPARTS(YEAR(d.[date]), MONTH(d.[date]), 1) AS month_start_date,
        f.product_key,
        f.warehouse_key,
        f.on_hand_qty,
        f.available_qty,
        f.inventory_value_vnd,
        f.stockout_flag
    FROM gold.fact_inventory_snapshot f
    INNER JOIN gold.dim_date d
        ON f.snapshot_date_key = d.date_key
),
StockoutStats AS
(
    SELECT
        month_start_date,
        product_key,
        COUNT(*) AS observed_sku_warehouse_days,
        SUM(CASE WHEN stockout_flag = 1 THEN 1 ELSE 0 END) AS stockout_sku_warehouse_days
    FROM SnapshotBase
    GROUP BY month_start_date, product_key
),
DailyNetwork AS
(
    SELECT
        snapshot_date,
        month_start_date,
        product_key,
        SUM(on_hand_qty) AS network_on_hand_qty,
        SUM(available_qty) AS network_available_qty,
        SUM(inventory_value_vnd) AS network_inventory_value_vnd
    FROM SnapshotBase
    GROUP BY snapshot_date, month_start_date, product_key
),
MonthlyNetwork AS
(
    SELECT
        month_start_date,
        product_key,
        AVG(CAST(network_on_hand_qty AS DECIMAL(18,4))) AS avg_network_on_hand_qty,
        AVG(CAST(network_available_qty AS DECIMAL(18,4))) AS avg_network_available_qty,
        AVG(CAST(network_inventory_value_vnd AS DECIMAL(18,2))) AS avg_network_inventory_value_vnd
    FROM DailyNetwork
    GROUP BY month_start_date, product_key
),
FulfillmentMonthly AS
(
    SELECT
        DATEFROMPARTS(YEAR(f.promised_delivery_date), MONTH(f.promised_delivery_date), 1) AS month_start_date,
        f.product_key,
        COUNT(*) AS eligible_fulfillment_line_count,
        SUM
        (
            CASE
                WHEN f.line_complete_flag = 0 THEN 1
                WHEN f.line_on_time_flag = 0 THEN 1
                ELSE 0
            END
        ) AS late_or_incomplete_line_count
    FROM gold.fact_fulfillment f
    WHERE f.promised_delivery_date <= @AnalysisCutoff
    GROUP BY
        DATEFROMPARTS(YEAR(f.promised_delivery_date), MONTH(f.promised_delivery_date), 1),
        f.product_key
)
INSERT INTO gold.mart_inventory_risk
(
    month_start_date,
    product_key,
    observed_sku_warehouse_days,
    stockout_sku_warehouse_days,
    stockout_rate,
    avg_network_on_hand_qty,
    avg_network_available_qty,
    avg_network_inventory_value_vnd,
    demand_window_days,
    avg_daily_demand_60d,
    inventory_coverage_days,
    eligible_fulfillment_line_count,
    late_or_incomplete_line_count,
    fulfillment_risk_rate
)
SELECT
    s.month_start_date,
    s.product_key,
    s.observed_sku_warehouse_days,
    s.stockout_sku_warehouse_days,

    CAST(s.stockout_sku_warehouse_days * 1.0
         / NULLIF(s.observed_sku_warehouse_days, 0) AS DECIMAL(12,6)) AS stockout_rate,

    n.avg_network_on_hand_qty,
    n.avg_network_available_qty,
    n.avg_network_inventory_value_vnd,

    @DemandWindowDays,

    CAST(COALESCE(demand.demand_qty_60d, 0) * 1.0
         / @DemandWindowDays AS DECIMAL(18,4)) AS avg_daily_demand_60d,

    CAST
    (
        n.avg_network_on_hand_qty
        / NULLIF(COALESCE(demand.demand_qty_60d, 0) * 1.0 / @DemandWindowDays, 0)
        AS DECIMAL(18,4)
    ) AS inventory_coverage_days,

    COALESCE(fm.eligible_fulfillment_line_count, 0),
    COALESCE(fm.late_or_incomplete_line_count, 0),

    CAST
    (
        COALESCE(fm.late_or_incomplete_line_count, 0) * 1.0
        / NULLIF(COALESCE(fm.eligible_fulfillment_line_count, 0), 0)
        AS DECIMAL(12,6)
    ) AS fulfillment_risk_rate

FROM StockoutStats s
INNER JOIN MonthlyNetwork n
    ON s.month_start_date = n.month_start_date
   AND s.product_key = n.product_key

INNER JOIN gold.dim_product p
    ON s.product_key = p.product_key

OUTER APPLY
(
    SELECT
        SUM(ol.quantity_ordered) AS demand_qty_60d
    FROM silver.sales_order_lines ol
    INNER JOIN silver.sales_orders o
        ON ol.sales_order_id = o.sales_order_id
    WHERE ol.product_id = p.product_id
      AND o.order_date >= DATEADD(DAY, 1 - @DemandWindowDays, EOMONTH(s.month_start_date))
      AND o.order_date <= EOMONTH(s.month_start_date)
) demand

LEFT JOIN FulfillmentMonthly fm
    ON s.month_start_date = fm.month_start_date
   AND s.product_key = fm.product_key;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.mart_inventory_risk completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

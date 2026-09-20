USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_inventory_snapshot

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT snapshot_date, product_id, warehouse_id
    FROM silver.inventory_daily_snapshot
    GROUP BY snapshot_date, product_id, warehouse_id
    HAVING COUNT(*) > 1
)
    THROW 62011, 'Duplicate inventory snapshot grain found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.inventory_daily_snapshot s
    LEFT JOIN gold.dim_date d
        ON s.snapshot_date = d.[date]
    LEFT JOIN gold.dim_product p
        ON s.product_id = p.product_id
    LEFT JOIN gold.dim_warehouse w
        ON s.warehouse_id = w.warehouse_id
    WHERE d.date_key IS NULL
       OR p.product_key IS NULL
       OR w.warehouse_key IS NULL
)
    THROW 62012, 'Inventory snapshot contains unmapped Date/Product/Warehouse keys.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_inventory_snapshot;

INSERT INTO gold.fact_inventory_snapshot
(
    snapshot_date_key,
    product_key,
    warehouse_key,
    on_hand_qty,
    on_order_qty,
    backlog_qty,
    available_qty,
    unit_cost_vnd,
    inventory_value_vnd,
    stockout_flag,
    reorder_point_qty,
    safety_stock_qty
)
SELECT
    d.date_key,
    p.product_key,
    w.warehouse_key,
    s.on_hand_qty,
    s.on_order_qty,
    s.backlog_qty,
    s.available_qty,
    s.unit_cost_vnd,
    s.inventory_value_vnd,
    s.stockout_flag,
    s.reorder_point_qty,
    s.safety_stock_qty
FROM silver.inventory_daily_snapshot s
INNER JOIN gold.dim_date d
    ON s.snapshot_date = d.[date]
INNER JOIN gold.dim_product p
    ON s.product_id = p.product_id
INNER JOIN gold.dim_warehouse w
    ON s.warehouse_id = w.warehouse_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_inventory_snapshot completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

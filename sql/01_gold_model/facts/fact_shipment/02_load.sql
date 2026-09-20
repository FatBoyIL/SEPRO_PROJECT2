USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_shipment

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT shipment_id
    FROM silver.shipments
    GROUP BY shipment_id
    HAVING COUNT(*) > 1
)
    THROW 62051, 'Duplicate shipment_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.shipments s
    LEFT JOIN gold.dim_warehouse w
        ON s.warehouse_id = w.warehouse_id
    LEFT JOIN gold.dim_date ds
        ON s.ship_date = ds.[date]
    LEFT JOIN gold.dim_date dd
        ON s.actual_delivery_date = dd.[date]
    WHERE w.warehouse_key IS NULL
       OR ds.date_key IS NULL
       OR dd.date_key IS NULL
)
    THROW 62052, 'Shipment contains unmapped Warehouse/Date keys.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.shipments
    WHERE actual_delivery_date < ship_date
)
    THROW 62053, 'Shipment has actual_delivery_date before ship_date.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_shipment;

INSERT INTO gold.fact_shipment
(
    shipment_id,
    sales_order_id,
    warehouse_key,
    ship_date_key,
    actual_delivery_date_key,
    ship_date,
    actual_delivery_date,
    shipping_method,
    freight_cost_vnd,
    shipment_status,
    partial_shipment_flag,
    tracking_no
)
SELECT
    s.shipment_id,
    s.sales_order_id,
    w.warehouse_key,
    ds.date_key,
    dd.date_key,
    s.ship_date,
    s.actual_delivery_date,
    s.shipping_method,
    s.freight_cost_vnd,
    s.shipment_status,
    s.partial_shipment_flag,
    s.tracking_no
FROM silver.shipments s
INNER JOIN gold.dim_warehouse w
    ON s.warehouse_id = w.warehouse_id
INNER JOIN gold.dim_date ds
    ON s.ship_date = ds.[date]
INNER JOIN gold.dim_date dd
    ON s.actual_delivery_date = dd.[date];


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_shipment completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

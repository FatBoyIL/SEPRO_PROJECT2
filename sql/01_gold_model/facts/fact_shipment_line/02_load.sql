USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_shipment_line

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT shipment_line_id
    FROM silver.shipment_lines
    GROUP BY shipment_line_id
    HAVING COUNT(*) > 1
)
    THROW 62061, 'Duplicate shipment_line_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.shipment_lines s
    LEFT JOIN gold.dim_product p
        ON s.product_id = p.product_id
    WHERE p.product_key IS NULL
)
    THROW 62062, 'Shipment line contains unmapped product.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.shipment_lines l
    LEFT JOIN silver.shipments h
        ON l.shipment_id = h.shipment_id
    LEFT JOIN silver.sales_order_lines ol
        ON l.sales_order_line_id = ol.sales_order_line_id
    WHERE h.shipment_id IS NULL
       OR ol.sales_order_line_id IS NULL
)
    THROW 62063, 'Shipment line contains orphan shipment/order-line relationship.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_shipment_line;

INSERT INTO gold.fact_shipment_line
(
    shipment_line_id,
    shipment_id,
    sales_order_line_id,
    product_key,
    quantity_shipped
)
SELECT
    s.shipment_line_id,
    s.shipment_id,
    s.sales_order_line_id,
    p.product_key,
    s.quantity_shipped
FROM silver.shipment_lines s
INNER JOIN gold.dim_product p
    ON s.product_id = p.product_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_shipment_line completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

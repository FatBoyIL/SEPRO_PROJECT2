USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_inventory_movement

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT inventory_move_id
    FROM silver.inventory_movements
    GROUP BY inventory_move_id
    HAVING COUNT(*) > 1
)
    THROW 62021, 'Duplicate inventory_move_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.inventory_movements s
    LEFT JOIN gold.dim_date d
        ON s.movement_date = d.[date]
    LEFT JOIN gold.dim_product p
        ON s.product_id = p.product_id
    LEFT JOIN gold.dim_warehouse w
        ON s.warehouse_id = w.warehouse_id
    WHERE d.date_key IS NULL
       OR p.product_key IS NULL
       OR w.warehouse_key IS NULL
)
    THROW 62022, 'Inventory movement contains unmapped Date/Product/Warehouse keys.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_inventory_movement;

INSERT INTO gold.fact_inventory_movement
(
    inventory_move_id,
    movement_date_key,
    product_key,
    warehouse_key,
    movement_type,
    quantity_signed,
    unit_cost_vnd,
    reference_document,
    reference_line,
    batch_no,
    expiry_date
)
SELECT
    s.inventory_move_id,
    d.date_key,
    p.product_key,
    w.warehouse_key,
    s.movement_type,
    s.quantity_signed,
    s.unit_cost_vnd,
    s.reference_document,
    s.reference_line,
    s.batch_no,
    s.expiry_date
FROM silver.inventory_movements s
INNER JOIN gold.dim_date d
    ON s.movement_date = d.[date]
INNER JOIN gold.dim_product p
    ON s.product_id = p.product_id
INNER JOIN gold.dim_warehouse w
    ON s.warehouse_id = w.warehouse_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_inventory_movement completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

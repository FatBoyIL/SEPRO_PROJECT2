USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_inventory_movement
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_inventory_movement', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_inventory_movement
    (
        inventory_move_id   NVARCHAR(100)  NOT NULL,
        movement_date_key   INT            NOT NULL,
        product_key         INT            NOT NULL,
        warehouse_key       INT            NOT NULL,

        movement_type       NVARCHAR(100)  NOT NULL,
        quantity_signed     INT            NOT NULL,
        unit_cost_vnd       DECIMAL(18,2)  NOT NULL,
        reference_document  NVARCHAR(200)  NOT NULL,
        reference_line      NVARCHAR(100)  NULL,
        batch_no            NVARCHAR(100)  NULL,
        expiry_date         DATE           NULL,

        CONSTRAINT PK_fact_inventory_movement
            PRIMARY KEY (inventory_move_id),

        CONSTRAINT FK_fact_inventory_movement_date
            FOREIGN KEY (movement_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_inventory_movement_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key),

        CONSTRAINT FK_fact_inventory_movement_warehouse
            FOREIGN KEY (warehouse_key)
            REFERENCES gold.dim_warehouse(warehouse_key)
    );

    CREATE INDEX IX_fact_inventory_movement_product_date
        ON gold.fact_inventory_movement(product_key, movement_date_key);

    PRINT 'Created gold.fact_inventory_movement';
END
ELSE
    PRINT 'gold.fact_inventory_movement already exists.';


    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

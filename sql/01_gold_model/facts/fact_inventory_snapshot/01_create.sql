USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_inventory_snapshot
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_inventory_snapshot', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_inventory_snapshot
    (
        snapshot_date_key    INT            NOT NULL,
        product_key          INT            NOT NULL,
        warehouse_key        INT            NOT NULL,

        on_hand_qty          INT            NOT NULL,
        on_order_qty         INT            NOT NULL,
        backlog_qty          INT            NOT NULL,
        available_qty        INT            NOT NULL,
        unit_cost_vnd        DECIMAL(18,2)  NOT NULL,
        inventory_value_vnd  DECIMAL(18,2)  NOT NULL,
        stockout_flag        BIT            NOT NULL,
        reorder_point_qty    INT            NOT NULL,
        safety_stock_qty     INT            NOT NULL,

        CONSTRAINT PK_fact_inventory_snapshot
            PRIMARY KEY (snapshot_date_key, product_key, warehouse_key),

        CONSTRAINT FK_fact_inventory_snapshot_date
            FOREIGN KEY (snapshot_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_inventory_snapshot_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key),

        CONSTRAINT FK_fact_inventory_snapshot_warehouse
            FOREIGN KEY (warehouse_key)
            REFERENCES gold.dim_warehouse(warehouse_key)
    );

    CREATE INDEX IX_fact_inventory_snapshot_product_date
        ON gold.fact_inventory_snapshot(product_key, snapshot_date_key);

    PRINT 'Created gold.fact_inventory_snapshot';
END
ELSE
    PRINT 'gold.fact_inventory_snapshot already exists.';


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

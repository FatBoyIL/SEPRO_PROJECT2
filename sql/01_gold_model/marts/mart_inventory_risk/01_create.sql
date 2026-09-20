USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.mart_inventory_risk
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.mart_inventory_risk', 'U') IS NULL
BEGIN
    CREATE TABLE gold.mart_inventory_risk
    (
        month_start_date                  DATE           NOT NULL,
        product_key                       INT            NOT NULL,

        observed_sku_warehouse_days       INT            NOT NULL,
        stockout_sku_warehouse_days       INT            NOT NULL,
        stockout_rate                     DECIMAL(12,6)  NULL,

        avg_network_on_hand_qty           DECIMAL(18,4)  NULL,
        avg_network_available_qty         DECIMAL(18,4)  NULL,
        avg_network_inventory_value_vnd   DECIMAL(18,2)  NULL,

        demand_window_days                INT            NOT NULL,
        avg_daily_demand_60d              DECIMAL(18,4)  NULL,
        inventory_coverage_days           DECIMAL(18,4)  NULL,

        eligible_fulfillment_line_count   INT            NOT NULL,
        late_or_incomplete_line_count     INT            NOT NULL,
        fulfillment_risk_rate             DECIMAL(12,6)  NULL,

        CONSTRAINT PK_mart_inventory_risk
            PRIMARY KEY (month_start_date, product_key),

        CONSTRAINT FK_mart_inventory_risk_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key)
    );

    CREATE INDEX IX_mart_inventory_risk_product
        ON gold.mart_inventory_risk(product_key, month_start_date);

    PRINT 'Created gold.mart_inventory_risk';
END
ELSE
    PRINT 'gold.mart_inventory_risk already exists.';


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

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_shipment
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_shipment', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_shipment
    (
        shipment_id            NVARCHAR(100)  NOT NULL,
        sales_order_id         NVARCHAR(100)  NOT NULL,
        warehouse_key          INT            NOT NULL,
        ship_date_key          INT            NOT NULL,
        actual_delivery_date_key INT          NOT NULL,

        ship_date              DATE           NOT NULL,
        actual_delivery_date   DATE           NOT NULL,
        shipping_method        NVARCHAR(100)  NOT NULL,
        freight_cost_vnd       DECIMAL(18,2)  NOT NULL,
        shipment_status        NVARCHAR(100)  NOT NULL,
        partial_shipment_flag  BIT            NOT NULL,
        tracking_no            NVARCHAR(200)  NOT NULL,

        CONSTRAINT PK_fact_shipment
            PRIMARY KEY (shipment_id),

        CONSTRAINT FK_fact_shipment_warehouse
            FOREIGN KEY (warehouse_key)
            REFERENCES gold.dim_warehouse(warehouse_key),

        CONSTRAINT FK_fact_shipment_ship_date
            FOREIGN KEY (ship_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_shipment_delivery_date
            FOREIGN KEY (actual_delivery_date_key)
            REFERENCES gold.dim_date(date_key)
    );

    CREATE INDEX IX_fact_shipment_sales_order
        ON gold.fact_shipment(sales_order_id);

    PRINT 'Created gold.fact_shipment';
END
ELSE
    PRINT 'gold.fact_shipment already exists.';


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

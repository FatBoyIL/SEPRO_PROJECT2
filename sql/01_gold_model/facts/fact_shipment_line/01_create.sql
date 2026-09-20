USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_shipment_line
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_shipment_line', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_shipment_line
    (
        shipment_line_id       NVARCHAR(100) NOT NULL,
        shipment_id            NVARCHAR(100) NOT NULL,
        sales_order_line_id    NVARCHAR(100) NOT NULL,
        product_key            INT           NOT NULL,
        quantity_shipped       INT           NOT NULL,

        CONSTRAINT PK_fact_shipment_line
            PRIMARY KEY (shipment_line_id),

        CONSTRAINT FK_fact_shipment_line_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key)
    );

    CREATE INDEX IX_fact_shipment_line_shipment
        ON gold.fact_shipment_line(shipment_id);

    CREATE INDEX IX_fact_shipment_line_order_line
        ON gold.fact_shipment_line(sales_order_line_id);

    PRINT 'Created gold.fact_shipment_line';
END
ELSE
    PRINT 'gold.fact_shipment_line already exists.';


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

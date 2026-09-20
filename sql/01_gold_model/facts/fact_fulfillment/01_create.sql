USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_fulfillment
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_fulfillment', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_fulfillment
    (
        sales_order_line_id       NVARCHAR(100) NOT NULL,
        sales_order_id            NVARCHAR(100) NOT NULL,
        product_key               INT           NOT NULL,

        quantity_ordered          INT           NOT NULL,
        quantity_shipped_total    INT           NOT NULL,

        first_ship_date           DATE          NULL,
        last_delivery_date        DATE          NULL,
        completion_delivery_date  DATE          NULL,
        promised_delivery_date    DATE          NOT NULL,

        line_complete_flag        BIT           NOT NULL,
        line_on_time_flag         BIT           NULL,
        late_delivery_days        INT           NULL,

        CONSTRAINT PK_fact_fulfillment
            PRIMARY KEY (sales_order_line_id),

        CONSTRAINT FK_fact_fulfillment_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key)
    );

    CREATE INDEX IX_fact_fulfillment_order
        ON gold.fact_fulfillment(sales_order_id);

    CREATE INDEX IX_fact_fulfillment_product
        ON gold.fact_fulfillment(product_key);

    PRINT 'Created gold.fact_fulfillment';
END
ELSE
    PRINT 'gold.fact_fulfillment already exists.';


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

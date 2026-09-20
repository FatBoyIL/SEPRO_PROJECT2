USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.mart_order_availability_otif
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.mart_order_availability_otif', 'U') IS NULL
BEGIN
    CREATE TABLE gold.mart_order_availability_otif
    (
        sales_order_id              NVARCHAR(100)  NOT NULL,
        customer_key                INT            NOT NULL,
        order_date                  DATE           NOT NULL,
        requested_delivery_date     DATE           NOT NULL,

        order_line_count            INT            NOT NULL,
        missing_snapshot_line_count INT            NOT NULL,
        available_in_full_line_count INT           NOT NULL,
        partial_available_line_count INT           NOT NULL,
        no_stock_line_count         INT            NOT NULL,

        availability_group          NVARCHAR(50)   NOT NULL,
        availability_scope          NVARCHAR(200)  NOT NULL,

        order_quantity_ordered      INT            NOT NULL,
        order_quantity_shipped      INT            NOT NULL,

        delivered_flag              BIT            NOT NULL,
        complete_flag               BIT            NOT NULL,
        final_delivery_date         DATE           NULL,
        on_time_flag                BIT            NULL,
        otif_flag                   BIT            NOT NULL,
        days_late                   INT            NULL,

        CONSTRAINT PK_mart_order_availability_otif
            PRIMARY KEY (sales_order_id),

        CONSTRAINT FK_mart_order_availability_otif_customer
            FOREIGN KEY (customer_key)
            REFERENCES gold.dim_customer(customer_key)
    );

    CREATE INDEX IX_mart_order_availability_otif_date
        ON gold.mart_order_availability_otif(order_date);

    CREATE INDEX IX_mart_order_availability_otif_availability
        ON gold.mart_order_availability_otif(availability_group);

    PRINT 'Created gold.mart_order_availability_otif';
END
ELSE
    PRINT 'gold.mart_order_availability_otif already exists.';


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

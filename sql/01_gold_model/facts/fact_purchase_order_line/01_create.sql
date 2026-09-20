USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_purchase_order_line
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_purchase_order_line', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_purchase_order_line
    (
        purchase_order_line_id   NVARCHAR(100)  NOT NULL,
        purchase_order_id        NVARCHAR(100)  NOT NULL,
        product_key              INT            NOT NULL,

        quantity_ordered         INT            NOT NULL,
        unit_price_local         DECIMAL(18,4)  NOT NULL,
        currency                 NVARCHAR(20)   NOT NULL,
        fx_rate_to_vnd           DECIMAL(18,6)  NOT NULL,
        merchandise_value_vnd    DECIMAL(18,2)  NOT NULL,
        freight_cost_vnd         DECIMAL(18,2)  NOT NULL,
        customs_cost_vnd         DECIMAL(18,2)  NOT NULL,
        expedite_cost_vnd        DECIMAL(18,2)  NOT NULL,
        supplier_role            NVARCHAR(100)  NOT NULL,
        contract_lead_time_days  INT            NOT NULL,

        CONSTRAINT PK_fact_purchase_order_line
            PRIMARY KEY (purchase_order_line_id),

        CONSTRAINT FK_fact_purchase_order_line_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key)
    );

    CREATE INDEX IX_fact_purchase_order_line_po
        ON gold.fact_purchase_order_line(purchase_order_id);

    CREATE INDEX IX_fact_purchase_order_line_product
        ON gold.fact_purchase_order_line(product_key);

    PRINT 'Created gold.fact_purchase_order_line';
END
ELSE
    PRINT 'gold.fact_purchase_order_line already exists.';


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

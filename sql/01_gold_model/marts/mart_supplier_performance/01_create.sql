USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.mart_supplier_performance
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.mart_supplier_performance', 'U') IS NULL
BEGIN
    CREATE TABLE gold.mart_supplier_performance
    (
        purchase_order_line_id        NVARCHAR(100)  NOT NULL,
        purchase_order_id             NVARCHAR(100)  NOT NULL,
        supplier_key                  INT            NOT NULL,
        product_key                   INT            NOT NULL,

        po_date                       DATE           NOT NULL,
        expected_receipt_date         DATE           NOT NULL,
        actual_receipt_date           DATE           NULL,

        received_flag                 BIT            NOT NULL,
        on_time_receipt_flag          BIT            NULL,
        supplier_otif_proxy_flag      BIT            NULL,
        supplier_otif_scope_note      NVARCHAR(250)  NOT NULL,

        actual_lead_time_days         INT            NULL,
        late_receipt_days             INT            NULL,
        contract_lead_time_days       INT            NOT NULL,

        quantity_ordered              INT            NOT NULL,
        merchandise_cost_vnd          DECIMAL(18,2)  NOT NULL,
        freight_cost_vnd              DECIMAL(18,2)  NOT NULL,
        customs_cost_vnd              DECIMAL(18,2)  NOT NULL,
        expedite_cost_vnd             DECIMAL(18,2)  NOT NULL,
        quality_cost_vnd              DECIMAL(18,2)  NOT NULL,
        quality_event_count           INT            NOT NULL,
        defect_qty                    INT            NOT NULL,

        landed_cost_vnd               DECIMAL(18,2)  NOT NULL,

        avg_inventory_value_vnd       DECIMAL(18,2)  NULL,
        annual_holding_rate_raw       DECIMAL(18,6)  NULL,
        annual_holding_rate_decimal   DECIMAL(18,6)  NULL,
        holding_days                  INT            NULL,
        estimated_holding_cost_vnd    DECIMAL(18,2)  NULL,
        estimated_tco_vnd             DECIMAL(18,2)  NULL,

        CONSTRAINT PK_mart_supplier_performance
            PRIMARY KEY (purchase_order_line_id),

        CONSTRAINT FK_mart_supplier_performance_supplier
            FOREIGN KEY (supplier_key)
            REFERENCES gold.dim_supplier(supplier_key),

        CONSTRAINT FK_mart_supplier_performance_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key)
    );

    CREATE INDEX IX_mart_supplier_performance_supplier
        ON gold.mart_supplier_performance(supplier_key, po_date);

    PRINT 'Created gold.mart_supplier_performance';
END
ELSE
    PRINT 'gold.mart_supplier_performance already exists.';


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

USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   CREATE gold.fact_purchase_order
   ============================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

IF OBJECT_ID('gold.fact_purchase_order', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_purchase_order
    (
        purchase_order_id          NVARCHAR(100)  NOT NULL,
        supplier_key               INT            NOT NULL,
        buyer_employee_key         INT            NOT NULL,
        po_date_key                INT            NOT NULL,
        expected_receipt_date_key  INT            NOT NULL,
        actual_receipt_date_key    INT            NULL,

        po_date                    DATE           NOT NULL,
        expected_receipt_date      DATE           NOT NULL,
        actual_receipt_date        DATE           NULL,
        currency                   NVARCHAR(20)   NOT NULL,
        fx_rate_to_vnd             DECIMAL(18,6)  NOT NULL,
        payment_term               NVARCHAR(100)  NOT NULL,
        incoterm                   NVARCHAR(50)   NOT NULL,
        po_status                  NVARCHAR(100)  NOT NULL,

        CONSTRAINT PK_fact_purchase_order
            PRIMARY KEY (purchase_order_id),

        CONSTRAINT FK_fact_purchase_order_supplier
            FOREIGN KEY (supplier_key)
            REFERENCES gold.dim_supplier(supplier_key),

        CONSTRAINT FK_fact_purchase_order_buyer
            FOREIGN KEY (buyer_employee_key)
            REFERENCES gold.dim_employee(employee_key),

        CONSTRAINT FK_fact_purchase_order_po_date
            FOREIGN KEY (po_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_purchase_order_expected_date
            FOREIGN KEY (expected_receipt_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_purchase_order_actual_date
            FOREIGN KEY (actual_receipt_date_key)
            REFERENCES gold.dim_date(date_key)
    );

    CREATE INDEX IX_fact_purchase_order_supplier_date
        ON gold.fact_purchase_order(supplier_key, po_date_key);

    PRINT 'Created gold.fact_purchase_order';
END
ELSE
    PRINT 'gold.fact_purchase_order already exists.';


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

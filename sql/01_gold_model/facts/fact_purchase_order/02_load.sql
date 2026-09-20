USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_purchase_order

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT purchase_order_id
    FROM silver.purchase_orders
    GROUP BY purchase_order_id
    HAVING COUNT(*) > 1
)
    THROW 62031, 'Duplicate purchase_order_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.purchase_orders s
    LEFT JOIN gold.dim_supplier sup
        ON s.supplier_id = sup.supplier_id
    LEFT JOIN gold.dim_employee emp
        ON s.buyer_id = emp.employee_id
    LEFT JOIN gold.dim_date dpo
        ON s.po_date = dpo.[date]
    LEFT JOIN gold.dim_date dexp
        ON s.expected_receipt_date = dexp.[date]
    LEFT JOIN gold.dim_date dact
        ON s.actual_receipt_date = dact.[date]
    WHERE sup.supplier_key IS NULL
       OR emp.employee_key IS NULL
       OR dpo.date_key IS NULL
       OR dexp.date_key IS NULL
       OR (s.actual_receipt_date IS NOT NULL AND dact.date_key IS NULL)
)
    THROW 62032, 'Purchase order contains unmapped dimension keys.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.purchase_orders
    WHERE actual_receipt_date IS NOT NULL
      AND actual_receipt_date < po_date
)
    THROW 62033, 'Purchase order has actual_receipt_date before po_date.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_purchase_order;

INSERT INTO gold.fact_purchase_order
(
    purchase_order_id,
    supplier_key,
    buyer_employee_key,
    po_date_key,
    expected_receipt_date_key,
    actual_receipt_date_key,
    po_date,
    expected_receipt_date,
    actual_receipt_date,
    currency,
    fx_rate_to_vnd,
    payment_term,
    incoterm,
    po_status
)
SELECT
    s.purchase_order_id,
    sup.supplier_key,
    emp.employee_key,
    dpo.date_key,
    dexp.date_key,
    dact.date_key,
    s.po_date,
    s.expected_receipt_date,
    s.actual_receipt_date,
    s.currency,
    s.fx_rate_to_vnd,
    s.payment_term,
    s.incoterm,
    s.po_status
FROM silver.purchase_orders s
INNER JOIN gold.dim_supplier sup
    ON s.supplier_id = sup.supplier_id
INNER JOIN gold.dim_employee emp
    ON s.buyer_id = emp.employee_id
INNER JOIN gold.dim_date dpo
    ON s.po_date = dpo.[date]
INNER JOIN gold.dim_date dexp
    ON s.expected_receipt_date = dexp.[date]
LEFT JOIN gold.dim_date dact
    ON s.actual_receipt_date = dact.[date];


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_purchase_order completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

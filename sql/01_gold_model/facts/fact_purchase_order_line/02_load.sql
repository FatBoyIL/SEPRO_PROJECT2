USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_purchase_order_line

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT purchase_order_line_id
    FROM silver.purchase_order_lines
    GROUP BY purchase_order_line_id
    HAVING COUNT(*) > 1
)
    THROW 62041, 'Duplicate purchase_order_line_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.purchase_order_lines s
    LEFT JOIN gold.dim_product p
        ON s.product_id = p.product_id
    WHERE p.product_key IS NULL
)
    THROW 62042, 'Purchase order line contains unmapped product.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.purchase_order_lines l
    LEFT JOIN silver.purchase_orders h
        ON l.purchase_order_id = h.purchase_order_id
    WHERE h.purchase_order_id IS NULL
)
    THROW 62043, 'Purchase order line has orphan purchase_order_id.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_purchase_order_line;

INSERT INTO gold.fact_purchase_order_line
(
    purchase_order_line_id,
    purchase_order_id,
    product_key,
    quantity_ordered,
    unit_price_local,
    currency,
    fx_rate_to_vnd,
    merchandise_value_vnd,
    freight_cost_vnd,
    customs_cost_vnd,
    expedite_cost_vnd,
    supplier_role,
    contract_lead_time_days
)
SELECT
    s.purchase_order_line_id,
    s.purchase_order_id,
    p.product_key,
    s.quantity_ordered,
    s.unit_price_local,
    s.currency,
    s.fx_rate_to_vnd,
    s.merchandise_value_vnd,
    s.freight_cost_vnd,
    s.customs_cost_vnd,
    s.expedite_cost_vnd,
    s.supplier_role,
    s.contract_lead_time_days
FROM silver.purchase_order_lines s
INNER JOIN gold.dim_product p
    ON s.product_id = p.product_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_purchase_order_line completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

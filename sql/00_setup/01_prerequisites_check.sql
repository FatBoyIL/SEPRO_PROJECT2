USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
GO

/* ============================================================
   PROJECT 2 - PREREQUISITES CHECK
   Inventory & Order Fulfillment Analytics

   Run this before creating Project 2 Gold objects.
   It does not modify data.
   ============================================================ */

DECLARE @RequiredObjects TABLE
(
    object_name SYSNAME NOT NULL,
    object_type VARCHAR(20) NOT NULL
);

INSERT INTO @RequiredObjects (object_name, object_type)
VALUES
    ('silver.inventory_daily_snapshot', 'U'),
    ('silver.inventory_movements',      'U'),
    ('silver.purchase_orders',          'U'),
    ('silver.purchase_order_lines',     'U'),
    ('silver.shipments',                'U'),
    ('silver.shipment_lines',           'U'),
    ('silver.sales_orders',             'U'),
    ('silver.sales_order_lines',        'U'),
    ('silver.qa_events',                'U'),
    ('silver.inventory_policy_history', 'U'),
    ('silver.products',                 'U'),
    ('silver.suppliers',                'U'),
    ('silver.warehouses',               'U'),
    ('gold.dim_date',                   'U'),
    ('gold.dim_product',                'U'),
    ('gold.dim_supplier',               'U'),
    ('gold.dim_warehouse',              'U'),
    ('gold.dim_employee',               'U'),
    ('gold.dim_customer',               'U');

SELECT
    r.object_name,
    CASE
        WHEN OBJECT_ID(r.object_name, r.object_type) IS NOT NULL THEN 'PASS'
        ELSE 'MISSING'
    END AS check_status
FROM @RequiredObjects r
ORDER BY r.object_name;

IF EXISTS
(
    SELECT 1
    FROM @RequiredObjects r
    WHERE OBJECT_ID(r.object_name, r.object_type) IS NULL
)
BEGIN
    THROW 62000, 'Project 2 prerequisites are incomplete. Review MISSING objects above.', 1;
END;

PRINT 'Project 2 prerequisites check passed.';
GO

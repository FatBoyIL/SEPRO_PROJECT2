USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.mart_order_availability_otif

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT sales_order_id
    FROM silver.sales_orders
    GROUP BY sales_order_id
    HAVING COUNT(*) > 1
)
    THROW 62091, 'Duplicate sales_order_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.sales_orders o
    LEFT JOIN gold.dim_customer c
        ON o.customer_id = c.customer_id
    WHERE c.customer_key IS NULL
)
    THROW 62092, 'Sales order contains unmapped customer.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.mart_order_availability_otif;

;WITH InventoryAtOrder AS
(
    /* Warehouse allocation is not available at order time.
       Therefore availability is evaluated at NETWORK level:
       sum available_qty across all warehouses for product/date. */
    SELECT
        d.[date] AS snapshot_date,
        p.product_id,
        SUM(f.available_qty) AS network_available_qty
    FROM gold.fact_inventory_snapshot f
    INNER JOIN gold.dim_date d
        ON f.snapshot_date_key = d.date_key
    INNER JOIN gold.dim_product p
        ON f.product_key = p.product_key
    GROUP BY d.[date], p.product_id
),
LineAvailability AS
(
    SELECT
        o.sales_order_id,
        ol.sales_order_line_id,
        ol.quantity_ordered,
        ia.network_available_qty,

        CASE
            WHEN ia.product_id IS NULL THEN 'Missing snapshot'
            WHEN ia.network_available_qty >= ol.quantity_ordered THEN 'Available in full'
            WHEN ia.network_available_qty > 0 THEN 'Partially available'
            ELSE 'No stock'
        END AS line_availability_group
    FROM silver.sales_orders o
    INNER JOIN silver.sales_order_lines ol
        ON o.sales_order_id = ol.sales_order_id
    LEFT JOIN InventoryAtOrder ia
        ON o.order_date = ia.snapshot_date
       AND ol.product_id = ia.product_id
),
AvailabilityByOrder AS
(
    SELECT
        sales_order_id,
        COUNT(*) AS order_line_count,
        SUM(CASE WHEN line_availability_group = 'Missing snapshot' THEN 1 ELSE 0 END) AS missing_snapshot_line_count,
        SUM(CASE WHEN line_availability_group = 'Available in full' THEN 1 ELSE 0 END) AS available_in_full_line_count,
        SUM(CASE WHEN line_availability_group = 'Partially available' THEN 1 ELSE 0 END) AS partial_available_line_count,
        SUM(CASE WHEN line_availability_group = 'No stock' THEN 1 ELSE 0 END) AS no_stock_line_count
    FROM LineAvailability
    GROUP BY sales_order_id
),
FulfillmentByOrder AS
(
    SELECT
        f.sales_order_id,
        SUM(f.quantity_ordered) AS order_quantity_ordered,
        SUM(f.quantity_shipped_total) AS order_quantity_shipped,
        MIN(CAST(f.line_complete_flag AS INT)) AS all_lines_complete,
        MAX(f.completion_delivery_date) AS final_delivery_date
    FROM gold.fact_fulfillment f
    GROUP BY f.sales_order_id
),
DeliveryByOrder AS
(
    SELECT
        sales_order_id,
        COUNT(*) AS shipment_count,
        MIN(actual_delivery_date) AS first_delivery_date,
        MAX(actual_delivery_date) AS last_delivery_date
    FROM gold.fact_shipment
    GROUP BY sales_order_id
)
INSERT INTO gold.mart_order_availability_otif
(
    sales_order_id,
    customer_key,
    order_date,
    requested_delivery_date,
    order_line_count,
    missing_snapshot_line_count,
    available_in_full_line_count,
    partial_available_line_count,
    no_stock_line_count,
    availability_group,
    availability_scope,
    order_quantity_ordered,
    order_quantity_shipped,
    delivered_flag,
    complete_flag,
    final_delivery_date,
    on_time_flag,
    otif_flag,
    days_late
)
SELECT
    o.sales_order_id,
    c.customer_key,
    o.order_date,
    o.requested_delivery_date,

    COALESCE(a.order_line_count, 0),
    COALESCE(a.missing_snapshot_line_count, 0),
    COALESCE(a.available_in_full_line_count, 0),
    COALESCE(a.partial_available_line_count, 0),
    COALESCE(a.no_stock_line_count, 0),

    CASE
        WHEN COALESCE(a.order_line_count, 0) = 0 THEN 'No order lines'
        WHEN a.missing_snapshot_line_count > 0 THEN 'Missing snapshot'
        WHEN a.no_stock_line_count > 0 THEN 'No stock'
        WHEN a.partial_available_line_count > 0 THEN 'Partially available'
        ELSE 'Available in full'
    END AS availability_group,

    'Network availability: sum available_qty across all warehouses on order date' AS availability_scope,

    COALESCE(f.order_quantity_ordered, 0),
    COALESCE(f.order_quantity_shipped, 0),

    CASE WHEN COALESCE(d.shipment_count, 0) > 0 THEN 1 ELSE 0 END AS delivered_flag,
    CASE WHEN COALESCE(f.all_lines_complete, 0) = 1 THEN 1 ELSE 0 END AS complete_flag,

    CASE
        WHEN COALESCE(f.all_lines_complete, 0) = 1 THEN f.final_delivery_date
        ELSE NULL
    END AS final_delivery_date,

    CASE
        WHEN COALESCE(f.all_lines_complete, 0) = 0 THEN NULL
        WHEN f.final_delivery_date <= o.requested_delivery_date THEN 1
        ELSE 0
    END AS on_time_flag,

    CASE
        WHEN COALESCE(d.shipment_count, 0) > 0
         AND COALESCE(f.all_lines_complete, 0) = 1
         AND f.final_delivery_date <= o.requested_delivery_date
        THEN 1 ELSE 0
    END AS otif_flag,

    CASE
        WHEN COALESCE(f.all_lines_complete, 0) = 0 THEN NULL
        WHEN f.final_delivery_date <= o.requested_delivery_date THEN 0
        ELSE DATEDIFF(DAY, o.requested_delivery_date, f.final_delivery_date)
    END AS days_late

FROM silver.sales_orders o
INNER JOIN gold.dim_customer c
    ON o.customer_id = c.customer_id
LEFT JOIN AvailabilityByOrder a
    ON o.sales_order_id = a.sales_order_id
LEFT JOIN FulfillmentByOrder f
    ON o.sales_order_id = f.sales_order_id
LEFT JOIN DeliveryByOrder d
    ON o.sales_order_id = d.sales_order_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.mart_order_availability_otif completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

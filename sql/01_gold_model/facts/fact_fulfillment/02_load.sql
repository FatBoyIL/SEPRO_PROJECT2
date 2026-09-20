USE [SEPRO_Master_Prod];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================
   LOAD gold.fact_fulfillment

   Load strategy:
   Full refresh of this Gold object inside one transaction.
   ============================================================ */

BEGIN TRY
IF EXISTS
(
    SELECT sales_order_line_id
    FROM silver.sales_order_lines
    GROUP BY sales_order_line_id
    HAVING COUNT(*) > 1
)
    THROW 62071, 'Duplicate sales_order_line_id found in Silver.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.sales_order_lines s
    LEFT JOIN gold.dim_product p
        ON s.product_id = p.product_id
    WHERE p.product_key IS NULL
)
    THROW 62072, 'Sales order line contains unmapped product.', 1;

IF EXISTS
(
    SELECT 1
    FROM silver.sales_order_lines
    WHERE quantity_ordered <= 0
)
    THROW 62073, 'Sales order line has non-positive quantity_ordered.', 1;


    BEGIN TRANSACTION;

DELETE FROM gold.fact_fulfillment;

;WITH ShipmentEvents AS
(
    SELECT
        sl.sales_order_line_id,
        sl.quantity_shipped,
        sh.shipment_id,
        sh.ship_date,
        sh.actual_delivery_date,

        SUM(sl.quantity_shipped) OVER
        (
            PARTITION BY sl.sales_order_line_id
            ORDER BY sh.actual_delivery_date, sh.shipment_id, sl.shipment_line_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_qty
    FROM gold.fact_shipment_line sl
    INNER JOIN gold.fact_shipment sh
        ON sl.shipment_id = sh.shipment_id
),
ShipmentAgg AS
(
    SELECT
        sales_order_line_id,
        SUM(quantity_shipped) AS quantity_shipped_total,
        MIN(ship_date) AS first_ship_date,
        MAX(actual_delivery_date) AS last_delivery_date
    FROM ShipmentEvents
    GROUP BY sales_order_line_id
),
Completion AS
(
    SELECT
        e.sales_order_line_id,
        MIN(e.actual_delivery_date) AS completion_delivery_date
    FROM ShipmentEvents e
    INNER JOIN silver.sales_order_lines ol
        ON e.sales_order_line_id = ol.sales_order_line_id
    WHERE e.cumulative_qty >= ol.quantity_ordered
    GROUP BY e.sales_order_line_id
)
INSERT INTO gold.fact_fulfillment
(
    sales_order_line_id,
    sales_order_id,
    product_key,
    quantity_ordered,
    quantity_shipped_total,
    first_ship_date,
    last_delivery_date,
    completion_delivery_date,
    promised_delivery_date,
    line_complete_flag,
    line_on_time_flag,
    late_delivery_days
)
SELECT
    ol.sales_order_line_id,
    ol.sales_order_id,
    p.product_key,
    ol.quantity_ordered,
    COALESCE(sa.quantity_shipped_total, 0),
    sa.first_ship_date,
    sa.last_delivery_date,
    c.completion_delivery_date,
    ol.promised_delivery_date,

    CASE
        WHEN COALESCE(sa.quantity_shipped_total, 0) >= ol.quantity_ordered
        THEN 1 ELSE 0
    END AS line_complete_flag,

    CASE
        WHEN COALESCE(sa.quantity_shipped_total, 0) < ol.quantity_ordered
            THEN NULL
        WHEN c.completion_delivery_date <= ol.promised_delivery_date
            THEN 1
        ELSE 0
    END AS line_on_time_flag,

    CASE
        WHEN COALESCE(sa.quantity_shipped_total, 0) < ol.quantity_ordered
            THEN NULL
        WHEN c.completion_delivery_date <= ol.promised_delivery_date
            THEN 0
        ELSE DATEDIFF(DAY, ol.promised_delivery_date, c.completion_delivery_date)
    END AS late_delivery_days

FROM silver.sales_order_lines ol
INNER JOIN gold.dim_product p
    ON ol.product_id = p.product_id
LEFT JOIN ShipmentAgg sa
    ON ol.sales_order_line_id = sa.sales_order_line_id
LEFT JOIN Completion c
    ON ol.sales_order_line_id = c.sales_order_line_id;


    COMMIT TRANSACTION;
    PRINT 'LOAD gold.fact_fulfillment completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
    PRINT CONCAT('Error Line: ', ERROR_LINE());
    PRINT CONCAT('Error Message: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

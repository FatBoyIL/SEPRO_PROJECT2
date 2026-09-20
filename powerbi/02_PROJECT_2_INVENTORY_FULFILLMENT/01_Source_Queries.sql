/* ============================================================
   PROJECT 2 - ORDER LINE AVAILABILITY DIAGNOSTIC
   Query name: pbi_p2_order_line_availability
   Grain: 1 row = 1 sales order line

   Availability is evaluated at network level on order date because
   the Sales Order does not carry a warehouse key.
   ============================================================ */
WITH network_inventory AS (
    SELECT
        snapshot_date_key,
        product_key,
        SUM(available_qty) AS network_available_qty,
        SUM(on_hand_qty) AS network_on_hand_qty
    FROM gold.fact_inventory_snapshot
    GROUP BY
        snapshot_date_key,
        product_key
)
SELECT
    sol.sales_order_line_id,
    so.sales_order_id,
    so.customer_key,
    so.order_date_key,
    so.order_date,
    so.requested_delivery_date,
    sol.product_key,
    sol.quantity_ordered,
    ni.network_on_hand_qty,
    ni.network_available_qty,
    CASE
        WHEN ni.product_key IS NULL THEN 'Missing snapshot'
        WHEN ni.network_available_qty >= sol.quantity_ordered THEN 'Available in full'
        WHEN ni.network_available_qty > 0 THEN 'Partially available'
        ELSE 'No stock'
    END AS line_availability_group,
    f.quantity_shipped_total,
    f.line_complete_flag,
    f.line_on_time_flag,
    f.completion_delivery_date,
    f.late_delivery_days
FROM gold.fact_sales_order_line AS sol
INNER JOIN gold.fact_sales_order AS so
    ON so.sales_order_id = sol.sales_order_id
LEFT JOIN network_inventory AS ni
    ON ni.snapshot_date_key = so.order_date_key
   AND ni.product_key = sol.product_key
LEFT JOIN gold.fact_fulfillment AS f
    ON f.sales_order_line_id = sol.sales_order_line_id;

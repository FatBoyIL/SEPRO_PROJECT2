USE [SEPRO_Master_Prod];
GO

/* ============================================================
   PROJECT 2 - RUN ORDER
   STOP POINT: KPI validation. Do NOT add to Power BI yet.

   Shared dimensions were already created/loaded earlier:
   - gold.dim_date
   - gold.dim_product
   - gold.dim_supplier
   - gold.dim_warehouse
   - gold.dim_employee
   - gold.dim_customer

   Execute files in filename order:

   000  Prerequisites
   010-012 fact_inventory_snapshot
   020-022 fact_inventory_movement
   030-032 fact_purchase_order
   040-042 fact_purchase_order_line
   050-052 fact_shipment
   060-062 fact_shipment_line
   070-072 fact_fulfillment
   080-082 mart_inventory_risk
   090-092 mart_order_availability_otif
   100-102 mart_supplier_performance
   130  Final KPI validation

   Important grain rules:
   - Inventory snapshot: 1 row = date + product + warehouse
   - Inventory movement: 1 row = inventory movement
   - Purchase order: 1 row = PO
   - Purchase order line: 1 row = PO line
   - Shipment: 1 row = shipment
   - Shipment line: 1 row = shipment line
   - Fulfillment: 1 row = sales order line
   - Inventory risk mart: 1 row = product + month
   - Availability/OTIF mart: 1 row = sales order
   - Supplier performance mart: 1 row = PO line

   Partial shipment warning:
   Customer OTIF is calculated at ORDER grain, not shipment grain.
   ============================================================ */

SELECT
    'Project 2 SQL package is ready. Execute files in filename order.' AS instruction;
GO

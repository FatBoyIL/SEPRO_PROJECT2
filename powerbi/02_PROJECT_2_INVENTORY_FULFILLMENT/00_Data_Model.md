# Project 2 — Data Model

## Business scope

**Sales Order → Inventory → Availability → Shipment/Delivery → Supplier → Total Cost**

Ba câu hỏi:
1. SKU nào có stockout / fulfillment risk cao?
2. Availability at Order liên hệ thế nào với Customer OTIF?
3. Supplier nào cân bằng reliability và total cost?

## Tables cần load

| Query | Source | Grain |
|---|---|---|
| `dim_date` | `gold.dim_date` | date |
| `dim_product` | `gold.dim_product` | product |
| `dim_warehouse` | `gold.dim_warehouse` | warehouse |
| `dim_supplier` | `gold.dim_supplier` | supplier |
| `dim_customer` | `gold.dim_customer` | customer |
| `fact_inventory_snapshot` | `gold.fact_inventory_snapshot` | date × product × warehouse |
| `mart_inventory_risk` | `gold.mart_inventory_risk` | month × product |
| `mart_order_availability_otif` | `gold.mart_order_availability_otif` | order |
| `mart_supplier_performance` | `gold.mart_supplier_performance` | PO line |
| `pbi_p2_order_line_availability` | helper SQL | sales order line |

## Relationships

```text
dim_date[date_key] 1 ─ * fact_inventory_snapshot[snapshot_date_key]
dim_product[product_key] 1 ─ * fact_inventory_snapshot[product_key]
dim_warehouse[warehouse_key] 1 ─ * fact_inventory_snapshot[warehouse_key]

dim_product[product_key] 1 ─ * mart_inventory_risk[product_key]
dim_date[date] 1 ─ * mart_inventory_risk[month_start_date]

dim_customer[customer_key] 1 ─ * mart_order_availability_otif[customer_key]

dim_supplier[supplier_key] 1 ─ * mart_supplier_performance[supplier_key]
dim_product[product_key] 1 ─ * mart_supplier_performance[product_key]

dim_product[product_key] 1 ─ * pbi_p2_order_line_availability[product_key]
```

For `mart_order_availability_otif[order_date]`, create an inactive relationship to `dim_date[date]` if the model already needs another date path, or use it as the active one if this mart is isolated from other date-filtered facts. Avoid ambiguous paths.

## Important limitation

`fact_purchase_order_line` does not contain `quantity_received`. Therefore `supplier_otif_proxy_flag` is a **timeliness proxy**, not true Supplier OTIF In-Full evidence. Label it clearly in the report.

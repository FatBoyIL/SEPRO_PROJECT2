# Project 2 — Interactions & Navigation

## Navigation

Page Navigator:
1. Inventory Risk
2. Availability vs OTIF
3. Supplier & TCO

## Slicers

Sync where semantically valid:
- Date/Month
- Product category

Do **not** sync Warehouse into Supplier page if it does not filter supplier performance through a valid relationship.

## Page 1 interaction

Selecting a warehouse heatmap cell filters the SKU exception table via `fact_inventory_snapshot` only. `mart_inventory_risk` is network-level, so if the relationship does not logically support warehouse filtering, disable cross-filter into network-level KPI cards.

This is intentional: do not imply `mart_inventory_risk` is warehouse-grain.

## Page 2 interaction

Availability group filters OTIF and exception table where valid. Product selection in the line diagnostic should not silently alter the order-level mart through an invalid path.

## Page 3 interaction

Supplier scorecard filters cost composition and supplier×product matrix.

## Drill-through

Use `dim_supplier[supplier_name]` as drill-through field on supplier detail page.

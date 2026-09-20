# Project 2 — Validation Checklist

No hard-coded output values are stored in the database script supplied, so Power BI must be reconciled against the Project 2 SQL analysis/conclusion results when run on your SQL Server.

## Inventory
- Stockout Rate = stockout SKU-warehouse days / observed SKU-warehouse days.
- Coverage is not averaged blindly when distribution is skewed; headline uses Median.
- Warehouse heatmap uses daily snapshot fact, not monthly network mart.

## OTIF
- Denominator = delivered orders.
- OTIF evaluated at order grain after partial shipments are aggregated.
- Availability group comes from order-level Gold mart for headline analysis.
- Line-level helper is diagnostic only.

## Supplier
- Timely Receipt Rate denominator = received PO lines.
- Estimated TCO = source mart value; do not recompute with arbitrary weights.
- Supplier OTIF label must include `proxy`/`timeliness` limitation because quantity_received is absent.

## Model
- No Fact ↔ Fact relationships.
- No many-to-many relationship added to force slicers to work.

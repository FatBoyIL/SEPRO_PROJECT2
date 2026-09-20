# Page 1 — Inventory Risk

## Business question

**SKU nào đang có stockout / fulfillment risk cao và ở đâu?**

## Style

Operations Control Tower. Không dùng funnel/bubble. Trọng tâm là **heatmap + exception ranking**.

## Layout

```text
┌─────────────────────────────────────────────────────────────┐
│ Inventory Risk               Month | Warehouse | Category   │
├───────────┬───────────┬───────────┬─────────────────────────┤
│ Stockout% │ Coverage  │ Fulfill%  │ Latest Inventory Value  │
├─────────────────────────────────────┬───────────────────────┤
│ HERO Warehouse × Month Heatmap      │ Stockout trend        │
├─────────────────────────────────────┴───────────────────────┤
│ Exception table: Product | Stockout | Coverage | Risk | Inv │
└─────────────────────────────────────────────────────────────┘
```

## KPI status strip

- `[P2 Stockout Rate]`
- `[P2 Median Coverage Days]`
- `[P2 Fulfillment Risk Rate]`
- `[P2 Latest Inventory Value]`

## HERO — Warehouse × Month Heatmap

Visual: **Matrix**.
- Rows: `dim_warehouse[warehouse_name]`
- Columns: `dim_date[month_name]` or Month-Year
- Values: `[P2 Warehouse Stockout Rate]`

Conditional formatting:
- Background color scale low → high.
- Show value as % with 1 decimal.

This visual answers where stockout exposure is concentrated operationally.

## Stockout trend

Line chart:
- X: `dim_date[date]` aggregated Month
- Y: `[P2 Warehouse Stockout Rate]`
- Legend: optional `dim_warehouse[warehouse_name]` only when filtered to a small number of warehouses.

## SKU exception table

Rows / columns:
- `dim_product[sku]`
- `dim_product[product_name]`
- `[P2 Stockout Rate]`
- `[P2 Median Coverage Days]`
- `[P2 Fulfillment Risk Rate]`
- `[P2 Latest Inventory Value]`

Sort descending by Stockout Rate or Fulfillment Risk depending on selected business focus.

Conditional formatting:
- Stockout / risk: data bars.
- Coverage: icons or scale.
- Inventory value: compact currency.

## Slicers

- Month range
- Warehouse
- Product category
- Product family

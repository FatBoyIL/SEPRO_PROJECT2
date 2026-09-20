# Page 2 — Availability vs OTIF

## Business question

**Stock availability tại thời điểm order có liên hệ thế nào với Customer OTIF?**

## Style

Exception-flow page: availability group → customer outcome → affected order lines.

## KPI row

- `[P2 Customer OTIF Rate]`
- `[P2 Full Availability Orders]`
- `[P2 Partial Availability Orders]`
- `[P2 No Stock Orders]`
- `[P2 Late Delivered Orders]`

## HERO — OTIF by Availability Group

Visual: 100% stacked column chart.
- X: `mart_order_availability_otif[availability_group]`
- Values:
  - `[P2 OTIF Orders]`
  - `[P2 Non OTIF Delivered Orders]`

Alternative if absolute volume matters more: use normal stacked column instead of 100%.

Tooltip:
- `[P2 Delivered Orders]`
- `[P2 Customer OTIF Rate]`
- `[P2 Incomplete Orders]`

## Diagnostic — Decomposition Tree

Analyze: `[P2 Late Delivered Orders]` or `[P2 Non OTIF Delivered Orders]`.

Explain by:
1. `availability_group`
2. `dim_customer[segment]`
3. `dim_customer[industry]`

Do not add Product here unless using `pbi_p2_order_line_availability`, because the order-level mart has no product key.

## Exception table — line-level

Use `pbi_p2_order_line_availability`:
- `sales_order_id`
- `sales_order_line_id`
- related product SKU/name
- `line_availability_group`
- `quantity_ordered`
- `network_available_qty`
- `line_complete_flag`
- `line_on_time_flag`
- `late_delivery_days`

Filter default:
- Availability ≠ `Available in full` OR line incomplete/late.

## Method note

The helper diagnostic evaluates **network availability on order date** because Sales Order has no warehouse key. Warehouse-level causality must not be claimed from this helper.

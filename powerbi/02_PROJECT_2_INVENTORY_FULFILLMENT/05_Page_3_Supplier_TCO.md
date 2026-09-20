# Page 3 — Supplier Reliability & TCO

## Business question

**Supplier nào cân bằng reliability và total cost, thay vì chỉ nhìn unit price?**

## Style

Supplier control board: scorecard matrix + cost composition + product-level reliability.

## KPI row

- `[P2 Timely Receipt Rate]`
- `[P2 Avg Actual Lead Time Days]`
- `[P2 Landed Cost]`
- `[P2 Estimated TCO]`
- `[P2 Quality Cost Rate]`

Label under first KPI:
> Timeliness proxy; source does not contain quantity_received for true Supplier OTIF In-Full.

## HERO — Supplier scorecard matrix

Rows: `dim_supplier[supplier_name]`

Values:
- `[P2 Received PO Lines]`
- `[P2 Timely Receipt Rate]`
- `[P2 Avg Actual Lead Time Days]`
- `[P2 Estimated TCO per Ordered Unit]`
- `[P2 Quality Cost Rate]`
- `[P2 Expedite Cost]`

Conditional formatting:
- Timely rate: icon set.
- Lead time/TCO/quality/expedite: color scale.

This avoids inventing a weighted composite score.

## Cost composition

Stacked bar chart by Supplier:
- Merchandise Cost
- Freight Cost
- Customs Cost
- Expedite Cost
- Quality Cost

Use Top N supplier by Landed Cost if supplier list is long.

## Supplier × Product matrix

Rows: Supplier  
Columns: Product category or SKU  
Values: `[P2 Timely Receipt Rate]` or `[P2 Estimated TCO per Ordered Unit]`

Use conditional background formatting.

Purpose: supplier performance can vary by product; do not evaluate supplier only at total-company level.

## Detail drill-through

Create page `DT_P2_Supplier` with:
- PO Line
- Product
- Expected receipt
- Actual receipt
- Late days
- Lead time
- Landed Cost
- Quality Cost
- Estimated TCO

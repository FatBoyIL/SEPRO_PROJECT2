# SEPRO 02 — Inventory & Order Fulfillment Analytics

**Gold Layer | Operations & Supply Chain Analytics | SQL Server + Power BI**

This repository is the **Gold Layer** for Project 02 of my SEPRO Data Analytics Portfolio. It starts where Project 01 ends: a customer has already placed a Sales Order, and the analytical problem becomes whether demand can be fulfilled reliably without creating excessive inventory or choosing suppliers only on purchase price.

The upstream Silver Layer is maintained separately in:

**Silver Layer repository:** https://github.com/FatBoyIL/SEPRO_Cleaning_Data

## Portfolio Context

| Project | Scope | Central question |
|---|---|---|
| 01 — Lead-to-Order | Marketing + Sales | How does demand become an order? |
| **02 — Inventory & Fulfillment** | Sales Order + Inventory + Purchasing + Logistics | How can demand be fulfilled efficiently? |
| 03 — Lead-to-Cash | Commercial + Operations + Finance | Where are time and working capital lost end-to-end? |

## Data Disclosure

This case study is modeled on a B2B operating process I have worked with and understand in practice. To protect confidential company information, all transaction-level customer, supplier, pricing, inventory, purchasing, logistics, revenue, and payment records in this portfolio are **synthetically generated**.

The data is used to recreate realistic business relationships and operational trade-offs so that I can demonstrate how I approach inventory, fulfillment, supplier, and total-cost analysis without exposing company records.

## Architecture

```text
Synthetic Source Data
        ↓
Bronze Layer
        ↓
Silver Layer
Clean • Standardize • Validate • Reconcile
        ↓
Gold Layer  ←  THIS REPOSITORY
Facts • Operational Marts • KPI Validation
        ↓
Business Analysis SQL
        ↓
Power BI / Insight / Recommendation
```

Project 02 reuses commercial master data and Sales Order structures established upstream, then extends the model into inventory, purchasing, shipment, fulfillment, and supplier-cost analysis.

## Business Problem

Customer demand must be fulfilled on time while controlling inventory exposure and procurement cost. The main trade-offs are:

```text
Availability vs Inventory Cost
Purchase Price vs Supplier Reliability
Safety Stock vs Service Level
```

## Core Business Questions

1. Which products are most exposed to stockout risk and late fulfillment?
2. How is stock availability at order time associated with Customer OTIF?
3. Which suppliers provide the best reliability-versus-total-cost trade-off, rather than simply the lowest unit price?

## Business Flow

```text
Sales Order
    ↓
Inventory Availability
    ↓
Fulfillment / Shipment / Delivery
    ↓
Customer OTIF

If stock is constrained:

Inventory Need
    ↓
Purchase Order
    ↓
Supplier Receipt
    ↓
Quality / Inbound Cost
    ↓
Inventory Available
```

## Gold Layer Scope

### Reused shared dimensions / commercial facts

- Date
- Customer
- Product
- Supplier
- Warehouse
- Sales Order
- Sales Order Line

### Project 02 facts

- `gold.fact_inventory_snapshot`
- `gold.fact_inventory_movement`
- `gold.fact_purchase_order`
- `gold.fact_purchase_order_line`
- `gold.fact_shipment`
- `gold.fact_shipment_line`
- `gold.fact_fulfillment`

### Analytical marts

- `gold.mart_inventory_risk`
- `gold.mart_order_availability_otif`
- `gold.mart_supplier_performance`

## Main Source Domains Reviewed

The original synthetic source package includes:

- `inventory_daily_snapshot_raw.csv`
- `inventory_movements_raw.csv`
- `inventory_policy_history.csv`
- `purchase_orders_raw.csv`
- `purchase_order_lines_raw.csv`
- `qa_events_raw.csv`
- `shipments_raw.csv`
- `shipment_lines_raw.csv`
- reused `sales_orders_raw.csv` and `sales_order_lines_raw.csv`
- shared products, suppliers, warehouses, customers, and FX/reference data

The project also includes a TCO framework and intervention records as analytical context.

## Key Metrics

- Weighted Stockout Rate
- Inventory Coverage Days
- Average Daily Demand
- Fulfillment Risk Rate
- Customer OTIF
- Availability Group
- Supplier Receipt Timeliness Proxy
- Actual Lead Time
- Landed Cost
- Estimated Holding Cost
- Estimated TCO

For exact definitions and implementation cautions, see [`docs/04_metric_definitions.md`](docs/04_metric_definitions.md).

## Analysis Approach

```text
Validate operational marts
        ↓
Profile stockout / coverage distribution
        ↓
Drill down Product × Warehouse × Month
        ↓
Segment SKU risk and Pareto exposure
        ↓
Compare availability at order vs Customer OTIF
        ↓
Trace SKU/order-line shortages to late or incomplete fulfillment
        ↓
Compare supplier reliability and total-cost components
        ↓
Drill down Supplier × Product
        ↓
Produce decision-ready conclusion outputs
```

## Repository Structure

```text
.
├── README.md
├── docs/
│   ├── 01_project_overview.md
│   ├── 02_business_logic.md
│   ├── 03_data_model.md
│   ├── 04_metric_definitions.md
│   ├── 05_assumptions_limitations.md
│   └── 06_review_guide.md
│
├── sql/
│   ├── 00_setup/
│   ├── 01_gold_model/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   └── marts/
│   ├── 02_validation/
│   ├── 03_analysis/
│   │   ├── 01_core/
│   │   └── 02_diagnostics/
│   └── 99_conclusion/
│
├── powerbi/
├── images/
└── data/
    └── sample/
```

## Reproducibility

Recommended execution order:

1. Prepare and validate Silver tables from the upstream Silver repository.
2. Verify shared dimensions and reused Sales Order facts are available.
3. Create/load Project 02 facts.
4. Create/load the three analytical marts.
5. Run Project 02 KPI validation.
6. Run core and diagnostic SQL.
7. Use the marts as Power BI sources.

## Analytical Principles Demonstrated

- Preserve daily inventory grain before monthly aggregation.
- Keep warehouse and product context available for diagnostics.
- Calculate Customer OTIF at **Sales Order grain**, not shipment grain.
- Aggregate partial shipments before deciding whether an order is complete.
- Do not choose suppliers using unit price alone.
- Keep reliability, landed cost, quality cost, expedite cost, and TCO visible separately.
- Do not invent a composite supplier score unless business weights are defined.
- Treat availability vs OTIF as an observational association, not causal proof.

## Power BI

The intended reporting structure is:

- Inventory Risk
- Availability vs OTIF
- Supplier Performance / TCO

Dashboard screenshots should be stored under `images/`, while the Power BI file belongs in `powerbi/`.

## Documentation

- [`docs/03_data_model.md`](docs/03_data_model.md) — operational lineage, grains, and dependencies
- [`docs/04_metric_definitions.md`](docs/04_metric_definitions.md) — inventory, fulfillment, OTIF, and supplier metric contracts
- [`docs/05_assumptions_limitations.md`](docs/05_assumptions_limitations.md) — availability, supplier, and TCO limitations
- [`docs/06_review_guide.md`](docs/06_review_guide.md) — step-by-step review guide

---

**Portfolio note:** the business logic is designed to reflect how I understand and analyze the process in practice; the underlying transaction values are synthetic to protect confidential company information.

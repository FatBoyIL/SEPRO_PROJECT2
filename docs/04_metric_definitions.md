# Metric Definitions — Project 02: Inventory & Order Fulfillment Analytics

| Metric | Business meaning | Formula / rule | Grain / population | Primary Gold object | Important note |
|---|---|---|---|---|---|
| **Weighted Stockout Rate** | Share of observed SKU-warehouse-days in stockout | `Stockout SKU-Warehouse-Days / Observed SKU-Warehouse-Days` | Product / Month, with warehouse-day evidence | `mart_inventory_risk` | Use daily snapshots; do not infer stockout from month-end only. |
| **Average Daily Demand (60d)** | Recent demand rate used for coverage | trailing 60-day ordered quantity / demand window days | Product | `mart_inventory_risk` | The 60-day window is an explicit project assumption. |
| **Inventory Coverage Days** | Approximate number of demand days covered by available inventory | `Available Inventory / Average Daily Demand` | Product / Month | `mart_inventory_risk` | Interpret together with stockout and demand. |
| **Fulfillment Risk Rate** | Share of eligible fulfillment lines that are late or incomplete | `Late or Incomplete Lines / Eligible Fulfillment Lines` | Product / Month | `mart_inventory_risk` | Diagnostic line-level service measure, not Customer OTIF. |
| **Customer OTIF** | Share of delivered Sales Orders completed on/before requested date | `Delivered On Time AND Complete Orders / Delivered Orders` | Sales Order | `mart_order_availability_otif` | Partial shipments must be aggregated to order grain first. |
| **Availability Group** | Stock position when the order was received | Full / Partial / No Stock / Missing Snapshot | Sales Order / derived from order lines | `mart_order_availability_otif` | Main analysis uses network-level availability. |
| **Supplier Receipt Timeliness Proxy** | Share of received PO lines arriving by expected date | `On-Time Received PO Lines / Received PO Lines` | Supplier / Product / PO Line | `mart_supplier_performance` | This is **not true Supplier OTIF** because in-full receipt quantity is unavailable. |
| **Actual Lead Time** | Time from PO placement to receipt | `First/actual receipt date - PO date` | Received PO line | `mart_supplier_performance` | Use median/P90 where distributions are skewed. |
| **Late Receipt Days** | Days received after expected receipt date | `Actual Receipt Date - Expected Receipt Date` when late | Received PO line | `mart_supplier_performance` | Negative/zero values are not late. |
| **Landed Cost** | Total inbound supplier cost beyond unit price | `Merchandise + Freight + Customs + Expedite + Quality Cost` | PO line / Supplier / Product | `mart_supplier_performance` | Quality cost is sourced from QA-event evidence. |
| **Estimated Holding Cost** | Working-capital cost proxy associated with inventory holding | `Average Inventory Value × Annual Holding Rate × Holding Days / 365` | Supplier/Product proxy | `mart_supplier_performance` | Requires inventory-value and holding-rate coverage. |
| **Estimated TCO** | Supplier total-cost proxy | `Landed Cost + Estimated Holding Cost` | PO line / Supplier / Product | `mart_supplier_performance` | Read together with TCO coverage; not an accounting ledger value. |

## Customer OTIF Rule

Customer OTIF is intentionally calculated at **Sales Order grain**:

```text
Complete Order
= total quantity shipped across all partial shipments
  >= total quantity ordered

Final Delivery Date
= date when the order is fully completed

On Time
= Final Delivery Date <= Requested Delivery Date

OTIF
= Complete AND On Time
```

The denominator is **Delivered Orders**.

## Supplier OTIF vs Timeliness Proxy

The original KPI framework defines Supplier OTIF as:

```text
PO lines received on/before expected date AND in full
-----------------------------------------------------
                  received PO lines
```

However, the implemented Gold model does not have reliable `quantity_received` evidence at PO-line grain. Therefore the repository deliberately labels the operational metric as a **Supplier Receipt Timeliness Proxy** rather than claiming true Supplier OTIF.

## Supplier Decision Framework

No arbitrary weighted supplier score is used. Supplier decisions should consider the trade-off among:

- receipt timeliness;
- actual lead time;
- landed cost;
- expedite cost;
- quality cost;
- estimated TCO;
- product-specific performance.

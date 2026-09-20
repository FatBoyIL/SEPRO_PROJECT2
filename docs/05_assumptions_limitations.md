# Assumptions & Limitations — Project 02: Inventory & Order Fulfillment Analytics

## 1. Synthetic Portfolio Data

All operational transactions in this case study are synthetic. They do not disclose actual SEPRO supplier pricing, inventory values, logistics records, customer demand, or procurement transactions.

The workflow is designed to demonstrate how I understand and analyze a B2B inventory, purchasing, fulfillment, and supplier-performance process.

## 2. Gold Depends on the Silver Layer

The Gold objects assume the upstream Silver model has already standardized keys, dates, quantities, currency-related fields, statuses, text values, and important relationships.

Silver repository:

https://github.com/FatBoyIL/SEPRO_Cleaning_Data

## 3. Daily Snapshot Requirement

Stockout risk is evaluated from daily inventory snapshots. Month-end inventory alone is not sufficient because it can hide stockout events that occurred earlier in the month.

## 4. Stockout and Availability

The project distinguishes inventory concepts such as on-hand and available quantity. Availability analysis uses inventory available for fulfillment rather than treating on-order quantity as immediately usable stock.

## 5. Demand Window

Inventory Coverage uses a trailing **60-day demand window** in the current project implementation. This is an analytical assumption and should be reviewed if the business uses another planning horizon.

## 6. Network-Level Availability

The source data does not contain a confirmed allocated warehouse for every Sales Order Line at the moment an order is created. The main availability-at-order analysis therefore uses **network-level inventory across warehouses**.

Warehouse-level stockout risk is still available as a diagnostic analysis from the inventory snapshot fact.

## 7. Customer OTIF Population

Customer OTIF is calculated at Sales Order grain and uses **Delivered Orders** as the denominator. Open/not-yet-delivered orders should not be mixed into the OTIF denominator unless the KPI definition is explicitly changed.

## 8. Partial Shipments

A Sales Order may be delivered in multiple shipments. No individual shipment is classified as "In Full" for the order. All shipment-line quantities must first be aggregated back to the order/order-line grain.

## 9. Supplier OTIF Limitation

The source/Gold PO-line model does not provide sufficient `quantity_received` evidence to prove in-full receipt at PO-line grain.

Therefore:

- `supplier_otif_proxy_flag` is treated as **receipt timeliness only**;
- the repository does not claim true Supplier OTIF;
- supplier reliability conclusions should use the proxy together with lead time and sample size.

## 10. TCO Is an Analytical Estimate

Estimated TCO contains modeled cost components, including an estimated holding-cost proxy. It is not a replacement for accounting or finance-ledger actuals.

Holding-cost results depend on:

- available inventory-value evidence;
- annual holding-rate assumptions;
- the chosen holding period;
- appropriate allocation to supplier/product combinations.

TCO should be interpreted together with coverage indicators.

## 11. Supplier Comparison

A supplier can perform differently by product. Supplier-level averages should therefore be supplemented by Supplier × Product diagnostics before sourcing decisions are made.

## 12. No Arbitrary Composite Score

The project intentionally avoids a weighted supplier score because no business-approved weighting exists for cost, reliability, quality, and lead time.

## 13. Association, Not Causation

If full availability is associated with higher OTIF, that relationship is observational. OTIF can also be affected by warehouse execution, transportation, supplier delays, customer requested dates, and other operational factors.

Pre/post intervention comparisons are also descriptive unless supported by a causal design.

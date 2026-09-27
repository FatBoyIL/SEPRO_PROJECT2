# 📦 SEPRO 02 — Inventory & Order Fulfillment Analytics

**Gold Layer | Operations & Supply Chain Analytics | SQL Server + Power BI**

Analyzed the operational flow after a customer places an order to understand **inventory risk, fulfillment reliability, Customer OTIF, and supplier cost-reliability trade-offs**.

---

## 📊 Key Analytical Outcomes

| Area | Outcome |
|---|---|
| Fulfillment evidence | **455 successfully delivered orders** used to evaluate downstream service performance |
| Inventory risk | Stockout and coverage analyzed from **daily inventory snapshots**, not month-end balance alone |
| Customer OTIF | Calculated at **Sales Order grain** after aggregating partial shipments |
| Availability vs OTIF | Compared order-time availability with delivered-order OTIF to identify service-level differences |
| Supplier performance | Evaluated using **actual lead time, landed cost, expedite cost, quality cost, holding cost, and estimated TCO** |
| Data limitation | Supplier receipt timeliness is treated as a **proxy**, not true Supplier OTIF, because reliable `quantity_received` is unavailable |

```text
Sales Order
    ↓
Inventory Availability
    ↓
Fulfillment
    ↓
Shipment / Delivery
    ↓
Customer OTIF
```

---

## 🧹 Data Preparation

The source package intentionally contains imperfect operational data such as missing values, duplicated records, inconsistent formats, incomplete receipt evidence, and repeated business events.

These issues are handled upstream in the **Silver Layer** before Gold modeling and analysis.

🔗 **Silver Layer:** [SEPRO_Cleaning_Data](https://github.com/FatBoyIL/SEPRO_Cleaning_Data)

The Gold Layer then focuses on:

- Grain validation
- Fact and dimension modeling
- Operational marts
- KPI validation
- Diagnostic SQL
- Power BI reporting

---

## 🧠 Business Thinking

- **Availability is not the same as service level** → inventory position must be connected to actual fulfillment evidence
- **Daily evidence before monthly KPI** → stockout risk is measured from daily Product × Warehouse snapshots before aggregation
- **Order grain for Customer OTIF** → partial shipments are aggregated before deciding whether an order was delivered On Time and In Full
- **Coverage and stockout must be read together** → high inventory does not automatically mean healthy inventory
- **Supplier price is not total supplier cost** → reliability, freight, customs, expedite, quality, and holding cost must also be considered
- **Proxy is not a true KPI** → supplier receipt timeliness is not presented as true Supplier OTIF when in-full receipt evidence is unavailable
- **Association is not causation** → lower availability can be associated with lower OTIF without proving that inventory shortage alone caused the service failure
- **No arbitrary supplier score** → trade-offs remain visible unless business-defined weights exist

---

## 🧩 Four Modeling Perspectives

| Model | Purpose in This Project |
|---|---|
| **Data Model** | Organize inventory, purchasing, shipment, fulfillment, supplier, and Sales Order data at the correct grain |
| **Business Model** | Represent how customer demand moves from Sales Order → Inventory Availability → Fulfillment → Delivery → Customer OTIF |
| **Analytic Model** | Analyze the factors associated with stockout risk, late or incomplete fulfillment, service level, supplier reliability, and total cost |
| **Predictive Model** | Future extension for demand forecasting, stockout risk prediction, replenishment planning, or supplier lead-time prediction. Predictive modeling is **not implemented in the current version** |

```text
Business Process
      ↓
Business Model
      ↓
Data Model
      ↓
Analytic Model
      ↓
Insight & Decision Support
      ↓
Predictive Model
Future Scope
```

The current project focuses on **descriptive and diagnostic analytics**.

---

## 🎯 ROI Framework

### R — Relevance

Once a Sales Order is created, the business must answer a different question:

> **Can customer demand be fulfilled reliably without creating excessive inventory or selecting suppliers only by purchase price?**

The project focuses on three operational questions:

1. Which products and warehouses are most exposed to **stockout and fulfillment risk**?
2. How is **availability at order time** associated with Customer OTIF?
3. Which suppliers show meaningful **reliability vs total-cost trade-offs**?

### O — Outcome

The project connects three decision areas that are often analyzed separately:

```text
Inventory Risk
      +
Order Fulfillment
      +
Supplier Performance
      ↓
Operational Decision Support
```

It uses delivered-order evidence to evaluate service performance, drills inventory exposure down to Product × Warehouse × Month, and expands supplier analysis beyond unit price into landed cost and estimated TCO.

### I — Insight

The main analytical value comes from keeping the business logic and the data grain aligned:

- Stockout risk is diagnosed from daily inventory evidence
- Customer OTIF is evaluated after partial shipments are consolidated
- Availability groups are compared using delivered-order populations
- Supplier performance is reviewed at Supplier × Product level
- TCO is interpreted together with its data coverage
- Operational flags are used to prioritize investigation, not as automatic verdicts

---

## 🚀 Decision Focus

The analysis supports five practical decision areas:

1. Prioritize SKUs with **high stockout and fulfillment exposure**
2. Investigate warehouse and replenishment patterns behind recurring shortages
3. Review failed OTIF orders at order-line level to distinguish **late vs incomplete fulfillment**
4. Compare suppliers using **reliability and total-cost components**, not purchase price alone
5. Improve source-data capture where missing receipt quantity prevents true Supplier OTIF measurement

---

## 🛠️ Technical Approach

```text
Synthetic Operational Data
        ↓
Bronze Layer
        ↓
Silver Layer
Clean → Standardize → Validate → Reconcile
        ↓
Gold Layer
Facts → Operational Marts → KPI Validation
        ↓
T-SQL Analysis
        ↓
Power BI
Insight → Decision Support
```

### Main Gold Marts

- `gold.mart_inventory_risk` → Product × Month inventory and fulfillment risk
- `gold.mart_order_availability_otif` → 1 row per Sales Order
- `gold.mart_supplier_performance` → 1 row per Purchase Order Line

### Important Grains

| Object | Grain |
|---|---|
| `fact_inventory_snapshot` | Date × Product × Warehouse |
| `fact_fulfillment` | 1 Sales Order Line |
| `mart_order_availability_otif` | 1 Sales Order |
| `mart_supplier_performance` | 1 Purchase Order Line |

### Key Skills

**SQL Server | T-SQL | JOIN | CTE | Window Functions | Data Validation | Data Modeling | Inventory Analytics | OTIF Analysis | Supplier Analysis | TCO Analysis | Power BI | DAX**

---

## 📈 Power BI Report

### Inventory Risk

<img width="6150" height="3525" alt="Project 2 (1)_page-0001" src="https://github.com/user-attachments/assets/84308745-4bf0-4864-b479-1e73b3776406" />

### Availability vs OTIF

<img width="6150" height="3525" alt="Project 2 (1)_page-0002" src="https://github.com/user-attachments/assets/86748e8b-3ff3-4ecf-9069-4b924ddd17bf" />

### Supplier Performance / TCO

<img width="6150" height="3525" alt="Project 2 (1)_page-0003" src="https://github.com/user-attachments/assets/ec573754-9354-4a80-8eee-fbbd136863dd" />

---

## 📐 Core Metrics

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

---

## 📁 Repository Guide

- [`docs/03_data_model.md`](docs/03_data_model.md) → grain, lineage, and operational relationships
- [`docs/04_metric_definitions.md`](docs/04_metric_definitions.md) → KPI definitions and population rules
- [`docs/05_assumptions_limitations.md`](docs/05_assumptions_limitations.md) → availability, supplier, and TCO limitations
- [`docs/06_review_guide.md`](docs/06_review_guide.md) → step-by-step analytical review
- [`sql/`](sql/) → Gold modeling, validation, diagnostics, and conclusion SQL
- [`powerbi/`](powerbi/) → Power BI project files

---

## 🔒 Data Disclosure

This case study is modeled on a B2B operating process I have worked with and understand in practice.

Customer, supplier, pricing, inventory, purchasing, logistics, and transaction-level records are **synthetically generated** to protect confidential company information.

The project is designed to demonstrate how I approach operational analytics from data preparation and grain control to decision support.

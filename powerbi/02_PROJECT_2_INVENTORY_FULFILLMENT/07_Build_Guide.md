# Project 2 — Build Guide

1. Import dimensions and Gold facts/marts from `00_Data_Model.md`.
2. Add `pbi_p2_order_line_availability` as native SQL query.
3. Build only documented relationships; do not create convenience many-to-many links.
4. Paste measures from `02_Measures.dax`.
5. Import `Theme.json`.
6. Build Page 1 heatmap first; verify warehouse stockout comes from `fact_inventory_snapshot`.
7. Build Page 2 OTIF visual from the order-grain mart.
8. Add line-level exception table from helper query.
9. Build supplier scorecard from `mart_supplier_performance`.
10. Add limitation text for supplier OTIF proxy.
11. Use Edit Interactions to block invalid warehouse/product filter paths across marts of different grain.
12. Validate all cards against Project 2 Conclusion SQL before formatting.

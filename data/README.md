# Data

This folder contains the synthetic portfolio data relevant to **Project 02 - Inventory & Order Fulfillment Analytics**.

## Data disclosure

This case study is modeled on a B2B operating process I worked with at SEPRO Eco Clean. To protect confidential company information, all transaction-level customer, supplier, pricing, revenue, inventory, and payment records used in this portfolio are synthetically generated. They do not represent actual SEPRO operational or financial records.

## Medallion architecture

This repository represents the **Gold Layer**.

The upstream Bronze/Silver cleaning and standardization work is maintained separately:

https://github.com/FatBoyIL/SEPRO_Cleaning_Data.git

The files here are included only to make the portfolio data model and business context easier to inspect on GitHub. Gold SQL should be understood as consuming cleaned Silver-layer tables rather than these raw CSV files directly.

## Folder structure

- sample/project/ - inventory, purchasing, shipment, fulfillment, QA, and intervention data.
- sample/shared/ - customer, product, supplier, warehouse, employee, and supplier-product master data.
- eference/ - project brief and TCO framework.
- manifest.csv - file-level mapping and purpose.

## Main business flow

Sales Order -> Inventory Availability -> Purchasing -> Shipment -> Customer Fulfillment

The sample files preserve the complete synthetic project subset rather than truncating rows, because the dataset is small and retaining full files keeps table relationships inspectable.

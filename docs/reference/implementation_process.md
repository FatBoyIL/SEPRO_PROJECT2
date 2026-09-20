# PROJECT 2 — INVENTORY & ORDER FULFILLMENT ANALYTICS

## 1. Mục tiêu của Project 2

Project 2 dùng để trả lời 3 câu hỏi chính:

1. **SKU nào đang có rủi ro thiếu hàng hoặc giao hàng không tốt?**
2. **Tình trạng hàng tồn tại thời điểm khách đặt hàng có liên hệ thế nào với Customer OTIF?**
3. **Supplier nào đang cân bằng tốt giữa độ tin cậy và tổng chi phí?**

Flow nghiệp vụ chính:

```text
Sales Order
    ↓
Inventory
    ↓
Purchasing
    ↓
Goods Receipt / QA
    ↓
Shipment
    ↓
Delivery
```

Project này không chỉ nhìn tồn kho.

Mục tiêu là nối được 3 góc nhìn:

```text
Inventory Risk
      +
Customer Fulfillment
      +
Supplier Performance
```

---

# 2. Các KPI chính của Project 2

Các KPI cần có trước khi phân tích:

```text
Stockout Rate
Inventory Coverage
Availability at Order
Customer OTIF
Supplier OTIF / On-time Receipt Proxy
Actual Lead Time
Late Receipt Days
Landed Cost
Estimated Holding Cost
Estimated TCO
```

Lưu ý:

- Customer OTIF phải tính ở **Sales Order grain**.
- Không tính Customer OTIF trực tiếp ở Shipment grain.
- Một Sales Order có thể được giao bằng nhiều shipment.
- Supplier OTIF hiện tại có thể chỉ là **proxy về đúng hạn** nếu source chưa có đủ quantity received.

---

# 3. Các Dimension được tái sử dụng

Project 2 không cần tạo lại toàn bộ dimension.

Sử dụng lại:

```text
gold.dim_date
gold.dim_product
gold.dim_supplier
gold.dim_warehouse
gold.dim_employee
gold.dim_customer
```

Trước khi chạy Project 2 cần kiểm tra các bảng này đã tồn tại.

File:

```text
00_SETUP/01_prerequisites_check.sql
```

Kết quả mong đợi:

```text
PASS
```

cho toàn bộ object cần thiết.

---

# 4. Quy trình thực hiện Project 2

Toàn bộ Project 2 đi theo flow:

```text
Fact
  ↓
Validate Fact
  ↓
Fact tiếp theo
  ↓
Mart
  ↓
Validate Mart
  ↓
KPI Validation
  ↓
STOP
  ↓
EDA / Statistical Analysis
```

Chưa làm Power BI ở bước này.

---

# 5. Bước 1 — Fact Inventory Snapshot

Folder:

```text
01_FACT_INVENTORY_SNAPSHOT
```

Chạy theo thứ tự:

```text
01_create.sql
02_load.sql
03_validate.sql
```

## 5.1 Grain

```text
1 row
=
1 date
+ 1 product
+ 1 warehouse
```

Ví dụ:

```text
2026-09-01
Product A
Warehouse HCM
```

chỉ được có 1 dòng.

## 5.2 Mục đích

Bảng này cho biết tồn kho tại từng ngày:

```text
on_hand_qty
on_order_qty
backlog_qty
available_qty
inventory_value_vnd
stockout_flag
reorder_point_qty
safety_stock_qty
```

## 5.3 Validation cần kiểm tra

```text
Không duplicate date + product + warehouse
Không mất row từ Silver
Product map đúng
Warehouse map đúng
Date map đúng
Không có quantity/value bất hợp lý
```

Chỉ đi tiếp khi validation ổn.

---

# 6. Bước 2 — Fact Inventory Movement

Folder:

```text
02_FACT_INVENTORY_MOVEMENT
```

Thứ tự:

```text
01_create.sql
02_load.sql
03_validate.sql
```

## 6.1 Grain

```text
1 row = 1 inventory movement
```

Ví dụ:

```text
Receipt
Issue
Transfer
Adjustment
```

## 6.2 Mục đích

Dùng để hiểu biến động tồn kho:

```text
movement_type
quantity_signed
unit_cost_vnd
reference_document
batch_no
expiry_date
```

Điểm quan trọng:

```text
quantity_signed < 0
```

không nhất thiết là lỗi.

Nó có thể là outbound hoặc consumption.

---

# 7. Bước 3 — Fact Purchase Order

Folder:

```text
03_FACT_PURCHASE_ORDER
```

## 7.1 Grain

```text
1 row = 1 Purchase Order
```

## 7.2 Dùng để phân tích

```text
Supplier
Buyer
PO Date
Expected Receipt Date
Actual Receipt Date
Currency
Payment Term
Incoterm
PO Status
```

## 7.3 KPI sẽ dùng sau này

Từ bảng này có thể tính:

```text
Actual Lead Time
=
Actual Receipt Date - PO Date
```

và:

```text
Late Receipt Days
=
Actual Receipt Date - Expected Receipt Date
```

---

# 8. Bước 4 — Fact Purchase Order Line

Folder:

```text
04_FACT_PURCHASE_ORDER_LINE
```

## 8.1 Grain

```text
1 row = 1 product line trong 1 Purchase Order
```

## 8.2 Measure quan trọng

```text
quantity_ordered
unit_price_local
merchandise_value_vnd
freight_cost_vnd
customs_cost_vnd
expedite_cost_vnd
contract_lead_time_days
```

## 8.3 Mục đích

Đây là bảng chính để phân tích chi phí purchasing.

Sau này:

```text
Landed Cost
=
Merchandise
+ Freight
+ Customs
+ Expedite
+ Quality Cost
```

---

# 9. Bước 5 — Fact Shipment

Folder:

```text
05_FACT_SHIPMENT
```

## 9.1 Grain

```text
1 row = 1 shipment
```

## 9.2 Dữ liệu chính

```text
sales_order_id
warehouse
ship_date
actual_delivery_date
shipping_method
freight_cost_vnd
partial_shipment_flag
tracking_no
```

## 9.3 Điểm cần nhớ

Một Sales Order có thể có:

```text
Shipment 1
Shipment 2
Shipment 3
```

Vì vậy:

```text
1 shipment != 1 completed order
```

Không được dùng từng shipment để kết luận OTIF cho order.

---

# 10. Bước 6 — Fact Shipment Line

Folder:

```text
06_FACT_SHIPMENT_LINE
```

## 10.1 Grain

```text
1 row = 1 product line trong 1 shipment
```

## 10.2 Mục đích

Dùng để biết:

```text
shipment nào
giao order line nào
giao bao nhiêu quantity
```

Đây là phần cần thiết để xử lý partial shipment.

---

# 11. Bước 7 — Fact Fulfillment

Folder:

```text
07_FACT_FULFILLMENT
```

## 11.1 Grain

```text
1 row = 1 Sales Order Line
```

## 11.2 Vì sao cần bảng này?

Ví dụ:

```text
Order Line A cần 100 pcs
```

nhưng giao thành:

```text
Shipment 1 = 40 pcs
Shipment 2 = 30 pcs
Shipment 3 = 30 pcs
```

Nếu nhìn từng shipment riêng:

```text
40 < 100
30 < 100
30 < 100
```

thì dễ kết luận sai là không giao đủ.

Phải cộng toàn bộ shipment của order line:

```text
40 + 30 + 30 = 100
```

Khi đó mới biết:

```text
line_complete_flag = 1
```

## 11.3 Field quan trọng

```text
quantity_ordered
quantity_shipped_total
first_ship_date
completion_delivery_date
promised_delivery_date
line_complete_flag
line_on_time_flag
late_delivery_days
```

---

# 12. Bước 8 — Mart Inventory Risk

Folder:

```text
08_MART_INVENTORY_RISK
```

## 12.1 Mục tiêu

Trả lời:

> SKU nào có rủi ro tồn kho và fulfillment cao?

## 12.2 Grain

```text
1 row = 1 product + 1 month
```

## 12.3 KPI chính

```text
Stockout Rate
Average On-hand
Average Available Qty
Average Inventory Value
Average Daily Demand
Inventory Coverage Days
Fulfillment Risk Rate
```

## 12.4 Công thức Stockout Rate

```text
Stockout Rate
=
Stockout SKU-Warehouse-Days
/
Observed SKU-Warehouse-Days
```

## 12.5 Inventory Coverage

Trong project hiện tại:

```text
Inventory Coverage Days
=
Average On-hand Qty
/
Average Daily Demand
```

Average Daily Demand đang dùng cửa sổ:

```text
60 days
```

Đây là analytical assumption.

Khi phân tích sau này cần kiểm tra xem 60 ngày có hợp lý hay không.

---

# 13. Bước 9 — Mart Order Availability OTIF

Folder:

```text
09_MART_ORDER_AVAILABILITY_OTIF
```

## 13.1 Business Question

> Tình trạng stock tại thời điểm order có liên hệ thế nào với Customer OTIF?

## 13.2 Grain

```text
1 row = 1 Sales Order
```

Đây là điểm cực kỳ quan trọng.

## 13.3 Availability Group

Mỗi order được đưa vào một nhóm:

```text
Available in full
Partially available
No stock
Missing snapshot
```

Logic line-level:

```text
Available in full:
available_qty >= quantity_ordered

Partially available:
0 < available_qty < quantity_ordered

No stock:
available_qty <= 0
```

## 13.4 Assumption quan trọng

Warehouse tại thời điểm order hiện chưa được xác định rõ.

Vì vậy project dùng:

```text
Network Availability
=
SUM(available_qty across warehouses)
```

tại:

```text
order_date + product
```

Phải ghi rõ đây là assumption.

Không được nói rằng đây là availability của một warehouse cụ thể.

---

# 14. Customer OTIF

Customer OTIF phải tính ở:

```text
Sales Order grain
```

Không phải Shipment grain.

## 14.1 Complete Flag

```text
Complete
=
Total Quantity Shipped
>=
Total Quantity Ordered
```

## 14.2 Final Delivery Date

Là ngày mà order đã được giao đủ.

## 14.3 On-Time Flag

```text
Final Delivery Date
<=
Requested Delivery Date
```

## 14.4 OTIF

```text
OTIF
=
Complete
AND
On-Time
```

## 14.5 Customer OTIF KPI

```text
Customer OTIF
=
Delivered Orders that are OTIF
/
Delivered Orders
```

---

# 15. Bước 10 — Mart Supplier Performance

Folder:

```text
10_MART_SUPPLIER_PERFORMANCE
```

## 15.1 Mục tiêu

Trả lời:

> Supplier nào cân bằng tốt reliability và total cost?

## 15.2 Grain

```text
1 row = 1 Purchase Order Line
```

## 15.3 Reliability metric

```text
Actual Lead Time
Late Receipt Days
On-time Receipt
Supplier OTIF Proxy
```

## 15.4 Supplier OTIF hiện tại

Source hiện tại chưa có đầy đủ:

```text
quantity received
```

để xác định true In-Full.

Vì vậy hiện tại:

```text
Supplier OTIF Proxy
=
Actual Receipt Date
<=
Expected Receipt Date
```

Phải gọi đúng là:

```text
OTIF Proxy / Receipt Timeliness
```

không gọi là Full Supplier OTIF nếu chưa có quantity received evidence.

---

# 16. Landed Cost

Công thức:

```text
Landed Cost
=
Merchandise Cost
+ Freight Cost
+ Customs Cost
+ Expedite Cost
+ Quality Cost
```

Quality Cost lấy từ:

```text
qa_events
```

Ví dụ:

```text
reject
rework
replacement
estimated_quality_cost_vnd
```

---

# 17. Estimated Holding Cost

Công thức:

```text
Estimated Holding Cost
=
Average Inventory Value
× Annual Holding Rate
× Holding Days
/ 365
```

Holding Rate lấy từ:

```text
inventory_policy_history
```

Lưu ý:

Source có tên:

```text
annual_holding_rate_pct
```

nhưng dữ liệu thực tế cần được kiểm tra xem đang lưu kiểu:

```text
0.20
```

hay:

```text
20
```

SQL hiện có logic normalize để hỗ trợ cả hai kiểu.

---

# 18. Estimated TCO

```text
Estimated TCO
=
Landed Cost
+
Estimated Holding Cost
```

Không nên tạo composite supplier score tùy ý nếu business chưa xác định trọng số.

Ví dụ không tự làm:

```text
Supplier Score
=
40% OTIF
+ 30% Cost
+ 30% Lead Time
```

nếu business chưa chốt weight.

Thay vào đó nên phân tích trade-off.

---

# 19. Bước 11 — KPI Validation

Folder:

```text
11_KPI_VALIDATION
```

Chạy lần lượt:

```text
01_validate_stockout_rate.sql
02_validate_inventory_coverage.sql
03_validate_customer_otif.sql
04_validate_availability_vs_otif.sql
05_validate_supplier_reliability.sql
06_validate_supplier_cost_tco.sql
07_validate_data_coverage.sql
08_project2_validation_stop_point.sql
```

Không cần chạy tất cả trong một file lớn.

Mỗi file trả lời một nhóm logic riêng.

---

# 20. Khi nào Project 2 được coi là hoàn thành phần Data Model?

Khi:

```text
Fact validation ổn
Mart validation ổn
KPI logic reconcile
Không có duplicate ngoài grain
Không có mapping error chưa giải thích
Partial shipment được xử lý đúng
OTIF tính đúng ở order grain
Supplier OTIF limitation được ghi rõ
Availability assumption được ghi rõ
```

Sau đó:

```text
STOP
```

Chưa làm Power BI.

Bước tiếp theo là:

```text
EDA
↓
Statistical Analysis
↓
Diagnostic Analysis
↓
Business Insight
↓
sau đó mới Power BI
```

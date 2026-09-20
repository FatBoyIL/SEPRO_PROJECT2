# PROJECT 2 — KẾ HOẠCH PHÂN TÍCH DỮ LIỆU

## 1. Khi nào bắt đầu file này?

Chỉ bắt đầu phân tích khi:

```text
Fact tables đã load
Fact validation ổn
Mart tables đã load
Mart validation ổn
KPI validation đã chạy
```

Tức là:

```text
Gold + KPI Validation
        ↓
BẮT ĐẦU PHÂN TÍCH
```

Chưa làm Power BI.

---

# 2. Mục tiêu của bước phân tích

Ở bước trước chúng ta chỉ xác nhận:

> Số có đúng không?

Ở bước này chúng ta mới hỏi:

> Dữ liệu đang nói điều gì?

Ba câu hỏi cần phân tích:

```text
Q1. SKU nào đang có stockout / fulfillment risk?

Q2. Availability at Order có liên hệ thế nào với Customer OTIF?

Q3. Supplier nào có trade-off tốt giữa reliability và total cost?
```

---

# 3. Nguyên tắc phân tích

Không bắt đầu bằng chart.

Flow nên là:

```text
Business Question
↓
Population / Grain
↓
Data Quality
↓
Descriptive Statistics
↓
Distribution
↓
Outlier Detection
↓
Segmentation
↓
Relationship Analysis
↓
Diagnostic Drill-down
↓
Business Insight
↓
Recommendation
```

---

# 4. PHASE 1 — Data Readiness Check

Trước khi phân tích cần xác nhận dữ liệu đủ để dùng.

## 4.1 Kiểm tra thời gian

Xác định:

```text
MIN date
MAX date
số tháng dữ liệu
```

Ví dụ:

```sql
SELECT
    MIN(month_start_date),
    MAX(month_start_date),
    COUNT(DISTINCT month_start_date)
FROM gold.mart_inventory_risk;
```

Mục tiêu:

Biết dữ liệu đang đại diện cho thời gian nào.

---

## 4.2 Kiểm tra population

Đếm:

```text
Products
Orders
Delivered Orders
PO Lines
Suppliers
Warehouses
```

Không phân tích tỷ lệ mà không biết denominator.

---

## 4.3 Kiểm tra missing evidence

Đặc biệt kiểm tra:

```text
Missing inventory snapshot
Missing annual holding rate
Missing inventory value
Missing actual receipt date
Incomplete orders
```

Nếu missing lớn:

Không được coi KPI là đại diện cho toàn bộ business population.

---

# 5. PHASE 2 — EDA cho Inventory Risk

Business Question:

> SKU nào đang có rủi ro tồn kho cao?

Bảng chính:

```text
gold.mart_inventory_risk
```

Các biến chính:

```text
stockout_rate
inventory_coverage_days
avg_network_on_hand_qty
avg_daily_demand_60d
fulfillment_risk_rate
avg_network_inventory_value_vnd
```

---

# 6. Bước 1 của Inventory Analysis — Descriptive Statistics

Đầu tiên tính:

```text
COUNT
MIN
MAX
AVG
MEDIAN
P25
P75
P90
```

cho:

```text
Stockout Rate
Inventory Coverage Days
Demand
Inventory Value
Fulfillment Risk Rate
```

Không nên chỉ nhìn AVG.

Ví dụ:

```text
Coverage Days

Min       = 0
P25       = 8
Median    = 21
P75       = 48
P90       = 95
Max       = 400
```

AVG có thể bị kéo lên bởi một số SKU có tồn kho rất lớn.

---

# 7. Bước 2 — Distribution Analysis

Kiểm tra distribution của:

```text
inventory_coverage_days
stockout_rate
avg_daily_demand_60d
inventory_value
```

Mục tiêu:

Biết dữ liệu:

```text
normal?
right-skewed?
long-tail?
zero-inflated?
```

Ví dụ Coverage thường có thể right-skew:

```text
5
10
12
16
20
25
31
45
300
```

Khi đó:

```text
Median
Percentile
IQR
```

thường hữu ích hơn chỉ dùng average.

---

# 8. Bước 3 — IQR Outlier Detection

IQR dùng để phát hiện observation bất thường.

## 8.1 Công thức

```text
Q1 = 25th percentile
Q3 = 75th percentile

IQR = Q3 - Q1

Lower Bound
= Q1 - 1.5 × IQR

Upper Bound
= Q3 + 1.5 × IQR
```

---

## 8.2 Có thể áp dụng IQR cho

```text
Inventory Coverage Days
Inventory Value
Average Daily Demand
Actual Lead Time
Late Receipt Days
Landed Cost
Estimated TCO
```

---

## 8.3 Không tự xóa outlier

Ví dụ:

```text
Coverage = 280 days
```

IQR đánh dấu là outlier.

Không có nghĩa là dữ liệu sai.

Cần điều tra:

```text
SKU slow-moving?
Safety stock quá cao?
Demand giảm?
MOQ lớn?
Strategic stock?
Data error?
```

Outlier Detection là:

```text
Flag
↓
Investigate
↓
Classify
```

không phải:

```text
Flag
↓
Delete
```

---

# 9. Bước 4 — SKU Risk Segmentation

Sau khi hiểu distribution, chia SKU thành các nhóm.

Ví dụ concept:

```text
High Stockout + Low Coverage
→ Shortage Risk

Low Stockout + High Coverage
→ Possible Overstock

High Stockout + High Demand
→ Priority Replenishment Risk

High Coverage + Low Demand
→ Slow-moving / Working Capital Risk
```

Không cần đặt threshold tùy ý ngay.

Threshold nên xem từ:

```text
Business target
hoặc
Percentile của data
```

Ví dụ:

```text
Low Coverage
=
Coverage < P25
```

hoặc theo business SLA nếu có.

---

# 10. Bước 5 — Pareto Analysis cho SKU Risk

Mục tiêu:

> Một nhóm nhỏ SKU có đang tạo phần lớn stockout hay không?

Thực hiện:

```text
1. Aggregate stockout days theo Product
2. Sort giảm dần
3. Tính cumulative stockout days
4. Tính cumulative %
```

Ví dụ:

```text
20% SKU
→ 72% stockout days
```

Nếu xảy ra:

đây là dấu hiệu rủi ro đang tập trung.

Nhưng không cố ép dữ liệu thành quy tắc 80/20.

---

# 11. Bước 6 — Trend Analysis

Phân tích theo tháng:

```text
Stockout Rate by Month
Coverage by Month
Fulfillment Risk by Month
```

Mục tiêu:

Phân biệt:

```text
một incident ngắn hạn
```

với:

```text
một vấn đề kéo dài
```

Ví dụ:

```text
Jan  2%
Feb  3%
Mar  9%
Apr  13%
May  15%
```

đáng chú ý hơn một tháng tăng đơn lẻ.

---

# 12. PHASE 3 — Availability at Order vs Customer OTIF

Business Question:

> Khi order được tạo mà stock không đủ, OTIF có thấp hơn không?

Bảng:

```text
gold.mart_order_availability_otif
```

Các nhóm:

```text
Available in full
Partially available
No stock
Missing snapshot
```

---

# 13. Bước 1 — Kiểm tra sample size

Trước khi so OTIF:

```text
COUNT orders by availability_group
```

Ví dụ:

```text
Available in full      500
Partially available     90
No stock                12
```

Nếu nhóm No Stock chỉ có:

```text
n = 2
```

thì không nên kết luận mạnh.

---

# 14. Bước 2 — So sánh Customer OTIF

Tính:

```text
OTIF Rate
=
OTIF Orders
/
Delivered Orders
```

theo từng availability group.

Ví dụ:

```text
Available in full      91%
Partially available    74%
No stock               52%
```

Điều này cho thấy:

```text
association
```

giữa availability và OTIF.

Không được nói:

> thiếu hàng gây ra OTIF thấp

chỉ từ dữ liệu quan sát này.

Có thể còn:

```text
Supplier delay
Warehouse
Carrier
Order complexity
Customer requested date
Product characteristics
```

---

# 15. Bước 3 — Proportion Comparison

Vì OTIF là binary:

```text
0 / 1
```

có thể so tỷ lệ giữa các group.

Ví dụ:

```text
Available in full vs No stock
```

Có thể dùng:

```text
Difference in proportion
Confidence Interval
Chi-square test
```

hoặc Fisher Exact khi sample nhỏ.

Mục tiêu không phải chỉ lấy p-value.

Cần xem cả:

```text
effect size
```

Ví dụ:

```text
OTIF difference = 24 percentage points
```

có ý nghĩa business rõ hơn chỉ nói:

```text
p < 0.05
```

---

# 16. Bước 4 — Drill-down các order bị fail OTIF

Lọc:

```text
otif_flag = 0
```

sau đó kiểm tra:

```text
availability_group
days_late
product
customer
shipment count
partial shipment
```

Mục tiêu:

Tìm pattern.

Ví dụ:

```text
OTIF fail tập trung ở:
- No stock
- nhiều partial shipment
- một số product family
```

Đây là diagnostic analysis.

---

# 17. PHASE 4 — Supplier Reliability Analysis

Bảng:

```text
gold.mart_supplier_performance
```

Biến chính:

```text
supplier_otif_proxy_flag
actual_lead_time_days
late_receipt_days
quality_cost_vnd
landed_cost_vnd
estimated_holding_cost_vnd
estimated_tco_vnd
```

---

# 18. Bước 1 — Supplier Sample Size

Trước khi so supplier:

```text
PO line count
Received PO line count
```

Supplier có:

```text
2 PO
```

không nên so ngang với supplier có:

```text
200 PO
```

mà không nói rõ sample size.

---

# 19. Bước 2 — Reliability Distribution

Không chỉ tính average.

Cho:

```text
Actual Lead Time
Late Receipt Days
```

hãy xem:

```text
Median
P75
P90
IQR
Max
```

Ví dụ:

Supplier A:

```text
Median Lead Time = 12 days
P90 = 15 days
```

Supplier B:

```text
Median Lead Time = 10 days
P90 = 38 days
```

B có average tốt nhưng tail risk cao.

Đây là insight quan trọng.

---

# 20. Bước 3 — IQR cho Supplier Delay

Áp dụng IQR cho:

```text
actual_lead_time_days
late_receipt_days
```

theo:

```text
toàn bộ dataset
```

và nếu sample đủ lớn:

```text
theo supplier
```

Mục tiêu:

Tìm PO có delay bất thường.

Sau đó drill-down:

```text
Supplier
Product
PO
Expedite Cost
Quality Event
```

---

# 21. Bước 4 — Supplier Cost Analysis

Không so supplier bằng unit price đơn thuần.

So:

```text
Merchandise Cost
Freight
Customs
Expedite
Quality Cost
Holding Cost
TCO
```

Một supplier giá mua thấp có thể có:

```text
Lead Time dài
Expedite Cost cao
Quality Cost cao
Holding Cost cao
```

và cuối cùng:

```text
TCO cao hơn
```

---

# 22. Bước 5 — Trade-off Analysis

Tạo analytical matrix:

```text
Reliability
vs
Total Cost
```

Ví dụ concept:

```text
                 Low Cost        High Cost

High Reliability    A                B

Low Reliability     C                D
```

Không tự gọi A là "best supplier".

Mục tiêu là trình bày trade-off để business quyết định.

---

# 23. Bước 6 — Supplier Pareto

Có thể chạy Pareto trên:

```text
Late PO Count
Expedite Cost
Quality Cost
Total TCO
```

Ví dụ:

```text
3 suppliers
→ 68% total expedite cost
```

thì đó là nhóm cần investigate trước.

---

# 24. PHASE 5 — Relationship Analysis

Sau descriptive analysis có thể phân tích relationship.

Một số cặp hợp lý:

```text
Inventory Coverage
vs
Stockout Rate

Inventory Coverage
vs
Fulfillment Risk

Availability Group
vs
OTIF

Lead Time
vs
Expedite Cost

Late Receipt Days
vs
Quality / TCO
```

---

# 25. Correlation dùng khi nào?

Nếu biến numeric:

```text
Coverage Days
Stockout Rate
Lead Time
Cost
```

có thể dùng correlation.

Vì dữ liệu business thường:

```text
skewed
outlier-heavy
non-normal
```

nên:

```text
Spearman correlation
```

thường phù hợp để exploratory analysis hơn Pearson trong nhiều trường hợp.

Nhưng correlation không chứng minh causality.

---

# 26. PHASE 6 — Diagnostic Analysis

Sau khi tìm thấy vấn đề, hỏi tiếp:

```text
WHY?
```

Ví dụ phát hiện:

```text
Product A có Stockout Rate cao
```

Drill-down:

```text
Demand tăng?
Coverage thấp?
PO lead time dài?
Supplier thường trễ?
Expedite cost tăng?
Reorder point quá thấp?
```

Đây là điểm Project 2 trở thành Business Analysis thay vì chỉ Reporting.

---

# 27. Insight Log

Trong quá trình phân tích nên tạo một bảng ghi insight.

Format:

```text
Observation
Evidence
Possible Explanation
Limitation
Business Impact
Next Check
```

Ví dụ:

```text
Observation:
No Stock group có OTIF thấp hơn.

Evidence:
OTIF 54% vs 90% ở Available in Full.

Possible Explanation:
Order không có đủ stock khi nhận đơn.

Limitation:
Warehouse allocation chưa xác định;
availability đang dùng network level.

Business Impact:
Có thể ảnh hưởng service level.

Next Check:
Drill-down theo Product / Month / Shipment Count.
```

---

# 28. Không được kết luận quá mức

Các câu nên dùng:

```text
associated with
shows a pattern
concentrated in
higher/lower in this dataset
requires further investigation
```

Tránh:

```text
causes
proves
definitely because
```

nếu chưa có causal design.

---

# 29. SQL dùng cho việc gì?

SQL phù hợp cho:

```text
Population
Aggregation
KPI
Grouping
Percentile
Ranking
Pareto
Drill-down
Data extraction
```

Ví dụ:

```text
P25 / Median / P75
```

có thể tính bằng SQL Server với:

```text
PERCENTILE_CONT()
```

---

# 30. Python dùng cho việc gì?

Python nên dùng khi cần:

```text
Distribution plot
Boxplot
Histogram
IQR automation
Correlation matrix
Statistical tests
Confidence interval
Sensitivity analysis
```

Flow nên là:

```text
SQL
→ tạo dataset analysis-ready

Python
→ statistical / diagnostic analysis
```

Không chuyển toàn bộ logic business sang Python nếu SQL đã xử lý rõ.

---

# 31. Thứ tự phân tích đề xuất

Thực hiện đúng thứ tự này:

```text
STEP 1
Data readiness

STEP 2
Descriptive statistics

STEP 3
Distribution

STEP 4
Percentile

STEP 5
IQR / Outlier detection

STEP 6
SKU risk segmentation

STEP 7
Pareto analysis

STEP 8
Trend analysis

STEP 9
Availability vs OTIF comparison

STEP 10
Statistical comparison

STEP 11
Supplier reliability analysis

STEP 12
Supplier cost / TCO analysis

STEP 13
Trade-off analysis

STEP 14
Diagnostic drill-down

STEP 15
Insight log

STEP 16
Business findings
```

Sau đó mới:

```text
Power BI
```

---

# 32. Output cuối cùng của phần phân tích

Trước khi qua Power BI, bạn nên có:

```text
1. KPI baseline
2. Distribution summary
3. Percentile table
4. Outlier table
5. SKU risk segmentation
6. SKU Pareto table
7. Availability vs OTIF comparison
8. Statistical comparison result
9. Supplier reliability table
10. Supplier cost / TCO table
11. Supplier trade-off analysis
12. Diagnostic findings
13. Insight log
14. Business recommendations
15. Analysis limitations
```

---

# 33. Definition of Done — Analytical Stage

Phân tích Project 2 hoàn thành khi bạn có thể trả lời rõ:

## Q1

```text
SKU nào đang có rủi ro?
Rủi ro là stockout, coverage hay fulfillment?
Rủi ro tập trung ở đâu?
```

## Q2

```text
Availability tại thời điểm order khác nhau thì OTIF thay đổi thế nào?
Sample size có đủ không?
Mức chênh lệch bao nhiêu?
Đây là association hay causal evidence?
```

## Q3

```text
Supplier nào có reliability ổn định?
Supplier nào có tail delay lớn?
Supplier nào làm tăng expedite / quality / holding cost?
Trade-off reliability và TCO như thế nào?
```

Khi trả lời được 3 nhóm câu hỏi này bằng dữ liệu đã kiểm chứng:

```text
Project 2 Analysis
=
READY
```

Lúc đó mới thiết kế Power BI để truyền đạt insight.

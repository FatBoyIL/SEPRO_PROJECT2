# Project 2 — Review Guide

Project 2 có nhiều grain khác nhau nên ngày mai khi kiểm tra, hãy luôn hỏi “một dòng của bảng này đại diện cho cái gì?” trước khi đọc KPI.

## 1. Grain cần nhớ

- `mart_inventory_risk`: **Product × Month**.
- `fact_inventory_snapshot`: **Date × Product × Warehouse**.
- `mart_order_availability_otif`: **1 Sales Order**.
- `fact_fulfillment`: **1 Sales Order Line**.
- `mart_supplier_performance`: **1 PO Line**.

Nếu join trực tiếp các bảng khác grain rồi SUM, rất dễ tạo fan-out.

## 2. `00_Readiness_Profile.sql`

Kiểm tra trước:

- thời gian dữ liệu inventory kéo dài bao nhiêu tháng;
- có bao nhiêu product;
- có bao nhiêu Sales Order và bao nhiêu order đã delivered;
- missing inventory snapshot có nhiều không;
- sample size của từng availability group;
- supplier performance có bao nhiêu PO line, supplier, received line;
- bao nhiêu PO line thiếu inventory value, holding rate hoặc TCO.

Nếu một availability group chỉ có vài order thì không nên diễn giải OTIF difference quá mạnh.

## 3. `01_Inventory_Risk_EDA.sql`

Mục tiêu là hiểu distribution trước khi gắn nhãn High/Low.

Đọc các metric:

- Stockout Rate
- Inventory Coverage Days
- Average Daily Demand 60d
- Inventory Value
- Fulfillment Risk Rate

Đừng chỉ nhìn Average. Hãy xem Median và P90 để biết distribution có tail hay không.

Monthly trend dùng weighted numerator/denominator, không average các rate của từng SKU. Đây là điểm quan trọng khi giải thích với interviewer.

## 4. `02_Warehouse_SKU_Risk.sql`

File này bổ sung đúng requirement Product / Category / Warehouse / Month.

Result set đầu cho biết một SKU ở một kho và một tháng có:

- bao nhiêu ngày được quan sát;
- bao nhiêu ngày stockout;
- stockout rate;
- average on-hand / available / backlog;
- average inventory value.

Result set thứ hai nhìn tổng warehouse exposure.

Khi thấy warehouse có stockout rate cao, chưa vội kết luận kho vận hành kém. Cần hỏi tiếp SKU mix, demand mix, replenishment và allocation policy.

## 5. `03_SKU_Risk_Segmentation_Pareto.sql`

Threshold dùng percentile của dataset thay vì cutoff tự nghĩ ra.

Các flag dùng để ưu tiên điều tra:

- `shortage_risk_flag`: stockout cao + coverage thấp.
- `priority_replenishment_flag`: stockout cao + demand cao.
- `working_capital_risk_flag`: coverage cao + demand không cao.
- `possible_overstock_flag`: stockout thấp + coverage cao.

Flag không phải verdict. Nó là cách phân nhóm để tìm SKU cần xem trước.

Pareto ở phần cuối phải tính trên **toàn bộ product population**, sau đó mới hỏi top 20% product đang tạo bao nhiêu stockout exposure. Không ép kết quả thành 80/20.

## 6. `04_Availability_vs_OTIF.sql`

Customer OTIF phải đọc ở Sales Order grain.

Denominator là **Delivered Orders**.

Các nhóm availability:

- Available in full
- Partially available
- No stock
- có thể có Missing snapshot nếu source thiếu evidence

Hãy kiểm tra:

- sample size từng nhóm;
- OTIF rate từng nhóm;
- gap so với Available in full;
- những order failed OTIF là incomplete hay simply late.

Nếu No stock có OTIF thấp hơn rõ rệt, kết luận đúng là availability thấp **đi cùng** service level thấp hơn trong dữ liệu quan sát, chưa phải causal proof.

## 7. `05_SKU_to_Late_Fulfillment_Diagnostic.sql`

File này nối đúng business flow:

`Order Line → Availability at Order → Fulfillment → Late / Incomplete`

Availability được tổng hợp network-wide vì source không chỉ định allocated warehouse cho order line.

Hãy kiểm tra theo Product + Availability Group:

- số order line;
- số line có fulfillment evidence;
- số late/incomplete line;
- fulfillment risk rate.

Sau đó mở detail list để thấy order/line cụ thể nào bị ảnh hưởng. Đây là bước giúp chuyển từ KPI tổng sang action list.

## 8. `06_Supplier_Reliability_TCO.sql`

Đây là supplier-level view.

Không gọi `supplier_otif_proxy_flag` là true OTIF. Source thiếu `quantity_received`, nên nó chỉ cho biết receipt có on-time hay không.

Đọc cùng:

- sample size / received PO lines;
- Median/P90 actual lead time;
- P90 late receipt days;
- merchandise/freight/customs;
- expedite cost;
- quality cost;
- landed cost;
- estimated holding cost;
- estimated TCO.

Không chọn “best supplier” chỉ vì TCO thấp hoặc timeliness cao. Project yêu cầu thể hiện trade-off.

## 9. `07_Supplier_Product_Diagnostic.sql`

File này kiểm tra Supplier × Product.

Hãy xem cùng một SKU có nhiều supplier hay không. Nếu có, so:

- timeliness proxy;
- Median/P90 lead time;
- landed cost per ordered unit;
- expedite / quality cost;
- estimated TCO per covered unit;
- TCO coverage rate.

Nếu TCO coverage thấp, không dùng con số TCO để kết luận mạnh.

## 10. `99_Project2_Conclusion.sql`

Khi review hoặc phỏng vấn, trình bày theo ba câu hỏi:

1. SKU và warehouse nào có stockout / fulfillment exposure cao.
2. Availability group nào có OTIF khác biệt.
3. Supplier nào có reliability/cost trade-off đáng chú ý.

Điểm nên nhấn mạnh là bạn giữ đúng grain và không biến proxy thành KPI thật.

## 11. Checklist hoàn thành

- [ ] Fact/Mart/KPI validation PASS.
- [ ] Biết rõ grain của 4 nhóm dữ liệu chính.
- [ ] Stockout được xem từ daily snapshot, không chỉ month-end.
- [ ] Có warehouse-level diagnostic.
- [ ] Coverage được đọc cùng Stockout Rate.
- [ ] OTIF được tính ở order grain.
- [ ] Partial shipment không làm double count order.
- [ ] Có SKU → late/incomplete drill-down.
- [ ] Supplier timeliness proxy được gọi đúng tên.
- [ ] Không claim true Supplier OTIF khi thiếu quantity_received.
- [ ] Supplier × Product đã được xem.
- [ ] TCO coverage được kiểm tra trước khi diễn giải.
- [ ] Availability vs OTIF chỉ được nói là association.

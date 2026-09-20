# Project 2 — Inventory & Order Fulfillment Analytics

Project 2 bắt đầu sau khi khách đã đặt Sales Order. Bài toán chuyển từ acquisition sang vận hành: **làm sao có đủ hàng để phục vụ đúng hạn nhưng không giữ tồn kho quá mức, đồng thời không chọn supplier chỉ vì giá mua thấp**.

Ba câu hỏi chính là: SKU nào đang có stockout và fulfillment risk, availability khi nhận order có liên hệ thế nào với Customer OTIF, và supplier nào có trade-off hợp lý giữa reliability và total cost.

Inventory risk được nhìn ở nhiều grain. `gold.mart_inventory_risk` cho góc nhìn Product × Month ở network level, còn `gold.fact_inventory_snapshot` cho phép drill-down tới Product × Warehouse × Date. Tôi không chỉ nhìn tồn kho cuối tháng vì stockout là hiện tượng theo ngày; warehouse-level diagnostic giúp biết rủi ro đang tập trung ở kho nào thay vì chỉ biết network tổng đang thiếu.

Inventory Coverage được đọc cùng Stockout Rate và demand. Stockout Rate cho biết thiếu hàng đã xảy ra thường xuyên thế nào, còn Coverage cho biết lượng hàng hiện có đủ phục vụ nhu cầu trong bao lâu. Hai KPI này cần đi cùng fulfillment evidence để biết thiếu hàng có thực sự gắn với late/incomplete delivery hay không.

Customer OTIF được tính ở **Sales Order grain**, không phải Shipment grain, vì một order có thể giao nhiều lần. Order chỉ đạt OTIF khi giao đủ và final delivery date không trễ hơn requested date. Availability tại order được chia thành Available in full, Partially available và No stock. Kết quả chỉ được diễn giải là association vì OTIF còn chịu ảnh hưởng của logistics, warehouse, supplier và customer request date.

Supplier analysis không tạo một “điểm tổng” tùy ý. Tôi nhìn riêng timeliness, lead time, expedite cost, quality cost, landed cost và estimated TCO. Database hiện không có `quantity_received` ở PO line, vì vậy `supplier_otif_proxy_flag` chỉ phản ánh **receipt timeliness**, chưa phải true In-Full OTIF. Đây là limitation phải nói rõ thay vì gọi proxy là OTIF thật.

Supplier cũng được drill-down theo **Supplier × Product** vì một supplier có thể tốt với SKU này nhưng không tốt với SKU khác. TCO được đọc kèm coverage vì estimated holding cost chỉ có ý nghĩa khi inventory value và holding-rate evidence đầy đủ.

Project 2 cuối cùng phải giúp business biết SKU/kho nào cần ưu tiên replenishment hoặc policy review, availability issue nào đang đi cùng OTIF thấp, và supplier/product combination nào cần cân nhắc giữa reliability và total cost.

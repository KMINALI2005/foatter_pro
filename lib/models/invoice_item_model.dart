class InvoiceItem {
  int? id;
  int? invoiceId;
  String productName;
  double quantity;
  double price;
  // لقد قمت بإزالة 'total' لأنه يمكن حسابه دائماً (quantity * price)
  // وهذا يقلل من تكرار البيانات ويمنع الأخطاء.
  // سنقوم بحسابه عند الحاجة بدلاً من تخزينه.
  String? notes;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.notes,
  });

  // دالة getter لحساب الإجمالي تلقائياً
  double get total => quantity * price;

  // ==== تم التعديل هنا ====
  // تم تغيير المفاتيح لتطابق أسماء الأعمدة في قاعدة البيانات (snake_case)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      // لا نقوم بتخزين 'total' في قاعدة البيانات
      'notes': notes,
    };
  }

  // ==== تم التعديل هنا ====
  // تم تغيير المفاتيح لتطابق أسماء الأعمدة عند القراءة من قاعدة البيانات
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productName: map['product_name'],
      // استخدام (as num).toDouble() لضمان تحويل النوع بشكل آمن
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      notes: map['notes'],
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    String? productName,
    double? quantity,
    double? price,
    String? notes,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }
}

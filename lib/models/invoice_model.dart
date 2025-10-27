import 'invoice_item_model.dart';

class Invoice {
  int? id;
  String invoiceNumber;
  DateTime invoiceDate;
  String customerName;
  double amountPaid;
  String? notes;
  double previousBalance;

  // هذه الحقول مهمة جداً لقراءة البيانات من قاعدة البيانات
  final DateTime createdAt;
  DateTime updatedAt;

  // قائمة المنتجات، سيتم تعبئتها من خلال database_service
  List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    this.amountPaid = 0.0,
    this.notes,
    this.previousBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [], // القيمة الافتراضية هي قائمة فارغة
  });

  // ====================================================================
  // ==== Getters لحساب القيم بدلاً من تخزينها (هذا هو الأسلوب الصحيح) ====
  // ====================================================================

  // 1. حساب إجمالي الفاتورة الحالية (مجموع أسعار المنتجات)
  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  // 2. الإجمالي الكلي مع الرصيد السابق
  double get totalWithPrevious => total + previousBalance;

  // 3. الرصيد المتبقي
  double get remainingBalance => totalWithPrevious - amountPaid;

  // 4. حالة الفاتورة (مدفوعة، جزئية، غير مدفوعة)
  String get status {
    if (remainingBalance <= 0) {
      return 'مدفوعة';
    } else if (amountPaid > 0 && amountPaid < totalWithPrevious) {
      return 'مدفوعة جزئياً';
    } else {
      return 'غير مدفوعة';
    }
  }

  // ====================================================================
  // ==== دوال التحويل لتتطابق مع قاعدة البيانات (snake_case) ====
  // ====================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'customer_name': customerName,
      'amount_paid': amountPaid,
      'notes': notes,
      'previous_balance': previousBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      customerName: map['customer_name'],
      amountPaid: (map['amount_paid'] as num).toDouble(),
      notes: map['notes'],
      previousBalance: (map['previous_balance'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      // `items` لا يتم جلبها من هنا، بل من `database_service`
      items: [], 
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? customerName,
    double? amountPaid,
    String? notes,
    double? previousBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerName: customerName ?? this.customerName,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      previousBalance: previousBalance ?? this.previousBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

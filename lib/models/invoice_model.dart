import 'invoice_item_model.dart';

class Invoice {
  int? id;
  String invoiceNumber;
  DateTime invoiceDate;
  String customerName;
  String status;
  double total;
  double discount;
  double grandTotal;
  double amountPaid;
  double remainingBalance;
  List<InvoiceItem> items;
  String? notes;
  // New fields for auditing
  double? previousBalance;
  double? totalWithPrevious;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.status,
    required this.total,
    this.discount = 0.0,
    required this.grandTotal,
    this.amountPaid = 0.0,
    required this.remainingBalance,
    required this.items,
    this.notes,
    this.previousBalance,
    this.totalWithPrevious,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'customerName': customerName,
      'status': status,
      'total': total,
      'discount': discount,
      'grandTotal': grandTotal,
      'amountPaid': amountPaid,
      'remainingBalance': remainingBalance,
      'notes': notes,
      'previousBalance': previousBalance,
      'totalWithPrevious': totalWithPrevious,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      customerName: map['customerName'],
      status: map['status'],
      total: map['total'],
      discount: map['discount'],
      grandTotal: map['grandTotal'],
      amountPaid: map['amountPaid'],
      remainingBalance: map['remainingBalance'],
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(item))
              .toList() ??
          [],
      notes: map['notes'],
      previousBalance: map['previousBalance'],
      totalWithPrevious: map['totalWithPrevious'],
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? customerName,
    String? status,
    double? total,
    double? discount,
    double? grandTotal,
    double? amountPaid,
    double? remainingBalance,
    List<InvoiceItem>? items,
    String? notes,
    double? previousBalance,
    double? totalWithPrevious,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      previousBalance: previousBalance ?? this.previousBalance,
      totalWithPrevious: totalWithPrevious ?? this.totalWithPrevious,
    );
  }
}

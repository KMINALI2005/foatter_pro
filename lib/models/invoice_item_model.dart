class InvoiceItem {
  int? id;
  int? invoiceId;
  String productName;
  double quantity;
  double price;
  double total;
  String? notes;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
      'notes': notes,
    };
  }

    factory InvoiceItem.fromMap(Map<String, dynamic> map) {

      return InvoiceItem(

        id: map['id'],

        invoiceId: map['invoiceId'],

        productName: map['productName'],

        quantity: map['quantity'],

        price: map['price'],

        total: map['total'],

        notes: map['notes'],

      );

    }

  

    InvoiceItem copyWith({

      int? id,

      int? invoiceId,

      String? productName,

      double? quantity,

      double? price,

      double? total,

      String? notes,

    }) {

      return InvoiceItem(

        id: id ?? this.id,

        invoiceId: invoiceId ?? this.invoiceId,

        productName: productName ?? this.productName,

        quantity: quantity ?? this.quantity,

        price: price ?? this.price,

        total: total ?? this.total,

        notes: notes ?? this.notes,

      );

    }

  }

  
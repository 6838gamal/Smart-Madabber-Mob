enum TransactionType {
  purchase,
  consume,
  sale,
  adjustment;

  String get label {
    switch (this) {
      case purchase:
        return 'Purchase Entry';
      case consume:
        return 'Consumption';
      case sale:
        return 'Sales Exit';
      case adjustment:
        return 'Stock Adjustment';
    }
  }

  String get labelAr {
    switch (this) {
      case purchase:
        return 'فاتورة شراء';
      case consume:
        return 'استهلاك';
      case sale:
        return 'فاتورة بيع';
      case adjustment:
        return 'تسوية مخزون';
    }
  }

  String get emoji {
    switch (this) {
      case purchase:
        return '📦';
      case consume:
        return '⚡';
      case sale:
        return '💰';
      case adjustment:
        return '🔧';
    }
  }
}

class Transaction {
  final String id;
  final String resourceId;
  final TransactionType type;
  final double quantity;
  final double price;
  final DateTime date;
  final String note;

  const Transaction({
    required this.id,
    required this.resourceId,
    required this.type,
    required this.quantity,
    this.price = 0.0,
    required this.date,
    this.note = '',
  });

  bool get affectsQuantityPositively =>
      type == TransactionType.purchase || type == TransactionType.adjustment;

  double get signedQuantity =>
      affectsQuantityPositively ? quantity : -quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'type': type.name,
        'quantity': quantity,
        'price': price,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.consume,
        ),
        quantity: (json['quantity'] as num).toDouble(),
        price: (json['price'] as num? ?? 0).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );

  Transaction copyWith({
    String? id,
    String? resourceId,
    TransactionType? type,
    double? quantity,
    double? price,
    DateTime? date,
    String? note,
  }) =>
      Transaction(
        id: id ?? this.id,
        resourceId: resourceId ?? this.resourceId,
        type: type ?? this.type,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        date: date ?? this.date,
        note: note ?? this.note,
      );
}

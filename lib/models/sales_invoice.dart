import 'package:flutter/foundation.dart';

/// حالة الفاتورة
enum InvoiceStatus { draft, confirmed, cancelled }

/// حالة السداد
enum PaymentStatus { unpaid, partial, paid }

/// بند واحد في الفاتورة
@immutable
class InvoiceLine {
  final String id;
  final String itemName;      // اسم الصنف (نصي مؤقتاً — سيصبح itemId لاحقاً)
  final String? description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;   // 0-100
  final double taxPercent;        // 0-100

  const InvoiceLine({
    required this.id,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.taxPercent = 0,
  });

  /// الإجمالي قبل الخصم والضريبة
  double get grossTotal => quantity * unitPrice;

  /// قيمة الخصم
  double get discountAmount => grossTotal * (discountPercent / 100);

  /// الصافي بعد الخصم
  double get netBeforeTax => grossTotal - discountAmount;

  /// قيمة الضريبة
  double get taxAmount => netBeforeTax * (taxPercent / 100);

  /// الإجمالي النهائي للبند
  double get total => netBeforeTax + taxAmount;

  InvoiceLine copyWith({
    String? id,
    String? itemName,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
    double? taxPercent,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountPercent': discountPercent,
        'taxPercent': taxPercent,
      };

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
        id: json['id'] as String,
        itemName: json['itemName'] as String,
        description: json['description'] as String?,
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      );
}

/// فاتورة بيع
@immutable
class SalesInvoice {
  final String id;
  final String invoiceNumber;       // INV-0001
  final String customerId;
  final String customerName;        // snapshot للعرض السريع
  final DateTime date;
  final DateTime? dueDate;
  final List<InvoiceLine> lines;
  final String? notes;

  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final double paidAmount;

  /// نسبة خصم عامة على الفاتورة (0-100)
  final double invoiceDiscountPercent;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const SalesInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    this.dueDate,
    required this.lines,
    this.notes,
    this.status = InvoiceStatus.draft,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paidAmount = 0,
    this.invoiceDiscountPercent = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // ── الحسابات ────────────────────────────────────────────────
  double get subtotal =>
      lines.fold(0.0, (s, l) => s + l.grossTotal);

  double get linesDiscountTotal =>
      lines.fold(0.0, (s, l) => s + l.discountAmount);

  double get linesTaxTotal =>
      lines.fold(0.0, (s, l) => s + l.taxAmount);

  double get netBeforeInvoiceDiscount =>
      subtotal - linesDiscountTotal;

  double get invoiceDiscountAmount =>
      netBeforeInvoiceDiscount * (invoiceDiscountPercent / 100);

  double get totalTax => linesTaxTotal;

  double get grandTotal =>
      netBeforeInvoiceDiscount - invoiceDiscountAmount + totalTax;

  double get remainingAmount => grandTotal - paidAmount;

  bool get isFullyPaid => remainingAmount.abs() < 0.01 && grandTotal > 0;

  bool get isOverdue {
    if (dueDate == null || isFullyPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  SalesInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    DateTime? date,
    DateTime? dueDate,
    List<InvoiceLine>? lines,
    String? notes,
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    double? paidAmount,
    double? invoiceDiscountPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      invoiceDiscountPercent:
          invoiceDiscountPercent ?? this.invoiceDiscountPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'notes': notes,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
        'paidAmount': paidAmount,
        'invoiceDiscountPercent': invoiceDiscountPercent,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory SalesInvoice.fromJson(Map<String, dynamic> json) => SalesInvoice(
        id: json['id'] as String,
        invoiceNumber: json['invoiceNumber'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        date: DateTime.parse(json['date'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        lines: (json['lines'] as List)
            .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        status: InvoiceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => InvoiceStatus.draft,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == json['paymentStatus'],
          orElse: () => PaymentStatus.unpaid,
        ),
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        invoiceDiscountPercent:
            (json['invoiceDiscountPercent'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

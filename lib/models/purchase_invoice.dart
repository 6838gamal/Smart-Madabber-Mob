import 'package:flutter/foundation.dart';
import 'sales_invoice.dart' show InvoiceLine; // إعادة استخدام InvoiceLine

enum PurchaseInvoiceStatus { draft, confirmed, cancelled }
enum PurchasePaymentStatus { unpaid, partial, paid }

@immutable
class PurchaseInvoice {
  final String id;
  final String invoiceNumber;   // PUR-0001
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final DateTime? dueDate;
  final List<InvoiceLine> lines;
  final String? notes;

  final PurchaseInvoiceStatus status;
  final PurchasePaymentStatus paymentStatus;
  final double paidAmount;
  final double invoiceDiscountPercent;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    this.dueDate,
    required this.lines,
    this.notes,
    this.status = PurchaseInvoiceStatus.draft,
    this.paymentStatus = PurchasePaymentStatus.unpaid,
    this.paidAmount = 0,
    this.invoiceDiscountPercent = 0,
    required this.createdAt,
    this.updatedAt,
  });

  double get subtotal => lines.fold(0.0, (s, l) => s + l.grossTotal);
  double get lineDiscounts => lines.fold(0.0, (s, l) => s + l.discountAmount);
  double get lineTaxes => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get netBeforeInvoiceDiscount => subtotal - lineDiscounts;
  double get invoiceDiscountAmount =>
      netBeforeInvoiceDiscount * (invoiceDiscountPercent / 100);
  double get grandTotal =>
      netBeforeInvoiceDiscount - invoiceDiscountAmount + lineTaxes;
  double get remainingAmount => grandTotal - paidAmount;
  bool get isFullyPaid => remainingAmount.abs() < 0.01 && grandTotal > 0;

  PurchaseInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? supplierId,
    String? supplierName,
    DateTime? date,
    DateTime? dueDate,
    List<InvoiceLine>? lines,
    String? notes,
    PurchaseInvoiceStatus? status,
    PurchasePaymentStatus? paymentStatus,
    double? paidAmount,
    double? invoiceDiscountPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
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
        'supplierId': supplierId,
        'supplierName': supplierName,
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

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) =>
      PurchaseInvoice(
        id: json['id'] as String,
        invoiceNumber: json['invoiceNumber'] as String,
        supplierId: json['supplierId'] as String,
        supplierName: json['supplierName'] as String,
        date: DateTime.parse(json['date'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        lines: (json['lines'] as List)
            .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        status: PurchaseInvoiceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PurchaseInvoiceStatus.draft,
        ),
        paymentStatus: PurchasePaymentStatus.values.firstWhere(
          (s) => s.name == json['paymentStatus'],
          orElse: () => PurchasePaymentStatus.unpaid,
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

import 'package:flutter/foundation.dart';
import 'sales_invoice.dart' show InvoiceLine;

enum PurchaseDocType { purchaseOrder, purchaseReturn }
enum PurchaseDocStatus { draft, accepted, rejected, converted, cancelled }

@immutable
class PurchaseDocument {
  final String id;
  final PurchaseDocType type;
  final String docNumber;      // PO-0001 / PR-0001
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final DateTime? deliveryDate;
  final List<InvoiceLine> lines;
  final String? notes;
  final PurchaseDocStatus status;
  final double discountPercent;
  final String? originalInvoiceId;
  final String? originalInvoiceNumber;
  final String? convertedToInvoiceId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PurchaseDocument({
    required this.id,
    required this.type,
    required this.docNumber,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    this.deliveryDate,
    required this.lines,
    this.notes,
    this.status = PurchaseDocStatus.draft,
    this.discountPercent = 0,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    this.convertedToInvoiceId,
    required this.createdAt,
    this.updatedAt,
  });

  double get subtotal => lines.fold(0.0, (s, l) => s + l.grossTotal);
  double get lineDiscounts => lines.fold(0.0, (s, l) => s + l.discountAmount);
  double get lineTaxes => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get netBeforeInvoiceDiscount => subtotal - lineDiscounts;
  double get docDiscountAmount =>
      netBeforeInvoiceDiscount * (discountPercent / 100);
  double get grandTotal =>
      netBeforeInvoiceDiscount - docDiscountAmount + lineTaxes;

  static String prefixFor(PurchaseDocType t) => switch (t) {
        PurchaseDocType.purchaseOrder => 'PO',
        PurchaseDocType.purchaseReturn => 'PR',
      };

  PurchaseDocument copyWith({
    String? id,
    PurchaseDocType? type,
    String? docNumber,
    String? supplierId,
    String? supplierName,
    DateTime? date,
    DateTime? deliveryDate,
    List<InvoiceLine>? lines,
    String? notes,
    PurchaseDocStatus? status,
    double? discountPercent,
    String? originalInvoiceId,
    String? originalInvoiceNumber,
    String? convertedToInvoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      docNumber: docNumber ?? this.docNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      date: date ?? this.date,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      discountPercent: discountPercent ?? this.discountPercent,
      originalInvoiceId: originalInvoiceId ?? this.originalInvoiceId,
      originalInvoiceNumber:
          originalInvoiceNumber ?? this.originalInvoiceNumber,
      convertedToInvoiceId:
          convertedToInvoiceId ?? this.convertedToInvoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'docNumber': docNumber,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'date': date.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'notes': notes,
        'status': status.name,
        'discountPercent': discountPercent,
        'originalInvoiceId': originalInvoiceId,
        'originalInvoiceNumber': originalInvoiceNumber,
        'convertedToInvoiceId': convertedToInvoiceId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PurchaseDocument.fromJson(Map<String, dynamic> json) =>
      PurchaseDocument(
        id: json['id'] as String,
        type: PurchaseDocType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PurchaseDocType.purchaseOrder,
        ),
        docNumber: json['docNumber'] as String,
        supplierId: json['supplierId'] as String,
        supplierName: json['supplierName'] as String,
        date: DateTime.parse(json['date'] as String),
        deliveryDate: json['deliveryDate'] != null
            ? DateTime.parse(json['deliveryDate'] as String)
            : null,
        lines: (json['lines'] as List)
            .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        status: PurchaseDocStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PurchaseDocStatus.draft,
        ),
        discountPercent:
            (json['discountPercent'] as num?)?.toDouble() ?? 0,
        originalInvoiceId: json['originalInvoiceId'] as String?,
        originalInvoiceNumber: json['originalInvoiceNumber'] as String?,
        convertedToInvoiceId: json['convertedToInvoiceId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

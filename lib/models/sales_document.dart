import 'package:flutter/foundation.dart';
import 'sales_invoice.dart'; // لإعادة استخدام InvoiceLine

/// نوع المستند
enum SalesDocType { quotation, salesOrder, salesReturn }

/// حالة المستند
enum SalesDocStatus { draft, sent, accepted, rejected, converted, cancelled }

/// مستند مبيعات عام (عرض سعر / أمر بيع / مرتجع)
@immutable
class SalesDocument {
  final String id;
  final SalesDocType type;
  final String docNumber;       // QT-0001 / SO-0001 / SR-0001
  final String customerId;
  final String customerName;
  final DateTime date;
  final DateTime? validUntil;   // للعروض
  final DateTime? deliveryDate; // للأوامر
  final List<InvoiceLine> lines;
  final String? notes;
  final SalesDocStatus status;

  final double discountPercent;

  /// مرجع الفاتورة الأصلية (للمرتجعات)
  final String? originalInvoiceId;
  final String? originalInvoiceNumber;

  /// مرجع المستند الذي حُوّل إلى هذا (أو العكس)
  final String? convertedToInvoiceId;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const SalesDocument({
    required this.id,
    required this.type,
    required this.docNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    this.validUntil,
    this.deliveryDate,
    required this.lines,
    this.notes,
    this.status = SalesDocStatus.draft,
    this.discountPercent = 0,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    this.convertedToInvoiceId,
    required this.createdAt,
    this.updatedAt,
  });

  // ── الحسابات ──────────────────────────────────────────────
  double get subtotal => lines.fold(0.0, (s, l) => s + l.grossTotal);
  double get lineDiscounts => lines.fold(0.0, (s, l) => s + l.discountAmount);
  double get lineTaxes => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get netBeforeInvoiceDiscount => subtotal - lineDiscounts;
  double get docDiscountAmount =>
      netBeforeInvoiceDiscount * (discountPercent / 100);
  double get grandTotal =>
      netBeforeInvoiceDiscount - docDiscountAmount + lineTaxes;

  /// بادئة الرقم حسب النوع
  static String prefixFor(SalesDocType t) => switch (t) {
        SalesDocType.quotation => 'QT',
        SalesDocType.salesOrder => 'SO',
        SalesDocType.salesReturn => 'SR',
      };

  String get typeLabel => switch (type) {
        SalesDocType.quotation => 'عرض سعر',
        SalesDocType.salesOrder => 'أمر بيع',
        SalesDocType.salesReturn => 'مرتجع مبيعات',
      };

  SalesDocument copyWith({
    String? id,
    SalesDocType? type,
    String? docNumber,
    String? customerId,
    String? customerName,
    DateTime? date,
    DateTime? validUntil,
    DateTime? deliveryDate,
    List<InvoiceLine>? lines,
    String? notes,
    SalesDocStatus? status,
    double? discountPercent,
    String? originalInvoiceId,
    String? originalInvoiceNumber,
    String? convertedToInvoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      docNumber: docNumber ?? this.docNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
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
        'customerId': customerId,
        'customerName': customerName,
        'date': date.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
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

  factory SalesDocument.fromJson(Map<String, dynamic> json) => SalesDocument(
        id: json['id'] as String,
        type: SalesDocType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SalesDocType.quotation,
        ),
        docNumber: json['docNumber'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        date: DateTime.parse(json['date'] as String),
        validUntil: json['validUntil'] != null
            ? DateTime.parse(json['validUntil'] as String)
            : null,
        deliveryDate: json['deliveryDate'] != null
            ? DateTime.parse(json['deliveryDate'] as String)
            : null,
        lines: (json['lines'] as List)
            .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        status: SalesDocStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SalesDocStatus.draft,
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

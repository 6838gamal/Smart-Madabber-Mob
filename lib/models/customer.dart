import 'package:flutter/foundation.dart';

/// حالة العميل
enum CustomerStatus { active, inactive, blocked }

/// العميل — كيان أساسي تُبنى عليه فواتير البيع
@immutable
class Customer {
  final String id;
  final String code;          // كود فريد (C-0001)
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;    // الرقم الضريبي
  final String? notes;

  /// حد الائتمان (0 = بلا حد)
  final double creditLimit;
  /// الرصيد الحالي (موجب = مدين لنا / سالب = له عندنا)
  final double balance;

  final CustomerStatus status;

  /// الحساب المحاسبي المرتبط (لذمم العملاء)
  final String? accountId;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.notes,
    this.creditLimit = 0,
    this.balance = 0,
    this.status = CustomerStatus.active,
    this.accountId,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == CustomerStatus.active;

  /// هل تجاوز حد الائتمان؟
  bool get isOverCreditLimit =>
      creditLimit > 0 && balance > creditLimit;

  Customer copyWith({
    String? id,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
    String? notes,
    double? creditLimit,
    double? balance,
    CustomerStatus? status,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      notes: notes ?? this.notes,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'taxNumber': taxNumber,
        'notes': notes,
        'creditLimit': creditLimit,
        'balance': balance,
        'status': status.name,
        'accountId': accountId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        taxNumber: json['taxNumber'] as String?,
        notes: json['notes'] as String?,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        status: CustomerStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CustomerStatus.active,
        ),
        accountId: json['accountId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

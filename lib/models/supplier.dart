import 'package:flutter/foundation.dart';

enum SupplierStatus { active, inactive, blocked }

@immutable
class Supplier {
  final String id;
  final String code;          // S-0001
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? notes;

  final double creditLimit;
  /// الرصيد الحالي (موجب = نحن مدينون له)
  final double balance;

  final SupplierStatus status;
  final String? accountId;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const Supplier({
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
    this.status = SupplierStatus.active,
    this.accountId,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == SupplierStatus.active;

  Supplier copyWith({
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
    SupplierStatus? status,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
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

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
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
        status: SupplierStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SupplierStatus.active,
        ),
        accountId: json['accountId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

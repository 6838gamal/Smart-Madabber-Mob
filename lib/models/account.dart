import 'package:flutter/material.dart';

/// نوع الحساب — يحدد طبيعة الرصيد (مدين/دائن)
enum AccountType {
  asset,      // أصول — مدين
  liability,  // خصوم — دائن
  equity,     // حقوق ملكية — دائن
  revenue,    // إيرادات — دائن
  expense,    // مصروفات — مدين
}

extension AccountTypeX on AccountType {
  String get labelAr {
    switch (this) {
      case AccountType.asset:     return 'أصول';
      case AccountType.liability: return 'خصوم';
      case AccountType.equity:    return 'حقوق ملكية';
      case AccountType.revenue:   return 'إيرادات';
      case AccountType.expense:   return 'مصروفات';
    }
  }

  /// طبيعة الرصيد: +1 مدين، -1 دائن
  int get naturalBalance {
    switch (this) {
      case AccountType.asset:
      case AccountType.expense:
        return 1;
      case AccountType.liability:
      case AccountType.equity:
      case AccountType.revenue:
        return -1;
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.asset:     return Icons.account_balance_wallet_outlined;
      case AccountType.liability: return Icons.trending_down;
      case AccountType.equity:    return Icons.pie_chart_outline;
      case AccountType.revenue:   return Icons.trending_up;
      case AccountType.expense:   return Icons.trending_down;
    }
  }
}

class Account {
  final String id;
  final String code;          // مثل: 1101
  final String name;          // مثل: النقدية بالصندوق
  final AccountType type;
  final String? parentId;     // للحسابات الفرعية (شجرة)
  final bool isActive;

  const Account({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.isActive = true,
  });

  Account copyWith({
    String? code,
    String? name,
    AccountType? type,
    String? parentId,
    bool? isActive,
  }) {
    return Account(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'type': type.name,
        'parentId': parentId,
        'isActive': isActive,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        type: AccountType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AccountType.asset,
        ),
        parentId: j['parentId'] as String?,
        isActive: j['isActive'] as bool? ?? true,
      );
}

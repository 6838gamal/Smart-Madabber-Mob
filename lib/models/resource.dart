import 'dart:math';

enum ResourceType {
  consumable,
  rawMaterial,
  product,
  asset,
  ingredient,
  other;

  String get label {
    switch (this) {
      case consumable:
        return 'Inventory Item';
      case rawMaterial:
        return 'Raw Material';
      case product:
        return 'Product';
      case asset:
        return 'Asset';
      case ingredient:
        return 'Ingredient';
      case other:
        return 'Other';
    }
  }

  String get labelAr {
    switch (this) {
      case consumable:
        return 'صنف مخزني';
      case rawMaterial:
        return 'مادة خام';
      case product:
        return 'منتج';
      case asset:
        return 'أصل ثابت';
      case ingredient:
        return 'مكوّن';
      case other:
        return 'أخرى';
    }
  }
}

enum ResourceStatus {
  normal,
  low,
  critical,
  inactive;

  String get label {
    switch (this) {
      case normal:
        return 'In Stock';
      case low:
        return 'Low Stock Alert';
      case critical:
        return 'Critical Stock';
      case inactive:
        return 'Inactive';
    }
  }

  String get labelAr {
    switch (this) {
      case normal:
        return 'متوفر';
      case low:
        return 'تنبيه مخزون منخفض';
      case critical:
        return 'مخزون حرج';
      case inactive:
        return 'غير نشط';
    }
  }
}

class Resource {
  final String id;
  final String name;
  final ResourceType type;
  final double currentQuantity;
  final double minThreshold;
  final String unit;
  final double dailyConsumptionRate;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  const Resource({
    required this.id,
    required this.name,
    required this.type,
    required this.currentQuantity,
    required this.minThreshold,
    required this.unit,
    this.dailyConsumptionRate = 0.0,
    required this.createdAt,
    this.lastActivityAt,
  });

  ResourceStatus get status {
    if (currentQuantity <= 0) return ResourceStatus.critical;
    if (currentQuantity <= minThreshold * 0.5) return ResourceStatus.critical;
    if (currentQuantity <= minThreshold) return ResourceStatus.low;
    if (lastActivityAt != null) {
      final daysSinceActivity =
          DateTime.now().difference(lastActivityAt!).inDays;
      if (daysSinceActivity >= 14) return ResourceStatus.inactive;
    }
    return ResourceStatus.normal;
  }

  double get daysRemaining {
    if (dailyConsumptionRate <= 0) return double.infinity;
    return currentQuantity / dailyConsumptionRate;
  }

  double get stockPercentage {
    if (minThreshold <= 0) return 1.0;
    return min(currentQuantity / (minThreshold * 3), 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'currentQuantity': currentQuantity,
        'minThreshold': minThreshold,
        'unit': unit,
        'dailyConsumptionRate': dailyConsumptionRate,
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': lastActivityAt?.toIso8601String(),
      };

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ResourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ResourceType.other,
        ),
        currentQuantity: (json['currentQuantity'] as num).toDouble(),
        minThreshold: (json['minThreshold'] as num).toDouble(),
        unit: json['unit'] as String,
        dailyConsumptionRate:
            (json['dailyConsumptionRate'] as num? ?? 0).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastActivityAt: json['lastActivityAt'] != null
            ? DateTime.parse(json['lastActivityAt'] as String)
            : null,
      );

  Resource copyWith({
    String? id,
    String? name,
    ResourceType? type,
    double? currentQuantity,
    double? minThreshold,
    String? unit,
    double? dailyConsumptionRate,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) =>
      Resource(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        minThreshold: minThreshold ?? this.minThreshold,
        unit: unit ?? this.unit,
        dailyConsumptionRate: dailyConsumptionRate ?? this.dailyConsumptionRate,
        createdAt: createdAt ?? this.createdAt,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      );
}

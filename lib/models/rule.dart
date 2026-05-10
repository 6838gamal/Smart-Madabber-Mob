enum RuleConditionType {
  lowStock,
  highConsumption,
  inactiveResource,
  wasteDetection,
  criticalLevel;

  String get label {
    switch (this) {
      case lowStock:
        return 'Low Stock Alert';
      case highConsumption:
        return 'High Consumption';
      case inactiveResource:
        return 'Inactive Item';
      case wasteDetection:
        return 'Waste Analysis';
      case criticalLevel:
        return 'Critical Stock Level';
    }
  }

  String get description {
    switch (this) {
      case lowStock:
        return 'Alert when stock quantity falls below minimum threshold';
      case highConsumption:
        return 'Alert when daily consumption rate is unusually high';
      case inactiveResource:
        return 'Alert when an inventory item has had no stock movement for too long';
      case wasteDetection:
        return 'Detect possible waste from high consumption with no restocking';
      case criticalLevel:
        return 'Alert when stock is critically low — below 50% of minimum threshold';
    }
  }
}

enum RuleSeverity {
  info,
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case info:
        return 'Info';
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case critical:
        return 'Critical';
    }
  }
}

class Rule {
  final String id;
  final String name;
  final RuleConditionType conditionType;
  final double conditionValue;
  final String action;
  final RuleSeverity severity;
  final bool enabled;

  const Rule({
    required this.id,
    required this.name,
    required this.conditionType,
    required this.conditionValue,
    required this.action,
    required this.severity,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'conditionType': conditionType.name,
        'conditionValue': conditionValue,
        'action': action,
        'severity': severity.name,
        'enabled': enabled,
      };

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
        id: json['id'] as String,
        name: json['name'] as String,
        conditionType: RuleConditionType.values.firstWhere(
          (e) => e.name == json['conditionType'],
          orElse: () => RuleConditionType.lowStock,
        ),
        conditionValue: (json['conditionValue'] as num).toDouble(),
        action: json['action'] as String,
        severity: RuleSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => RuleSeverity.medium,
        ),
        enabled: json['enabled'] as bool? ?? true,
      );

  Rule copyWith({
    String? id,
    String? name,
    RuleConditionType? conditionType,
    double? conditionValue,
    String? action,
    RuleSeverity? severity,
    bool? enabled,
  }) =>
      Rule(
        id: id ?? this.id,
        name: name ?? this.name,
        conditionType: conditionType ?? this.conditionType,
        conditionValue: conditionValue ?? this.conditionValue,
        action: action ?? this.action,
        severity: severity ?? this.severity,
        enabled: enabled ?? this.enabled,
      );
}

import 'rule.dart';

enum InsightStatus {
  active,
  dismissed,
  resolved;

  String get label {
    switch (this) {
      case active:
        return 'Active';
      case dismissed:
        return 'Dismissed';
      case resolved:
        return 'Resolved';
    }
  }
}

class Insight {
  final String id;
  final String resourceId;
  final String resourceName;
  final RuleConditionType type;
  final String message;
  final String decision;
  final int priority;
  final DateTime createdAt;
  final InsightStatus status;
  final RuleSeverity severity;

  const Insight({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.type,
    required this.message,
    required this.decision,
    required this.priority,
    required this.createdAt,
    this.status = InsightStatus.active,
    required this.severity,
  });

  bool get isActive => status == InsightStatus.active;

  String get severityEmoji {
    switch (severity) {
      case RuleSeverity.critical:
        return '🔴';
      case RuleSeverity.high:
        return '🟠';
      case RuleSeverity.medium:
        return '🟡';
      case RuleSeverity.low:
        return '🟢';
      case RuleSeverity.info:
        return '🔵';
    }
  }

  String get typeIcon {
    switch (type) {
      case RuleConditionType.lowStock:
        return '📉';
      case RuleConditionType.highConsumption:
        return '⚡';
      case RuleConditionType.inactiveResource:
        return '😴';
      case RuleConditionType.wasteDetection:
        return '♻️';
      case RuleConditionType.criticalLevel:
        return '🚨';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'resourceName': resourceName,
        'type': type.name,
        'message': message,
        'decision': decision,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'severity': severity.name,
      };

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        resourceName: json['resourceName'] as String? ?? '',
        type: RuleConditionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RuleConditionType.lowStock,
        ),
        message: json['message'] as String,
        decision: json['decision'] as String? ?? '',
        priority: json['priority'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: InsightStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => InsightStatus.active,
        ),
        severity: RuleSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => RuleSeverity.medium,
        ),
      );

  Insight copyWith({
    String? id,
    String? resourceId,
    String? resourceName,
    RuleConditionType? type,
    String? message,
    String? decision,
    int? priority,
    DateTime? createdAt,
    InsightStatus? status,
    RuleSeverity? severity,
  }) =>
      Insight(
        id: id ?? this.id,
        resourceId: resourceId ?? this.resourceId,
        resourceName: resourceName ?? this.resourceName,
        type: type ?? this.type,
        message: message ?? this.message,
        decision: decision ?? this.decision,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        severity: severity ?? this.severity,
      );
}

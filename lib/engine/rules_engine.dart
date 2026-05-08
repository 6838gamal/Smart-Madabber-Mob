import 'package:uuid/uuid.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../models/rule.dart';
import '../models/insight.dart';

class RulesEngine {
  static const _uuid = Uuid();

  static List<Insight> run({
    required List<Resource> resources,
    required List<Transaction> transactions,
    required List<Rule> rules,
  }) {
    final insights = <Insight>[];
    final now = DateTime.now();

    for (final resource in resources) {
      final resourceTxns = transactions
          .where((t) => t.resourceId == resource.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      for (final rule in rules.where((r) => r.enabled)) {
        switch (rule.conditionType) {
          case RuleConditionType.lowStock:
            if (resource.currentQuantity <= resource.minThreshold &&
                resource.currentQuantity > resource.minThreshold * 0.5) {
              insights.add(Insight(
                id: _uuid.v4(),
                resourceId: resource.id,
                resourceName: resource.name,
                type: RuleConditionType.lowStock,
                message:
                    '${resource.name} is running low — ${resource.currentQuantity.toStringAsFixed(1)} ${resource.unit} remaining (min: ${resource.minThreshold} ${resource.unit})',
                decision:
                    'Restock ${resource.name} soon. You have approximately ${resource.daysRemaining.isFinite ? resource.daysRemaining.toStringAsFixed(0) : "∞"} days of supply left.',
                priority: 2,
                createdAt: now,
                severity: rule.severity,
              ));
            }
            break;

          case RuleConditionType.criticalLevel:
            if (resource.currentQuantity <= resource.minThreshold * 0.5) {
              insights.add(Insight(
                id: _uuid.v4(),
                resourceId: resource.id,
                resourceName: resource.name,
                type: RuleConditionType.criticalLevel,
                message:
                    '🚨 CRITICAL: ${resource.name} is at ${resource.currentQuantity.toStringAsFixed(1)} ${resource.unit} — below critical threshold!',
                decision:
                    'Immediately restock ${resource.name}. Current level is dangerously low.',
                priority: 5,
                createdAt: now,
                severity: RuleSeverity.critical,
              ));
            }
            break;

          case RuleConditionType.highConsumption:
            final recentConsumptions = resourceTxns
                .where((t) =>
                    t.type == TransactionType.consume &&
                    now.difference(t.date).inDays <= 7)
                .toList();
            if (recentConsumptions.length >= 3) {
              final weeklyTotal =
                  recentConsumptions.fold(0.0, (s, t) => s + t.quantity);
              final avgDaily = weeklyTotal / 7;
              if (avgDaily > resource.dailyConsumptionRate * 1.5 &&
                  resource.dailyConsumptionRate > 0) {
                insights.add(Insight(
                  id: _uuid.v4(),
                  resourceId: resource.id,
                  resourceName: resource.name,
                  type: RuleConditionType.highConsumption,
                  message:
                      '${resource.name} consumption is ${((avgDaily / resource.dailyConsumptionRate - 1) * 100).toStringAsFixed(0)}% above normal this week',
                  decision:
                      'Review ${resource.name} usage. Consider setting stricter consumption limits or investigating the cause of increased usage.',
                  priority: 3,
                  createdAt: now,
                  severity: rule.severity,
                ));
              }
            }
            break;

          case RuleConditionType.inactiveResource:
            final inactiveDays = rule.conditionValue.toInt();
            final lastActivity = resourceTxns.isNotEmpty ? resourceTxns.first.date : resource.createdAt;
            final daysSince = now.difference(lastActivity).inDays;
            if (daysSince >= inactiveDays) {
              insights.add(Insight(
                id: _uuid.v4(),
                resourceId: resource.id,
                resourceName: resource.name,
                type: RuleConditionType.inactiveResource,
                message:
                    '${resource.name} has had no activity for $daysSince days',
                decision:
                    'Review ${resource.name}. Consider whether this resource is still needed or if it should be removed/repurposed.',
                priority: 1,
                createdAt: now,
                severity: rule.severity,
              ));
            }
            break;

          case RuleConditionType.wasteDetection:
            final consumptions = resourceTxns
                .where((t) =>
                    t.type == TransactionType.consume &&
                    now.difference(t.date).inDays <= 14)
                .toList();
            final purchases = resourceTxns
                .where((t) =>
                    t.type == TransactionType.purchase &&
                    now.difference(t.date).inDays <= 14)
                .toList();
            if (consumptions.length >= 5 && purchases.isEmpty) {
              final totalConsumed =
                  consumptions.fold(0.0, (s, t) => s + t.quantity);
              if (totalConsumed > resource.currentQuantity * 0.8) {
                insights.add(Insight(
                  id: _uuid.v4(),
                  resourceId: resource.id,
                  resourceName: resource.name,
                  type: RuleConditionType.wasteDetection,
                  message:
                      'Potential waste detected for ${resource.name} — high consumption with no restocking in 14 days',
                  decision:
                      'Audit ${resource.name} usage patterns. Consider purchasing in smaller quantities to avoid waste.',
                  priority: 2,
                  createdAt: now,
                  severity: rule.severity,
                ));
              }
            }
            break;
        }
      }
    }

    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights;
  }

  static Insight? decisionOfTheDay(List<Insight> insights) {
    final active = insights.where((i) => i.isActive).toList();
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.priority >= b.priority ? a : b);
  }
}

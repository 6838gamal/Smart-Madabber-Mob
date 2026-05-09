import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/insight.dart';
import '../models/rule.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onDismiss;
  final VoidCallback? onResolve;
  final bool compact;

  const InsightCard({
    super.key,
    required this.insight,
    this.onDismiss,
    this.onResolve,
    this.compact = false,
  });

  Color get _severityColor {
    switch (insight.severity) {
      case RuleSeverity.critical:
        return AppColors.critical;
      case RuleSeverity.high:
        return AppColors.danger;
      case RuleSeverity.medium:
        return AppColors.warning;
      case RuleSeverity.low:
        return AppColors.normal;
      case RuleSeverity.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _severityColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _severityColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(insight.typeIcon,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SeverityChip(severity: insight.severity),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            insight.resourceName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!compact && insight.decision.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _severityColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _severityColor.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: _severityColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insight.decision,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(insight.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Row(
                  children: [
                    if (onDismiss != null)
                      _ActionButton(
                        label: l10n.dismiss,
                        icon: Icons.close_rounded,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        onTap: onDismiss!,
                      ),
                    if (onResolve != null) ...[
                      const SizedBox(width: 6),
                      _ActionButton(
                        label: l10n.resolve,
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: onResolve!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final RuleSeverity severity;
  const _SeverityChip({required this.severity});

  Color get _color {
    switch (severity) {
      case RuleSeverity.critical:
        return AppColors.critical;
      case RuleSeverity.high:
        return AppColors.danger;
      case RuleSeverity.medium:
        return AppColors.warning;
      case RuleSeverity.low:
        return AppColors.normal;
      case RuleSeverity.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

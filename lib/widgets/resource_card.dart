import 'package:flutter/material.dart';
import '../models/resource.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onTap;

  const ResourceCard({super.key, required this.resource, this.onTap});

  Color get _statusColor {
    switch (resource.status) {
      case ResourceStatus.critical:
        return AppColors.critical;
      case ResourceStatus.low:
        return AppColors.warning;
      case ResourceStatus.inactive:
        return AppColors.inactive;
      case ResourceStatus.normal:
        return AppColors.normal;
    }
  }

  IconData get _typeIcon {
    switch (resource.type) {
      case ResourceType.consumable:
        return Icons.local_grocery_store_rounded;
      case ResourceType.rawMaterial:
        return Icons.category_rounded;
      case ResourceType.product:
        return Icons.shopping_bag_rounded;
      case ResourceType.asset:
        return Icons.business_rounded;
      case ResourceType.ingredient:
        return Icons.kitchen_rounded;
      case ResourceType.other:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = resource.stockPercentage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: resource.status == ResourceStatus.critical
                ? AppColors.critical.withOpacity(0.4)
                : resource.status == ResourceStatus.low
                    ? AppColors.warning.withOpacity(0.3)
                    : isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_typeIcon, color: _statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        resource.type.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: resource.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${resource.currentQuantity.toStringAsFixed(1)} ${resource.unit}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
                Text(
                  '${l10n.minPrefix}${resource.minThreshold} ${resource.unit}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              ),
            ),
            if (resource.dailyConsumptionRate > 0) ...[
              const SizedBox(height: 8),
              Text(
                resource.daysRemaining.isFinite
                    ? '~${resource.daysRemaining.toStringAsFixed(0)} ${l10n.daysRemaining}'
                    : l10n.consumptionRateNotSet,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ResourceStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case ResourceStatus.critical:
        return AppColors.critical;
      case ResourceStatus.low:
        return AppColors.warning;
      case ResourceStatus.inactive:
        return AppColors.inactive;
      case ResourceStatus.normal:
        return AppColors.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

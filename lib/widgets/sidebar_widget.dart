import 'package:flutter/material.dart';
import '../models/sidebar_node.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SidebarWidget extends StatefulWidget {
  final List<SidebarNode> nodes;
  final AppScreen selectedScreen;
  final ValueChanged<AppScreen> onItemSelected;
  final bool showHeader;

  const SidebarWidget({
    super.key,
    required this.nodes,
    required this.selectedScreen,
    required this.onItemSelected,
    this.showHeader = true,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.showHeader ? 280 : null,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          if (widget.showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تطبيق المحاسبة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: widget.nodes.map(_buildNode).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(SidebarNode node) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (node.isGroup) {
      final isExpanded = _expanded.contains(node.id);
      return Column(
        children: [
          ListTile(
            leading: Icon(
              node.icon,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            title: Text(
              node.title,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => setState(() {
              isExpanded
                  ? _expanded.remove(node.id)
                  : _expanded.add(node.id);
            }),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Column(
                children: node.children.map(_buildNode).toList(),
              ),
            ),
        ],
      );
    }

    final screen = node.screen as AppScreen?;
    final isSelected = screen != null && screen == widget.selectedScreen;
    final isEnabled = node.enabled && screen != null;

    final color = !isEnabled
        ? (isDark
            ? AppColors.textSecondaryDark.withOpacity(0.5)
            : AppColors.textSecondaryLight.withOpacity(0.5))
        : (isSelected
            ? AppColors.primary
            : (isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight));

    return ListTile(
      enabled: isEnabled,
      leading: Icon(node.icon, color: color),
      title: Text(
        node.title,
        style: TextStyle(
          color: isEnabled
              ? (isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight))
              : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: isEnabled ? () => widget.onItemSelected(screen!) : null,
    );
  }
}

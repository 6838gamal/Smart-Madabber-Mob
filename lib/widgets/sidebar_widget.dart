import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _buildLogo(context, isDark),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _buildItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  screen: AppScreen.dashboard,
                  provider: provider,
                  badge: provider.criticalCount + provider.lowStockCount > 0
                      ? provider.criticalCount + provider.lowStockCount
                      : null,
                ),
                _buildItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  label: 'Resources',
                  screen: AppScreen.resources,
                  provider: provider,
                ),
                _buildItem(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transactions',
                  screen: AppScreen.transactions,
                  provider: provider,
                ),
                _buildItem(
                  context,
                  icon: Icons.lightbulb_rounded,
                  label: 'Insights',
                  screen: AppScreen.insights,
                  provider: provider,
                  badge: provider.activeInsights.length > 0
                      ? provider.activeInsights.length
                      : null,
                ),
                _buildItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  screen: AppScreen.reports,
                  provider: provider,
                ),
                const SizedBox(height: 8),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 8),
                _buildItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  screen: AppScreen.settings,
                  provider: provider,
                ),
              ],
            ),
          ),
          _buildFooter(context, provider, isDark),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدبّر الذكي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Smart Advisor',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppScreen screen,
    required AppProvider provider,
    int? badge,
  }) {
    final isSelected = provider.currentScreen == screen;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => provider.navigateTo(screen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            size: 16,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            provider.isDarkMode ? 'Dark Mode' : 'Light Mode',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Switch(
            value: provider.isDarkMode,
            onChanged: (_) => provider.toggleDarkMode(),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

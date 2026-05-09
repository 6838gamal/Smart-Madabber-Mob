import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(context, isDark, l10n),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _buildItem(context,
                    icon: Icons.dashboard_rounded,
                    label: l10n.dashboard,
                    screen: AppScreen.dashboard,
                    provider: provider,
                    isDark: isDark,
                    badge: provider.criticalCount + provider.lowStockCount > 0
                        ? provider.criticalCount + provider.lowStockCount
                        : null),
                _buildItem(context,
                    icon: Icons.inventory_2_rounded,
                    label: l10n.resources,
                    screen: AppScreen.resources,
                    provider: provider,
                    isDark: isDark),
                _buildItem(context,
                    icon: Icons.swap_horiz_rounded,
                    label: l10n.transactions,
                    screen: AppScreen.transactions,
                    provider: provider,
                    isDark: isDark),
                _buildItem(context,
                    icon: Icons.lightbulb_rounded,
                    label: l10n.insights,
                    screen: AppScreen.insights,
                    provider: provider,
                    isDark: isDark,
                    badge: provider.activeInsights.isNotEmpty
                        ? provider.activeInsights.length
                        : null),
                _buildItem(context,
                    icon: Icons.bar_chart_rounded,
                    label: l10n.reports,
                    screen: AppScreen.reports,
                    provider: provider,
                    isDark: isDark),
                const SizedBox(height: 8),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 8),
                _buildItem(context,
                    icon: Icons.settings_rounded,
                    label: l10n.settings,
                    screen: AppScreen.settings,
                    provider: provider,
                    isDark: isDark),
                _buildItem(context,
                    icon: Icons.help_outline_rounded,
                    label: l10n.help,
                    screen: AppScreen.help,
                    provider: provider,
                    isDark: isDark),
              ],
            ),
          ),
          _buildFooter(context, provider, isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark, L10n l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
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
                  l10n.appName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  l10n.appSubtitle,
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
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppScreen screen,
    required AppProvider provider,
    required bool isDark,
    int? badge,
  }) {
    final isSelected = provider.currentScreen == screen;

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
      BuildContext context, AppProvider provider, bool isDark, L10n l10n) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Dark mode row
          Row(
            children: [
              Icon(
                provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 15,
                color: secondary,
              ),
              const SizedBox(width: 8),
              Text(
                provider.isDarkMode ? l10n.darkMode : l10n.lightMode,
                style: TextStyle(fontSize: 12, color: secondary),
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
          const SizedBox(height: 8),
          // Language toggle row
          Row(
            children: [
              Icon(Icons.language_rounded, size: 15, color: secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.isArabic ? l10n.arabicLanguage : l10n.englishLanguage,
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ),
              _LangToggle(provider: provider, l10n: l10n),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final AppProvider provider;
  final L10n l10n;
  const _LangToggle({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () =>
          provider.setLanguage(provider.isArabic ? 'en' : 'ar'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          provider.isArabic ? 'EN' : 'ع',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

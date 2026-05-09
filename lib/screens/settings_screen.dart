import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/rule.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.customizeExperience,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          // ── Appearance ──────────────────────────────────────────────────
          _Section(title: l10n.appearance, isDark: isDark, children: [
            _SettingRow(
              isDark: isDark,
              icon: Icons.dark_mode_rounded,
              title: l10n.darkModeLabel,
              subtitle: l10n.switchTheme,
              trailing: Switch(
                value: provider.isDarkMode,
                onChanged: (_) => provider.toggleDarkMode(),
                activeColor: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Language ────────────────────────────────────────────────────
          _Section(title: l10n.languageLabel, isDark: isDark, children: [
            _SettingRow(
              isDark: isDark,
              icon: Icons.language_rounded,
              title: l10n.languageLabel,
              subtitle: provider.isArabic
                  ? l10n.arabicLanguage
                  : l10n.englishLanguage,
              trailing: _LanguageSelector(
                  provider: provider, isDark: isDark, l10n: l10n),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Currency ────────────────────────────────────────────────────
          _Section(title: l10n.currencyLabel, isDark: isDark, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: provider.currency,
                decoration: InputDecoration(
                  labelText: l10n.displayCurrencyLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'YER_NEW',
                    child: Text(
                        l10n.isAr ? 'ريال جديد — ر.ي.ج' : 'YER New — ر.ي.ج'),
                  ),
                  DropdownMenuItem(
                    value: 'YER_OLD',
                    child: Text(
                        l10n.isAr ? 'ريال قديم — ر.ي.ق' : 'YER Old — ر.ي.ق'),
                  ),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text(
                        l10n.isAr ? 'دولار أمريكي — \$' : 'US Dollar — \$'),
                  ),
                ],
                onChanged: (v) => provider.setCurrency(v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Rules Engine ────────────────────────────────────────────────
          _Section(
              title: l10n.rulesEngineLabel,
              isDark: isDark,
              children: provider.rules
                  .map((rule) => _RuleRow(rule: rule, isDark: isDark))
                  .toList()),
          const SizedBox(height: 16),

          // ── About ────────────────────────────────────────────────────────
          _Section(title: l10n.aboutLabel, isDark: isDark, children: [
            _SettingRow(
              isDark: isDark,
              icon: Icons.psychology_rounded,
              title: 'المدبّر الذكي — Smart Advisor',
              subtitle: l10n.versionInfo,
              trailing: const SizedBox(),
            ),
            _SettingRow(
              isDark: isDark,
              icon: Icons.storage_rounded,
              title: l10n.dataStorageLabel,
              subtitle: l10n.dataStoredLocally,
              trailing: const SizedBox(),
            ),
            _SettingRow(
              isDark: isDark,
              icon: Icons.info_rounded,
              title: l10n.systemLabel,
              subtitle:
                  '${provider.resources.length} ${l10n.resources} · ${provider.transactions.length} ${l10n.transactions} · ${provider.insights.length} ${l10n.insights}',
              trailing: const SizedBox(),
            ),
          ]),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppProvider provider;
  final bool isDark;
  final L10n l10n;

  const _LanguageSelector(
      {required this.provider, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangBtn(
          label: 'ع',
          selected: provider.isArabic,
          onTap: () => provider.setLanguage('ar'),
        ),
        const SizedBox(width: 6),
        _LangBtn(
          label: 'EN',
          selected: !provider.isArabic,
          onTap: () => provider.setLanguage('en'),
        ),
      ],
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _Section(
      {required this.title, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Divider(
                            height: 1,
                            indent: 52,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final Rule rule;
  final bool isDark;

  const _RuleRow({required this.rule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (rule.enabled ? AppColors.success : AppColors.inactive)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.rule_rounded,
              size: 17,
              color: rule.enabled ? AppColors.success : AppColors.inactive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  rule.severity.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.enabled,
            onChanged: (_) => provider.toggleRule(rule.id),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

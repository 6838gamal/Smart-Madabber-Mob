import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/rule.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
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
            'Customize your Smart Advisor experience',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Appearance', isDark: isDark, children: [
            _SettingRow(
              isDark: isDark,
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              trailing: Switch(
                value: provider.isDarkMode,
                onChanged: (_) => provider.toggleDarkMode(),
                activeColor: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Currency', isDark: isDark, children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: provider.currency,
                decoration: const InputDecoration(
                  labelText: 'Display Currency',
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar')),
                  DropdownMenuItem(value: 'SAR', child: Text('SAR — Saudi Riyal')),
                  DropdownMenuItem(value: 'AED', child: Text('AED — UAE Dirham')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP — British Pound')),
                  DropdownMenuItem(value: 'EGP', child: Text('EGP — Egyptian Pound')),
                  DropdownMenuItem(value: 'KWD', child: Text('KWD — Kuwaiti Dinar')),
                ],
                onChanged: (v) => provider.setCurrency(v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(
              title: 'Rules Engine',
              isDark: isDark,
              children: provider.rules
                  .map((rule) => _RuleRow(rule: rule, isDark: isDark))
                  .toList()),
          const SizedBox(height: 16),
          _Section(title: 'About', isDark: isDark, children: [
            _SettingRow(
              isDark: isDark,
              icon: Icons.psychology_rounded,
              title: 'المدبّر الذكي — Smart Advisor',
              subtitle: 'Version 1.0.0 · Offline-first decision engine',
              trailing: const SizedBox(),
            ),
            _SettingRow(
              isDark: isDark,
              icon: Icons.storage_rounded,
              title: 'Data Storage',
              subtitle: 'All data stored locally on your device',
              trailing: const SizedBox(),
            ),
            _SettingRow(
              isDark: isDark,
              icon: Icons.info_rounded,
              title: 'System',
              subtitle:
                  '${provider.resources.length} resources · ${provider.transactions.length} transactions · ${provider.insights.length} insights',
              trailing: const SizedBox(),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _Section(
      {required this.title,
      required this.isDark,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
            color:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
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
              color: rule.enabled
                  ? AppColors.success
                  : AppColors.inactive,
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
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

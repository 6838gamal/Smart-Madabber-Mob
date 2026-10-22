import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/sidebar_widget.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'resources_screen.dart';
import 'transactions_screen.dart';
import 'insights_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'add_entry_screen.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            const SidebarWidget(),
            Expanded(child: _buildContent(provider.currentScreen)),
          ],
        ),
        floatingActionButton: _buildFabColumn(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    return Scaffold(
      drawer: _buildDrawer(context, provider),
      body: _buildContent(provider.currentScreen),
      bottomNavigationBar: _BottomNav(provider: provider),
      floatingActionButton: _buildFabColumn(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildContent(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return const DashboardScreen();
      case AppScreen.resources:
        return const ResourcesScreen();
      case AppScreen.transactions:
        return const TransactionsScreen();
      case AppScreen.insights:
        return const InsightsScreen();
      case AppScreen.reports:
        return const ReportsScreen();
      case AppScreen.settings:
        return const SettingsScreen();
      case AppScreen.help:
        return const HelpScreen();
    }
  }

  /// عمود الأزرار العائمة: زر الإضافة (الرئيسي) + زر الذكاء الاصطناعي فوقه
  Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر الذكاء الاصطناعي (صغير)
        FloatingActionButton.small(
          heroTag: 'ai_fab',
          backgroundColor: AppColors.primary.withOpacity(0.85),
          foregroundColor: Colors.white,
          tooltip: 'المساعد الذكي',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
            );
          },
          child: const Icon(Icons.auto_awesome_rounded),
        ),
        const SizedBox(height: 12),
        // زر الإضافة (الرئيسي - في المنتصف)
        FloatingActionButton(
          heroTag: 'add_fab',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          tooltip: 'إضافة قيد',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEntryScreen()),
            );
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, AppProvider provider) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // العناصر المنقولة إلى القائمة الجانبية
    final drawerItems = [
      (AppScreen.transactions, Icons.swap_horiz_rounded, l10n.transactions),
      (AppScreen.insights, Icons.lightbulb_rounded, l10n.insights),
      (AppScreen.reports, Icons.bar_chart_rounded, l10n.reports),
      (AppScreen.settings, Icons.settings_rounded, l10n.settings),
      (AppScreen.help, Icons.help_outline_rounded, l10n.help),
    ];

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس القائمة
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
            const SizedBox(height: 8),

            // عناصر القائمة الجانبية
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  // الشاشة الرئيسية
                  _drawerTile(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: l10n.dashboard,
                    selected: provider.currentScreen == AppScreen.dashboard,
                    onTap: () {
                      provider.navigateTo(AppScreen.dashboard);
                      Navigator.pop(context);
                    },
                  ),
                  // المخزون
                  _drawerTile(
                    context,
                    icon: Icons.inventory_2_rounded,
                    label: l10n.resources,
                    selected: provider.currentScreen == AppScreen.resources,
                    onTap: () {
                      provider.navigateTo(AppScreen.resources);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),

                  // باقي العناصر
                  ...drawerItems.map(
                    (e) => _drawerTile(
                      context,
                      icon: e.$2,
                      label: e.$3,
                      selected: provider.currentScreen == e.$1,
                      onTap: () {
                        provider.navigateTo(e.$1);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // تذييل القائمة
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'الإصدار 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color: selected
            ? AppColors.primary
            : (isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected
              ? AppColors.primary
              : (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppProvider provider;
  const _BottomNav({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomAppBar(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // 1) الشاشة الرئيسية
            _navItem(
              context,
              icon: Icons.dashboard_rounded,
              label: l10n.dashboard,
              selected: provider.currentScreen == AppScreen.dashboard,
              onTap: () => provider.navigateTo(AppScreen.dashboard),
            ),

            // 2) فتح القائمة الجانبية
            _navItem(
              context,
              icon: Icons.menu_rounded,
              label: 'القائمة',
              selected: false,
              onTap: () => Scaffold.of(context).openDrawer(),
            ),

            // مساحة فارغة في المنتصف لزر الإضافة العائم (Notch)
            const SizedBox(width: 72),

            // 3) المخزون
            _navItem(
              context,
              icon: Icons.inventory_2_rounded,
              label: l10n.resources,
              selected: provider.currentScreen == AppScreen.resources,
              onTap: () => provider.navigateTo(AppScreen.resources),
            ),

            // 4) الإعدادات (زر إضافي سريع)
            _navItem(
              context,
              icon: Icons.settings_rounded,
              label: l10n.settings,
              selected: provider.currentScreen == AppScreen.settings,
              onTap: () => provider.navigateTo(AppScreen.settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? AppColors.primary
        : (isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

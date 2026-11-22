import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/sidebar_node.dart';
import 'dashboard_screen.dart';
import 'resources_screen.dart';
import 'transactions_screen.dart';
import 'insights_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'add_entry_screen.dart';
import 'ai_assistant_screen.dart';
import 'drawer_screen.dart';

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
            const AppSidebar(),
            Expanded(child: _buildContent(provider.currentScreen)),
          ],
        ),
        floatingActionButton: _buildFabColumn(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),

      // ✅ زر القائمة في مكانه الطبيعي أعلى الشاشة + زر المساعد الذكي يميناً
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'القائمة',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(_screenTitle(provider.currentScreen)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'المساعد الذكي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              );
            },
          ),
        ],
      ),

      body: _buildContent(provider.currentScreen),
      bottomNavigationBar: _BottomNav(provider: provider),

      // ✅ زر الإضافة جزء من القائمة السفلية عبر الفتحة (notch)
      floatingActionButton: FloatingActionButton(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// عنوان الشاشة الحالية لعرضه في الـ AppBar
  String _screenTitle(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return 'الرئيسية';
      case AppScreen.resources:
        return 'الموارد';
      case AppScreen.transactions:
        return 'المعاملات';
      case AppScreen.insights:
        return 'الرؤى';
      case AppScreen.reports:
        return 'التقارير';
      case AppScreen.settings:
        return 'الإعدادات';
      case AppScreen.help:
        return 'المساعدة';
    }
  }

  // ---------------- محتوى الشاشات ----------------
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

  /// على الشاشات العريضة فقط: عمود الأزرار العائمة على يمين الشاشة
  /// (زر الإضافة + زر المساعد الذكي فوقه)
  Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        FloatingActionButton(
          heroTag: 'add_fab_wide',
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
}

// ---------------- BottomNav ----------------
class _BottomNav extends StatelessWidget {
  final AppProvider provider;
  const _BottomNav({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomAppBar(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,

      // ✅ الفتحة ضرورية لظهور زر الإضافة كجزء من الشريط
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,

      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _navItem(
              context,
              icon: Icons.dashboard_rounded,
              label: l10n.dashboard,
              selected: provider.currentScreen == AppScreen.dashboard,
              onTap: () => provider.navigateTo(AppScreen.dashboard),
            ),
            _navItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'المعاملات',
              selected: provider.currentScreen == AppScreen.transactions,
              onTap: () => provider.navigateTo(AppScreen.transactions),
            ),

            // ✅ فراغ في المنتصف للفتحة (عرض ≈ قطر الزر + notchMargin*2)
            const SizedBox(width: 72),

            _navItem(
              context,
              icon: Icons.inventory_2_rounded,
              label: l10n.resources,
              selected: provider.currentScreen == AppScreen.resources,
              onTap: () => provider.navigateTo(AppScreen.resources),
            ),
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

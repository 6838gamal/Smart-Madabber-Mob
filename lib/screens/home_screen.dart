import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/sidebar_widget.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'resources_screen.dart';
import 'transactions_screen.dart';
import 'insights_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            const SidebarWidget(),
            Expanded(
              child: _buildContent(provider.currentScreen),
            ),
          ],
        ),
      );
    }

    // Narrow layout: bottom nav
    return Scaffold(
      body: _buildContent(provider.currentScreen),
      bottomNavigationBar: _BottomNav(provider: provider),
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
    }
  }
}

class _BottomNav extends StatelessWidget {
  final AppProvider provider;
  const _BottomNav({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (AppScreen.dashboard, Icons.dashboard_rounded, 'Dashboard'),
      (AppScreen.resources, Icons.inventory_2_rounded, 'Resources'),
      (AppScreen.transactions, Icons.swap_horiz_rounded, 'Txns'),
      (AppScreen.insights, Icons.lightbulb_rounded, 'Insights'),
      (AppScreen.settings, Icons.settings_rounded, 'Settings'),
    ];

    final currentIndex =
        items.indexWhere((e) => e.$1 == provider.currentScreen);

    return BottomNavigationBar(
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      onTap: (i) => provider.navigateTo(items[i].$1),
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: items
          .map((e) => BottomNavigationBarItem(
                icon: Icon(e.$2, size: 22),
                label: e.$3,
              ))
          .toList(),
    );
  }
}

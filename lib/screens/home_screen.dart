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
import 'accounting/general_ledger_screen.dart';
import 'accounting/chart_of_accounts_screen.dart';
import 'accounting/journal_entry_new_screen.dart';
import 'accounting/journal_entries_list_screen.dart';
import 'accounting/trial_balance_screen.dart';
import 'accounting/profit_loss_screen.dart';
import 'accounting/balance_sheet_screen.dart';
import 'accounting/cash_flow_screen.dart';

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
      // ── شاشات أساسية ──────────────────────────────────────
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

      // ── المحاسبة ──────────────────────────────────────────
      case AppScreen.chartOfAccounts:
        return 'دليل الحسابات';
      case AppScreen.journalEntryNew:
        return 'قيد جديد';
      case AppScreen.journalEntriesList:
        return 'قائمة القيود';
      case AppScreen.recurringJournals:
        return 'القيود المتكررة';
      case AppScreen.generalLedger:
        return 'دفتر الأستاذ';
      case AppScreen.trialBalance:
        return 'ميزان المراجعة';
      case AppScreen.profitLoss:
        return 'الأرباح والخسائر';
      case AppScreen.balanceSheet:
        return 'الميزانية العمومية';
      case AppScreen.cashFlow:
        return 'التدفقات النقدية';
      case AppScreen.costCenters:
        return 'مراكز التكلفة / الفروع';
      case AppScreen.openingBalances:
        return 'الأرصدة الافتتاحية';

      // ── المبيعات ──────────────────────────────────────────
      case AppScreen.salesInvoiceNew:
        return 'فاتورة بيع جديدة';
      case AppScreen.salesInvoicesList:
        return 'قائمة فواتير البيع';
      case AppScreen.salesReturns:
        return 'مرتجع المبيعات';
      case AppScreen.quotations:
        return 'عروض الأسعار';
      case AppScreen.salesOrders:
        return 'أوامر البيع';
      case AppScreen.customersList:
        return 'قائمة العملاء';
      case AppScreen.discounts:
        return 'الخصومات والأسعار الخاصة';

      // ── المشتريات ─────────────────────────────────────────
      case AppScreen.purchaseInvoiceNew:
        return 'فاتورة شراء جديدة';
      case AppScreen.purchaseInvoicesList:
        return 'قائمة فواتير الشراء';
      case AppScreen.purchaseReturns:
        return 'مرتجع المشتريات';
      case AppScreen.purchaseOrders:
        return 'أوامر الشراء';
      case AppScreen.suppliersList:
        return 'قائمة الموردين';

      // ── المخزون ───────────────────────────────────────────
      case AppScreen.itemsList:
        return 'قائمة الأصناف';
      case AppScreen.itemGroups:
        return 'مجموعات الأصناف';
      case AppScreen.units:
        return 'وحدات القياس';
      case AppScreen.warehousesList:
        return 'قائمة المخازن';
      case AppScreen.stockTransfer:
        return 'تحويل بين المخازن';
      case AppScreen.stockBalance:
        return 'رصيد المخزون';
      case AppScreen.stockAdjustment:
        return 'تسوية المخزون / الجرد';
      case AppScreen.stockDamage:
        return 'التالف والهالك';

      // ── الخزينة والبنوك ───────────────────────────────────
      case AppScreen.receiptVouchers:
        return 'سندات القبض';
      case AppScreen.paymentVouchers:
        return 'سندات الصرف';
      case AppScreen.paymentMethods:
        return 'طرق الدفع';
      case AppScreen.cashboxes:
        return 'الخزائن';
      case AppScreen.bankAccounts:
        return 'الحسابات البنكية';
      case AppScreen.chequesIn:
        return 'شيكات واردة';
      case AppScreen.chequesOut:
        return 'شيكات صادرة';
      case AppScreen.chequesDue:
        return 'شيكات مستحقة';
      case AppScreen.bankReconciliation:
        return 'التسويات البنكية';
    }
  }

  // ---------------- محتوى الشاشات ----------------
  Widget _buildContent(AppScreen screen) {
    switch (screen) {
      // ── شاشات جاهزة ───────────────────────────────────────
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

      // ── المحاسبة ──────────────────────────────────────────
      case AppScreen.chartOfAccounts:
        return const ChartOfAccountsScreen();
      case AppScreen.journalEntryNew:
        return const JournalEntryNewScreen();
      case AppScreen.journalEntriesList:
        return const JournalEntriesListScreen();
      case AppScreen.recurringJournals:
        return const _ComingSoon(title: 'القيود المتكررة', icon: Icons.repeat);
      case AppScreen.generalLedger:
        return const GeneralLedgerScreen();
      case AppScreen.trialBalance:
        return const TrialBalanceScreen();
      case AppScreen.profitLoss:
        return const ProfitLossScreen();
      case AppScreen.balanceSheet:
        return const BalanceSheetScreen();
      case AppScreen.cashFlow:
        return const CashFlowScreen();
      case AppScreen.costCenters:
        return const _ComingSoon(title: 'مراكز التكلفة / الفروع', icon: Icons.hub_outlined);
      case AppScreen.openingBalances:
        return const _ComingSoon(title: 'الأرصدة الافتتاحية', icon: Icons.play_circle_outline);

      // ── المبيعات ──────────────────────────────────────────
      case AppScreen.salesInvoiceNew:
        return const _ComingSoon(title: 'فاتورة بيع جديدة', icon: Icons.add);
      case AppScreen.salesInvoicesList:
        return const _ComingSoon(title: 'قائمة فواتير البيع', icon: Icons.list);
      case AppScreen.salesReturns:
        return const _ComingSoon(title: 'مرتجع المبيعات', icon: Icons.assignment_return_outlined);
      case AppScreen.quotations:
        return const _ComingSoon(title: 'عروض الأسعار', icon: Icons.request_quote_outlined);
      case AppScreen.salesOrders:
        return const _ComingSoon(title: 'أوامر البيع', icon: Icons.shopping_cart_outlined);
      case AppScreen.customersList:
        return const _ComingSoon(title: 'قائمة العملاء', icon: Icons.people_outline);
      case AppScreen.discounts:
        return const _ComingSoon(title: 'الخصومات والأسعار الخاصة', icon: Icons.percent);

      // ── المشتريات ─────────────────────────────────────────
      case AppScreen.purchaseInvoiceNew:
        return const _ComingSoon(title: 'فاتورة شراء جديدة', icon: Icons.add);
      case AppScreen.purchaseInvoicesList:
        return const _ComingSoon(title: 'قائمة فواتير الشراء', icon: Icons.list);
      case AppScreen.purchaseReturns:
        return const _ComingSoon(title: 'مرتجع المشتريات', icon: Icons.assignment_return_outlined);
      case AppScreen.purchaseOrders:
        return const _ComingSoon(title: 'أوامر الشراء', icon: Icons.shopping_cart_outlined);
      case AppScreen.suppliersList:
        return const _ComingSoon(title: 'قائمة الموردين', icon: Icons.local_shipping_outlined);

      // ── المخزون ───────────────────────────────────────────
      case AppScreen.itemsList:
        return const _ComingSoon(title: 'قائمة الأصناف', icon: Icons.list);
      case AppScreen.itemGroups:
        return const _ComingSoon(title: 'مجموعات الأصناف', icon: Icons.folder_outlined);
      case AppScreen.units:
        return const _ComingSoon(title: 'وحدات القياس', icon: Icons.straighten);
      case AppScreen.warehousesList:
        return const _ComingSoon(title: 'قائمة المخازن', icon: Icons.list);
      case AppScreen.stockTransfer:
        return const _ComingSoon(title: 'تحويل بين المخازن', icon: Icons.swap_horiz);
      case AppScreen.stockBalance:
        return const _ComingSoon(title: 'رصيد المخزون', icon: Icons.inventory);
      case AppScreen.stockAdjustment:
        return const _ComingSoon(title: 'تسوية المخزون / الجرد', icon: Icons.tune);
      case AppScreen.stockDamage:
        return const _ComingSoon(title: 'التالف والهالك', icon: Icons.delete_outline);

      // ── الخزينة والبنوك ───────────────────────────────────
      case AppScreen.receiptVouchers:
        return const _ComingSoon(title: 'سندات القبض', icon: Icons.call_received);
      case AppScreen.paymentVouchers:
        return const _ComingSoon(title: 'سندات الصرف', icon: Icons.call_made);
      case AppScreen.paymentMethods:
        return const _ComingSoon(title: 'طرق الدفع', icon: Icons.payment);
      case AppScreen.cashboxes:
        return const _ComingSoon(title: 'الخزائن', icon: Icons.savings_outlined);
      case AppScreen.bankAccounts:
        return const _ComingSoon(title: 'الحسابات البنكية', icon: Icons.account_balance);
      case AppScreen.chequesIn:
        return const _ComingSoon(title: 'شيكات واردة', icon: Icons.south_west);
      case AppScreen.chequesOut:
        return const _ComingSoon(title: 'شيكات صادرة', icon: Icons.north_east);
      case AppScreen.chequesDue:
        return const _ComingSoon(title: 'شيكات مستحقة', icon: Icons.schedule);
      case AppScreen.bankReconciliation:
        return const _ComingSoon(title: 'التسويات البنكية', icon: Icons.fact_check_outlined);
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

// ---------------- Placeholder للشاشات قيد التطوير ----------------
class _ComingSoon extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoon({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'هذه الشاشة قيد التطوير',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

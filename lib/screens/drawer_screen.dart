import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/sidebar_widget.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/sidebar_node.dart';

/// ---------------------------------------------------------------
/// شجرة القائمة الجانبية
/// ---------------------------------------------------------------
/// تربط العناصر بالشاشات الموجودة حالياً فقط.
/// العناصر التي لا شاشة لها تُعلَّم enabled: false.
List<SidebarNode> buildSidebarTree(L10n l10n) {
  return [
    // 🏠 لوحة التحكم
    SidebarNode(
      id: 'dashboard',
      title: l10n.dashboard,
      icon: Icons.dashboard_rounded,
      screen: AppScreen.dashboard,
    ),

    // 💰 المحاسبة
    SidebarNode(
      id: 'accounting',
      title: 'المحاسبة',
      icon: Icons.account_balance_outlined,
      type: SidebarNodeType.group,
      children: [
        SidebarNode(
          id: 'chart_of_accounts',
          title: 'دليل الحسابات',
          icon: Icons.account_tree_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'journal_entries',
          title: 'القيود اليومية',
          icon: Icons.edit_note_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'je_new',
              title: 'قيد جديد',
              icon: Icons.add,
              enabled: false,
            ),
            SidebarNode(
              id: 'je_list',
              title: 'قائمة القيود',
              icon: Icons.list,
              screen: AppScreen.transactions, // مؤقتاً
            ),
            SidebarNode(
              id: 'je_recurring',
              title: 'القيود المتكررة',
              icon: Icons.repeat,
              enabled: false,
            ),
          ],
        ),
        SidebarNode(
          id: 'general_ledger',
          title: 'الأستاذ العام',
          icon: Icons.menu_book_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'gl_ledger',
              title: 'دفتر الأستاذ',
              icon: Icons.book,
              screen: AppScreen.reports, // مؤقتاً
            ),
            SidebarNode(
              id: 'gl_trial',
              title: 'ميزان المراجعة',
              icon: Icons.balance,
              screen: AppScreen.reports, // مؤقتاً
            ),
          ],
        ),
        SidebarNode(
          id: 'financial_reports',
          title: 'التقارير المالية',
          icon: Icons.assessment_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'pnl',
              title: 'الأرباح والخسائر',
              icon: Icons.trending_up,
              screen: AppScreen.reports,
            ),
            SidebarNode(
              id: 'balance_sheet',
              title: 'الميزانية العمومية',
              icon: Icons.account_balance,
              screen: AppScreen.reports,
            ),
            SidebarNode(
              id: 'cash_flow',
              title: 'التدفقات النقدية',
              icon: Icons.swap_vert,
              screen: AppScreen.reports,
            ),
          ],
        ),
        SidebarNode(
          id: 'cost_centers',
          title: 'مراكز التكلفة / الفروع',
          icon: Icons.hub_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'opening_balances',
          title: 'الأرصدة الافتتاحية',
          icon: Icons.play_circle_outline,
          enabled: false,
        ),
      ],
    ),

    // 🧾 المبيعات
    SidebarNode(
      id: 'sales',
      title: 'المبيعات',
      icon: Icons.point_of_sale_outlined,
      type: SidebarNodeType.group,
      children: [
        SidebarNode(
          id: 'sales_invoices',
          title: 'فواتير البيع',
          icon: Icons.receipt_long_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'si_new',
              title: 'فاتورة جديدة',
              icon: Icons.add,
              enabled: false,
            ),
            SidebarNode(
              id: 'si_list',
              title: 'قائمة الفواتير',
              icon: Icons.list,
              screen: AppScreen.transactions, // مؤقتاً
            ),
          ],
        ),
        SidebarNode(
          id: 'sales_returns',
          title: 'مرتجع المبيعات',
          icon: Icons.assignment_return_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'quotations',
          title: 'عروض الأسعار',
          icon: Icons.request_quote_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'sales_orders',
          title: 'أوامر البيع',
          icon: Icons.shopping_cart_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'customers',
          title: 'العملاء',
          icon: Icons.people_outline,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'customers_list',
              title: 'قائمة العملاء',
              icon: Icons.list,
              enabled: false,
            ),
          ],
        ),
        SidebarNode(
          id: 'discounts',
          title: 'الخصومات والأسعار الخاصة',
          icon: Icons.percent,
          enabled: false,
        ),
      ],
    ),

    // 🛒 المشتريات
    SidebarNode(
      id: 'purchasing',
      title: 'المشتريات',
      icon: Icons.shopping_bag_outlined,
      type: SidebarNodeType.group,
      children: [
        SidebarNode(
          id: 'purchase_invoices',
          title: 'فواتير الشراء',
          icon: Icons.receipt_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'pi_new',
              title: 'فاتورة جديدة',
              icon: Icons.add,
              enabled: false,
            ),
            SidebarNode(
              id: 'pi_list',
              title: 'قائمة الفواتير',
              icon: Icons.list,
              screen: AppScreen.transactions, // مؤقتاً
            ),
          ],
        ),
        SidebarNode(
          id: 'purchase_returns',
          title: 'مرتجع المشتريات',
          icon: Icons.assignment_return_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'purchase_orders',
          title: 'أوامر الشراء',
          icon: Icons.shopping_cart_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'suppliers',
          title: 'الموردون',
          icon: Icons.local_shipping_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'suppliers_list',
              title: 'قائمة الموردين',
              icon: Icons.list,
              enabled: false,
            ),
          ],
        ),
      ],
    ),

    // 📦 المخزون
    SidebarNode(
      id: 'inventory',
      title: l10n.resources,
      icon: Icons.inventory_2_rounded,
      type: SidebarNodeType.group,
      children: [
        SidebarNode(
          id: 'items',
          title: 'الأصناف',
          icon: Icons.category_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'items_list',
              title: 'قائمة الأصناف',
              icon: Icons.list,
              screen: AppScreen.resources,
            ),
            SidebarNode(
              id: 'item_groups',
              title: 'مجموعات الأصناف',
              icon: Icons.folder_outlined,
              screen: AppScreen.resources,
            ),
            SidebarNode(
              id: 'units',
              title: 'وحدات القياس',
              icon: Icons.straighten,
              screen: AppScreen.resources,
            ),
          ],
        ),
        SidebarNode(
          id: 'warehouses',
          title: 'المخازن',
          icon: Icons.warehouse_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'warehouses_list',
              title: 'قائمة المخازن',
              icon: Icons.list,
              screen: AppScreen.resources,
            ),
            SidebarNode(
              id: 'stock_transfer',
              title: 'تحويل بين المخازن',
              icon: Icons.swap_horiz,
              screen: AppScreen.resources,
            ),
          ],
        ),
        SidebarNode(
          id: 'stock_movements',
          title: 'حركات المخزون',
          icon: Icons.sync_alt_outlined,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'stock_balance',
              title: 'رصيد المخزون',
              icon: Icons.inventory,
              screen: AppScreen.resources,
            ),
            SidebarNode(
              id: 'stock_adjustment',
              title: 'تسوية المخزون / الجرد',
              icon: Icons.tune,
              screen: AppScreen.resources,
            ),
            SidebarNode(
              id: 'stock_damage',
              title: 'التالف والهالك',
              icon: Icons.delete_outline,
              screen: AppScreen.resources,
            ),
          ],
        ),
      ],
    ),

    // 💵 الخزينة والبنوك
    SidebarNode(
      id: 'treasury',
      title: 'الخزينة والبنوك',
      icon: Icons.account_balance_wallet_outlined,
      type: SidebarNodeType.group,
      children: [
        SidebarNode(
          id: 'receipt_vouchers',
          title: 'سندات القبض',
          icon: Icons.call_received,
          enabled: false,
        ),
        SidebarNode(
          id: 'payment_vouchers',
          title: 'سندات الصرف',
          icon: Icons.call_made,
          enabled: false,
        ),
        SidebarNode(
          id: 'payment_methods',
          title: 'طرق الدفع',
          icon: Icons.payment,
          enabled: false,
        ),
        SidebarNode(
          id: 'cashboxes',
          title: 'الخزائن',
          icon: Icons.savings_outlined,
          enabled: false,
        ),
        SidebarNode(
          id: 'bank_accounts',
          title: 'الحسابات البنكية',
          icon: Icons.account_balance,
          enabled: false,
        ),
        SidebarNode(
          id: 'cheques',
          title: 'إدارة الشيكات',
          icon: Icons.receipt_long,
          type: SidebarNodeType.group,
          children: [
            SidebarNode(
              id: 'cheques_in',
              title: 'شيكات واردة',
              icon: Icons.south_west,
              enabled: false,
            ),
            SidebarNode(
              id: 'cheques_out',
              title: 'شيكات صادرة',
              icon: Icons.north_east,
              enabled: false,
            ),
            SidebarNode(
              id: 'cheques_due',
              title: 'شيكات مستحقة',
              icon: Icons.schedule,
              enabled: false,
            ),
          ],
        ),
        SidebarNode(
          id: 'bank_reconciliation',
          title: 'التسويات البنكية',
          icon: Icons.fact_check_outlined,
          enabled: false,
        ),
      ],
    ),

    // 📊 التحليلات
    SidebarNode(
      id: 'insights',
      title: l10n.insights,
      icon: Icons.lightbulb_rounded,
      screen: AppScreen.insights,
    ),

    // 📈 التقارير
    SidebarNode(
      id: 'reports',
      title: l10n.reports,
      icon: Icons.bar_chart_rounded,
      screen: AppScreen.reports,
    ),

    // ⚙️ الإعدادات
    SidebarNode(
      id: 'settings',
      title: l10n.settings,
      icon: Icons.settings_rounded,
      screen: AppScreen.settings,
    ),

    // ❓ المساعدة
    SidebarNode(
      id: 'help',
      title: l10n.help,
      icon: Icons.help_outline_rounded,
      screen: AppScreen.help,
    ),
  ];
}

/// ---------------------------------------------------------------
/// الشريط الجانبي الثابت (لشاشات كبيرة - isWide)
/// ---------------------------------------------------------------
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final tree = buildSidebarTree(l10n);

    return SidebarWidget(
      nodes: tree,
      selectedScreen: provider.currentScreen,
      onItemSelected: (screen) => provider.navigateTo(screen),
    );
  }
}

/// ---------------------------------------------------------------
/// الـ Drawer (لشاشات صغيرة)
/// ---------------------------------------------------------------
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final tree = buildSidebarTree(l10n);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  const Icon(
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

            // الشجرة
            Expanded(
              child: SidebarWidget(
                nodes: tree,
                selectedScreen: provider.currentScreen,
                showHeader: false,
                onItemSelected: (screen) {
                  provider.navigateTo(screen);
                  Navigator.pop(context);
                },
              ),
            ),

            // تذييل
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
}

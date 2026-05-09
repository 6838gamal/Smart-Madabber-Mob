import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/decision_card.dart';
import '../widgets/resource_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';
import '../models/resource.dart';
import '../models/rule.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      children: [
        _buildHeader(context, isDark, l10n),
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(text: l10n.today),
              Tab(text: l10n.trends),
              Tab(text: l10n.stock),
              Tab(text: l10n.intelligence),
            ],
          ),
        ),
        Divider(height: 1, color: border),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _TodayTab(),
              _TrendsTab(),
              _StockTab(),
              _IntelligenceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, L10n l10n) {
    final provider = context.watch<AppProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboard,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                l10n.intelligentOverview,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.refreshInsights(),
            tooltip: l10n.refreshInsights,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecisionCard(
            insight: provider.decisionOfTheDay,
            onDismiss: provider.decisionOfTheDay != null
                ? () => provider.resolveInsight(provider.decisionOfTheDay!.id)
                : null,
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: l10n.quickStats),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              StatCard(
                title: l10n.totalResources,
                value: provider.resources.length.toString(),
                icon: Icons.inventory_2_rounded,
                color: AppColors.primary,
                onTap: () => provider.navigateTo(AppScreen.resources),
              ),
              StatCard(
                title: l10n.activeAlerts,
                value: provider.activeInsights.length.toString(),
                subtitle: l10n.needAttention,
                icon: Icons.notifications_active_rounded,
                color: AppColors.warning,
                onTap: () => provider.navigateTo(AppScreen.insights),
              ),
              StatCard(
                title: l10n.critical,
                value: provider.criticalCount.toString(),
                subtitle: l10n.immediateAction,
                icon: Icons.warning_rounded,
                color: AppColors.critical,
              ),
              StatCard(
                title: l10n.lowStock,
                value: provider.lowStockCount.toString(),
                subtitle: l10n.restockSoon,
                icon: Icons.trending_down_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (provider.activeInsights.isNotEmpty) ...[
            _SectionTitle(
              title: l10n.activeAlerts,
              trailing: TextButton(
                onPressed: () => provider.navigateTo(AppScreen.insights),
                child: Text(l10n.seeAll),
              ),
            ),
            const SizedBox(height: 12),
            ...provider.activeInsights.take(3).map((i) => InsightCard(
                  insight: i,
                  compact: true,
                )),
          ],
        ],
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recent7 = provider.recentTransactions(days: 7);
    final recent30 = provider.recentTransactions(days: 30);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.spent30d,
                  value: provider.formatAmount(provider.totalSpent(days: 30)),
                  icon: Icons.shopping_cart_rounded,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: l10n.revenue30d,
                  value:
                      provider.formatAmount(provider.totalRevenue(days: 30)),
                  icon: Icons.attach_money_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.txns7d,
                  value: recent7.length.toString(),
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: l10n.txns30d,
                  value: recent30.length.toString(),
                  icon: Icons.history_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: l10n.recentActivity),
          const SizedBox(height: 12),
          if (recent7.isEmpty)
            EmptyState(
              emoji: '📊',
              title: l10n.noRecentTransactions,
              subtitle: l10n.addTransactionsForTrends,
            )
          else
            ...recent7.take(10).map((txn) {
              final resource = provider.resources
                  .where((r) => r.id == txn.resourceId)
                  .firstOrNull;
              final resourceName = resource?.name ?? '—';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Text(txn.type.emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resourceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${txn.type.label} · ${txn.quantity.toStringAsFixed(1)} ${l10n.units}',
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
                    if (txn.price > 0)
                      Text(
                        provider.formatAmount(txn.price),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: txn.type.name == 'sale'
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StockTab extends StatelessWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final resources = provider.resources;
    final critical =
        resources.where((r) => r.status == ResourceStatus.critical).toList();
    final low =
        resources.where((r) => r.status == ResourceStatus.low).toList();
    final normal =
        resources.where((r) => r.status == ResourceStatus.normal).toList();
    final inactive =
        resources.where((r) => r.status == ResourceStatus.inactive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (critical.isNotEmpty) ...[
            _SectionTitle(
                title: '${l10n.criticalSection} (${critical.length})'),
            const SizedBox(height: 12),
            _ResourceGrid(resources: critical,
                onTap: () => provider.navigateTo(AppScreen.resources)),
            const SizedBox(height: 20),
          ],
          if (low.isNotEmpty) ...[
            _SectionTitle(
                title: '${l10n.lowStockSection} (${low.length})'),
            const SizedBox(height: 12),
            _ResourceGrid(resources: low),
            const SizedBox(height: 20),
          ],
          if (inactive.isNotEmpty) ...[
            _SectionTitle(
                title: '${l10n.inactiveSection} (${inactive.length})'),
            const SizedBox(height: 12),
            _ResourceGrid(resources: inactive),
            const SizedBox(height: 20),
          ],
          if (normal.isNotEmpty) ...[
            _SectionTitle(
                title: '${l10n.normalSection} (${normal.length})'),
            const SizedBox(height: 12),
            _ResourceGrid(resources: normal),
          ],
          if (resources.isEmpty)
            EmptyState(
              emoji: '📦',
              title: l10n.noResourcesYet,
              subtitle: l10n.addResourcesToTrack,
            ),
        ],
      ),
    );
  }
}

class _ResourceGrid extends StatelessWidget {
  final List<Resource> resources;
  final VoidCallback? onTap;
  const _ResourceGrid({required this.resources, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: resources.length,
      itemBuilder: (_, i) => ResourceCard(resource: resources[i], onTap: onTap),
    );
  }
}

class _IntelligenceTab extends StatelessWidget {
  const _IntelligenceTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded,
                    color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.engineDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
              title:
                  '${l10n.activeRulesLabel} (${provider.rules.where((r) => r.enabled).length})'),
          const SizedBox(height: 12),
          ...provider.rules.map((rule) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      rule.enabled
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: rule.enabled
                          ? AppColors.success
                          : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rule.conditionType.description,
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
                    _SeverityPill(severity: rule.severity),
                    const SizedBox(width: 8),
                    Switch(
                      value: rule.enabled,
                      onChanged: (_) => provider.toggleRule(rule.id),
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          _SectionTitle(title: l10n.engineSummary),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
            children: [
              StatCard(
                title: l10n.insightsGenerated,
                value: provider.insights.length.toString(),
                icon: Icons.auto_awesome_rounded,
                color: AppColors.info,
              ),
              StatCard(
                title: l10n.active,
                value: provider.activeInsights.length.toString(),
                icon: Icons.notifications_active_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                title: l10n.rulesActive,
                value: provider.rules
                    .where((r) => r.enabled)
                    .length
                    .toString(),
                icon: Icons.rule_rounded,
                color: AppColors.success,
              ),
              StatCard(
                title: l10n.totalRulesLabel,
                value: provider.rules.length.toString(),
                icon: Icons.settings_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final RuleSeverity severity;
  const _SeverityPill({required this.severity});

  Color get _color {
    switch (severity) {
      case RuleSeverity.critical:
        return AppColors.critical;
      case RuleSeverity.high:
        return AppColors.danger;
      case RuleSeverity.medium:
        return AppColors.warning;
      case RuleSeverity.low:
        return AppColors.normal;
      case RuleSeverity.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../models/resource.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 30;

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
          _buildPageHeader(isDark, provider, l10n),
          const SizedBox(height: 20),
          _buildPeriodSelector(isDark, l10n),
          const SizedBox(height: 20),
          _buildSummaryCards(provider, l10n),
          const SizedBox(height: 24),
          _buildResourceStatusChart(isDark, provider, l10n),
          const SizedBox(height: 24),
          _buildTransactionTypeChart(isDark, provider, l10n),
          const SizedBox(height: 24),
          _buildTopResourcesTable(isDark, provider, l10n),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isDark, AppProvider provider, L10n l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reports,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            Text(
              l10n.dataAtAGlance,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(bool isDark, L10n l10n) {
    final periods = {
      7: l10n.last7Days,
      30: l10n.last30Days,
      90: l10n.last90Days,
    };
    return Row(
      children: [
        ...periods.entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _days = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _days == e.key
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _days == e.key
                          ? AppColors.primary
                          : isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _days == e.key
                          ? Colors.white
                          : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSummaryCards(AppProvider provider, L10n l10n) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        StatCard(
          title: l10n.totalSpentLabel,
          value: provider.formatAmount(provider.totalSpent(days: _days)),
          subtitle: l10n.isAr ? 'آخر $_days يوم' : 'Last $_days days',
          icon: Icons.shopping_cart_rounded,
          color: AppColors.danger,
        ),
        StatCard(
          title: l10n.totalRevenueLabel,
          value: provider.formatAmount(provider.totalRevenue(days: _days)),
          subtitle: l10n.isAr ? 'آخر $_days يوم' : 'Last $_days days',
          icon: Icons.attach_money_rounded,
          color: AppColors.success,
        ),
        StatCard(
          title: l10n.resources,
          value: provider.resources.length.toString(),
          subtitle:
              '${provider.criticalCount + provider.lowStockCount} ${l10n.needAttention}',
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          title: l10n.transactionsCountLabel,
          value: provider.recentTransactions(days: _days).length.toString(),
          subtitle: l10n.isAr ? 'آخر $_days يوم' : 'Last $_days days',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildResourceStatusChart(
      bool isDark, AppProvider provider, L10n l10n) {
    final normal = provider.resources
        .where((r) => r.status == ResourceStatus.normal)
        .length;
    final low = provider.resources
        .where((r) => r.status == ResourceStatus.low)
        .length;
    final critical = provider.resources
        .where((r) => r.status == ResourceStatus.critical)
        .length;
    final inactive = provider.resources
        .where((r) => r.status == ResourceStatus.inactive)
        .length;

    if (provider.resources.isEmpty) return const SizedBox();

    return _Card(
      isDark: isDark,
      title: l10n.resourceHealth,
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (normal > 0)
                      PieChartSectionData(
                        value: normal.toDouble(),
                        color: AppColors.success,
                        title: '$normal',
                        radius: 50,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    if (low > 0)
                      PieChartSectionData(
                        value: low.toDouble(),
                        color: AppColors.warning,
                        title: '$low',
                        radius: 50,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    if (critical > 0)
                      PieChartSectionData(
                        value: critical.toDouble(),
                        color: AppColors.critical,
                        title: '$critical',
                        radius: 50,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    if (inactive > 0)
                      PieChartSectionData(
                        value: inactive.toDouble(),
                        color: AppColors.inactive,
                        title: '$inactive',
                        radius: 50,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(
                    color: AppColors.success,
                    label: l10n.normal,
                    count: normal),
                const SizedBox(height: 8),
                _Legend(
                    color: AppColors.warning,
                    label: l10n.low,
                    count: low),
                const SizedBox(height: 8),
                _Legend(
                    color: AppColors.critical,
                    label: l10n.critical,
                    count: critical),
                const SizedBox(height: 8),
                _Legend(
                    color: AppColors.inactive,
                    label: l10n.inactive,
                    count: inactive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeChart(
      bool isDark, AppProvider provider, L10n l10n) {
    final txns = provider.recentTransactions(days: _days);
    if (txns.isEmpty) return const SizedBox();

    final purchases =
        txns.where((t) => t.type == TransactionType.purchase).length;
    final consumes =
        txns.where((t) => t.type == TransactionType.consume).length;
    final sales =
        txns.where((t) => t.type == TransactionType.sale).length;

    final groups = [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(
            toY: purchases.toDouble(),
            color: AppColors.primary,
            width: 28,
            borderRadius: BorderRadius.circular(4))
      ]),
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(
            toY: consumes.toDouble(),
            color: AppColors.warning,
            width: 28,
            borderRadius: BorderRadius.circular(4))
      ]),
      BarChartGroupData(x: 2, barRods: [
        BarChartRodData(
            toY: sales.toDouble(),
            color: AppColors.success,
            width: 28,
            borderRadius: BorderRadius.circular(4))
      ]),
    ];

    final barLabels = l10n.isAr
        ? ['مشتريات', 'استهلاك', 'مبيعات']
        : ['Purchases', 'Consumed', 'Sales'];

    return _Card(
      isDark: isDark,
      title: '${l10n.transactionSummary} (${_days}d)',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: ([purchases, consumes, sales]
                        .reduce((a, b) => a > b ? a : b) *
                    1.3)
                .toDouble(),
            barGroups: groups,
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (v) => FlLine(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                strokeWidth: 1,
              ),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= barLabels.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        barLabels[idx],
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopResourcesTable(
      bool isDark, AppProvider provider, L10n l10n) {
    final resources = List.from(provider.resources)
      ..sort((a, b) =>
          b.dailyConsumptionRate.compareTo(a.dailyConsumptionRate));

    return _Card(
      isDark: isDark,
      title: l10n.topResourcesByConsumption,
      child: Column(
        children: resources.take(5).map((r) {
          final pct = r.stockPercentage;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _statusColor(r.status)),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.currentQuantity.toStringAsFixed(1)}/${r.minThreshold} ${r.unit}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  r.dailyConsumptionRate > 0
                      ? '${r.dailyConsumptionRate.toStringAsFixed(1)}/d'
                      : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statusColor(ResourceStatus s) {
    switch (s) {
      case ResourceStatus.critical:
        return AppColors.critical;
      case ResourceStatus.low:
        return AppColors.warning;
      case ResourceStatus.inactive:
        return AppColors.inactive;
      case ResourceStatus.normal:
        return AppColors.success;
    }
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _Card(
      {required this.isDark, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

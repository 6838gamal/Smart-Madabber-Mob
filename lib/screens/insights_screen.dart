import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/insight.dart';
import '../models/rule.dart';
import '../widgets/insight_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insights',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.refreshInsights(),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                      text:
                          'Active (${provider.insights.where((i) => i.isActive).length})'),
                  Tab(
                      text:
                          'Resolved (${provider.insights.where((i) => i.status == InsightStatus.resolved).length})'),
                  Tab(
                      text:
                          'Dismissed (${provider.insights.where((i) => i.status == InsightStatus.dismissed).length})'),
                ],
              ),
            ],
          ),
        ),
        Divider(
            height: 1,
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _InsightList(
                insights: provider.insights
                    .where((i) => i.isActive)
                    .toList(),
                onDismiss: (id) =>
                    provider.dismissInsight(id),
                onResolve: (id) =>
                    provider.resolveInsight(id),
                empty: const EmptyState(
                  emoji: '🎉',
                  title: 'No active insights',
                  subtitle:
                      'All systems are running smoothly. The engine found no issues.',
                ),
              ),
              _InsightList(
                insights: provider.insights
                    .where((i) =>
                        i.status == InsightStatus.resolved)
                    .toList(),
                empty: const EmptyState(
                  emoji: '✅',
                  title: 'No resolved insights',
                  subtitle: 'Resolved insights will appear here.',
                ),
              ),
              _InsightList(
                insights: provider.insights
                    .where((i) =>
                        i.status == InsightStatus.dismissed)
                    .toList(),
                empty: const EmptyState(
                  emoji: '🗑️',
                  title: 'No dismissed insights',
                  subtitle:
                      'Dismissed insights will appear here.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightList extends StatelessWidget {
  final List<Insight> insights;
  final void Function(String)? onDismiss;
  final void Function(String)? onResolve;
  final Widget empty;

  const _InsightList({
    required this.insights,
    this.onDismiss,
    this.onResolve,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return empty;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: insights.length,
      itemBuilder: (_, i) => InsightCard(
        insight: insights[i],
        onDismiss:
            onDismiss != null ? () => onDismiss!(insights[i].id) : null,
        onResolve:
            onResolve != null ? () => onResolve!(insights[i].id) : null,
      ),
    );
  }
}

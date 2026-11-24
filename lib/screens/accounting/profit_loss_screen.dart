import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, 1, 1);
    _to = now;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final data = _compute(provider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _buildPeriodPicker(context),
          const SizedBox(height: 12),
          _buildSection(
            'الإيرادات',
            data.revenues,
            data.totalRevenue,
            Colors.green,
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _buildSection(
            'المصروفات',
            data.expenses,
            data.totalExpense,
            Colors.red,
            Icons.trending_down,
          ),
          const SizedBox(height: 12),
          _buildNetResult(provider, data),
        ],
      ),
    );
  }

  // ── Period picker ───────────────────────────────────────
  Widget _buildPeriodPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isFrom: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'من',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event, size: 18),
                      ),
                      child: Text(
                        _from == null ? '—' : _formatDate(_from!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isFrom: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'إلى',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event, size: 18),
                      ),
                      child: Text(_to == null ? '—' : _formatDate(_to!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip('هذا الشهر', _QuickPeriod.thisMonth),
                  const SizedBox(width: 6),
                  _quickChip('هذا الربع', _QuickPeriod.thisQuarter),
                  const SizedBox(width: 6),
                  _quickChip('هذه السنة', _QuickPeriod.thisYear),
                  const SizedBox(width: 6),
                  _quickChip('الشهر الماضي', _QuickPeriod.lastMonth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, _QuickPeriod q) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        final now = DateTime.now();
        setState(() {
          switch (q) {
            case _QuickPeriod.thisMonth:
              _from = DateTime(now.year, now.month, 1);
              _to = now;
              break;
            case _QuickPeriod.thisQuarter:
              final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
              _from = DateTime(now.year, qStart, 1);
              _to = now;
              break;
            case _QuickPeriod.thisYear:
              _from = DateTime(now.year, 1, 1);
              _to = now;
              break;
            case _QuickPeriod.lastMonth:
              final prev = DateTime(now.year, now.month - 1, 1);
              _from = prev;
              _to = DateTime(now.year, now.month, 0, 23, 59, 59);
              break;
          }
        });
      },
    );
  }

  // ── Section (إيرادات / مصروفات) ──────────────────────────
  Widget _buildSection(
    String title,
    List<_PLRow> rows,
    double total,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  _fmt(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد حركات في هذه الفترة',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            )
          else
            ...rows.map((r) => _buildRow(r, isDark)),
        ],
      ),
    );
  }

  Widget _buildRow(_PLRow r, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            r.account.code,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.account.name,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _fmt(r.amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Net result ──────────────────────────────────────────
  Widget _buildNetResult(AppProvider provider, _PLData data) {
    final isProfit = data.net >= 0;
    final color = isProfit ? Colors.green : Colors.red;
    final label = isProfit ? 'صافي الربح' : 'صافي الخسارة';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isProfit ? Icons.emoji_emotions_outlined : Icons.sentiment_dissatisfied,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(data.net.abs()),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compute ─────────────────────────────────────────────
  _PLData _compute(AppProvider provider) {
    final totals = provider.totalsByAccount(from: _from, to: _to);

    final revenues = <_PLRow>[];
    final expenses = <_PLRow>[];
    double totalRevenue = 0;
    double totalExpense = 0;

    for (final acc in provider.sortedAccounts) {
      final t = totals[acc.id];
      if (t == null) continue;
      final net = t.debit - t.credit;

      if (acc.type == AccountType.revenue) {
        // الإيرادات طبيعتها دائن → الرصيد = -net
        final amount = -net;
        if (amount.abs() < 0.01) continue;
        revenues.add(_PLRow(account: acc, amount: amount));
        totalRevenue += amount;
      } else if (acc.type == AccountType.expense) {
        // المصروفات طبيعتها مدين → الرصيد = net
        final amount = net;
        if (amount.abs() < 0.01) continue;
        expenses.add(_PLRow(account: acc, amount: amount));
        totalExpense += amount;
      }
    }

    return _PLData(
      revenues: revenues,
      expenses: expenses,
      totalRevenue: totalRevenue,
      totalExpense: totalExpense,
      net: totalRevenue - totalExpense,
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  String _fmt(double v) {
    if (v.abs() < 0.01) return '0';
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final sign = v < 0 ? '-' : '';
    return '$sign${buf.toString()}.$decPart';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final init = isFrom ? (_from ?? now) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

enum _QuickPeriod { thisMonth, thisQuarter, thisYear, lastMonth }

class _PLRow {
  final Account account;
  final double amount;
  const _PLRow({required this.account, required this.amount});
}

class _PLData {
  final List<_PLRow> revenues;
  final List<_PLRow> expenses;
  final double totalRevenue;
  final double totalExpense;
  final double net;

  const _PLData({
    required this.revenues,
    required this.expenses,
    required this.totalRevenue,
    required this.totalExpense,
    required this.net,
  });
}

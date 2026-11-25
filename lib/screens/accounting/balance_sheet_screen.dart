import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
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
            'الأصول',
            data.assets,
            data.totalAssets,
            const Color(0xFF1976D2),
            Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 8),
          _buildSection(
            'الخصوم',
            data.liabilities,
            data.totalLiabilities,
            const Color(0xFFD32F2F),
            Icons.trending_down,
          ),
          const SizedBox(height: 8),
          _buildEquitySection(provider, data),
          const SizedBox(height: 12),
          _buildBalanceCheck(provider, data),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'الميزانية كما في تاريخ',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event, size: 18),
                ),
                child: Text(
                  _to == null ? '—' : _formatDate(_to!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip('اليوم', _QuickDate.today),
                  const SizedBox(width: 6),
                  _quickChip('نهاية الشهر', _QuickDate.endOfMonth),
                  const SizedBox(width: 6),
                  _quickChip('نهاية السنة', _QuickDate.endOfYear),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, _QuickDate q) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        final now = DateTime.now();
        setState(() {
          switch (q) {
            case _QuickDate.today:
              _to = now;
              break;
            case _QuickDate.endOfMonth:
              _to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
              break;
            case _QuickDate.endOfYear:
              _to = DateTime(now.year, 12, 31, 23, 59, 59);
              break;
          }
        });
      },
    );
  }

  // ── Section (أصول / خصوم) ─────────────────────────────────
  Widget _buildSection(
    String title,
    List<_BSRow> rows,
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
                'لا توجد أرصدة',
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

  // ── Equity Section (حقوق الملكية + صافي الربح) ────────────
  Widget _buildEquitySection(AppProvider provider, _BSData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Color(0xFF7B1FA2);
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
                const Icon(Icons.pie_chart_outline, color: color, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'حقوق الملكية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  _fmt(data.totalEquity + data.netProfit),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (data.equity.isEmpty && data.netProfit.abs() < 0.01)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد أرصدة',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            )
          else ...[
            ...data.equity.map((r) => _buildRow(r, isDark)),
            // صافي الربح/الخسارة كسطر إضافي
            if (data.netProfit.abs() >= 0.01)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    const Icon(Icons.trending_up,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.netProfit >= 0
                            ? 'صافي الربح (غير مرحّل)'
                            : 'صافي الخسارة (غير مرحّلة)',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: data.netProfit >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    Text(
                      _fmt(data.netProfit.abs()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: data.netProfit >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(_BSRow r, bool isDark) {
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

  // ── Balance check ───────────────────────────────────────
  Widget _buildBalanceCheck(AppProvider provider, _BSData data) {
    final rightSide = data.totalLiabilities + data.totalEquity + data.netProfit;
    final diff = (data.totalAssets - rightSide).abs();
    final balanced = diff < 0.01;
    final color = balanced ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                balanced ? Icons.check_circle : Icons.error_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  balanced
                      ? 'الميزانية متوازنة ✓'
                      : 'الميزانية غير متوازنة — فرق: ${_fmt(diff)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _summarySide(
                  'الأصول',
                  data.totalAssets,
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summarySide(
                  'الخصوم + حقوق الملكية',
                  rightSide,
                  const Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summarySide(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Compute ─────────────────────────────────────────────
  _BSData _compute(AppProvider provider) {
    final totals = provider.totalsByAccount(to: _to);

    final assets = <_BSRow>[];
    final liabilities = <_BSRow>[];
    final equity = <_BSRow>[];
    double totalAssets = 0;
    double totalLiabilities = 0;
    double totalEquity = 0;
    double totalRevenue = 0;
    double totalExpense = 0;

    for (final acc in provider.sortedAccounts) {
      final t = totals[acc.id];
      if (t == null) continue;
      final net = t.debit - t.credit;

      switch (acc.type) {
        case AccountType.asset:
          // الأصول طبيعتها مدين → الرصيد = net
          if (net.abs() < 0.01) break;
          assets.add(_BSRow(account: acc, amount: net));
          totalAssets += net;
          break;
        case AccountType.liability:
          // الخصوم طبيعتها دائن → الرصيد = -net
          if (net.abs() < 0.01) break;
          final amount = -net;
          liabilities.add(_BSRow(account: acc, amount: amount));
          totalLiabilities += amount;
          break;
        case AccountType.equity:
          // حقوق الملكية طبيعتها دائن → الرصيد = -net
          if (net.abs() < 0.01) break;
          final amount = -net;
          equity.add(_BSRow(account: acc, amount: amount));
          totalEquity += amount;
          break;
        case AccountType.revenue:
          // تُجمّع لصافي الربح فقط
          totalRevenue += -net;
          break;
        case AccountType.expense:
          totalExpense += net;
          break;
      }
    }

    return _BSData(
      assets: assets,
      liabilities: liabilities,
      equity: equity,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquity,
      netProfit: totalRevenue - totalExpense,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _to = picked);
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

enum _QuickDate { today, endOfMonth, endOfYear }

class _BSRow {
  final Account account;
  final double amount;
  const _BSRow({required this.account, required this.amount});
}

class _BSData {
  final List<_BSRow> assets;
  final List<_BSRow> liabilities;
  final List<_BSRow> equity;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double netProfit;

  const _BSData({
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.netProfit,
  });
}

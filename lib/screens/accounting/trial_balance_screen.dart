import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  DateTime? _from;
  DateTime? _to;
  bool _showZeroBalances = false;
  bool _leafOnly = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final rows = _computeRows(provider);

    final totalDebit =
        rows.fold<double>(0, (s, r) => s + r.debitBalance);
    final totalCredit =
        rows.fold<double>(0, (s, r) => s + r.creditBalance);
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context),
          _buildSummary(context, totalDebit, totalCredit, balanced),
          Expanded(
            child: rows.isEmpty
                ? _buildEmpty(context)
                : _buildTable(provider, rows),
          ),
        ],
      ),
    );
  }

  // ── Toolbar: فترة + خيارات ───────────────────────────────
  Widget _buildToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isFrom: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'من تاريخ',
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
                      labelText: 'إلى تاريخ',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event, size: 18),
                    ),
                    child: Text(_to == null ? '—' : _formatDate(_to!)),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'مسح الفترة',
                icon: const Icon(Icons.clear),
                onPressed: (_from == null && _to == null)
                    ? null
                    : () => setState(() {
                          _from = null;
                          _to = null;
                        }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              FilterChip(
                label: const Text(
                  'الحسابات الورقية فقط',
                  style: TextStyle(fontSize: 11),
                ),
                selected: _leafOnly,
                onSelected: (v) => setState(() => _leafOnly = v),
                selectedColor: AppColors.primary.withOpacity(0.18),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text(
                  'إظهار الأرصدة الصفرية',
                  style: TextStyle(fontSize: 11),
                ),
                selected: _showZeroBalances,
                onSelected: (v) => setState(() => _showZeroBalances = v),
                selectedColor: AppColors.primary.withOpacity(0.18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary ────────────────────────────────────────────
  Widget _buildSummary(
    BuildContext context,
    double totalDebit,
    double totalCredit,
    bool balanced,
  ) {
    final color = balanced ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            balanced ? Icons.check_circle : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balanced
                      ? 'الميزان متوازن ✓'
                      : 'الميزان غير متوازن — فرق: '
                          '${(totalDebit - totalCredit).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _summaryItem('مدين', totalDebit, Colors.green),
                    const SizedBox(width: 16),
                    _summaryItem('دائن', totalCredit, Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: color),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Table ──────────────────────────────────────────────
  Widget _buildTable(AppProvider provider, List<_TbRow> rows) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      itemCount: rows.length + 1, // +1 لرأس الجدول
      itemBuilder: (_, i) {
        if (i == 0) return _buildHeaderRow(isDark);
        return _buildDataRow(provider, rows[i - 1], isDark);
      },
    );
  }

  Widget _buildHeaderRow(bool isDark) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : Colors.black54,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('الرمز', style: style)),
          Expanded(flex: 4, child: Text('الحساب', style: style)),
          Expanded(
            flex: 2,
            child: Text(
              'مدين',
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'دائن',
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(AppProvider provider, _TbRow r, bool isDark) {
    final account = r.account;
    final typeColor = _typeColor(account.type);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              account.code,
              style: TextStyle(
                fontSize: 11,
                color: typeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  account.type.labelAr,
                  style: TextStyle(
                    fontSize: 10,
                    color: typeColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.debitBalance > 0.01
                  ? provider.formatAmount(r.debitBalance)
                  : '—',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.creditBalance > 0.01
                  ? provider.formatAmount(r.creditBalance)
                  : '—',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.balance_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أرصدة للعرض',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف قيوداً أو وسّع الفترة الزمنية',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Computation ────────────────────────────────────────
  List<_TbRow> _computeRows(AppProvider provider) {
    final totals = provider.totalsByAccount(from: _from, to: _to);

    // اختر الحسابات المعروضة
    final accounts = _leafOnly
        ? provider.leafAccounts
        : provider.sortedAccounts;

    final rows = <_TbRow>[];
    for (final acc in accounts) {
      final t = totals[acc.id];
      final debitTotal = t?.debit ?? 0;
      final creditTotal = t?.credit ?? 0;
      // صافي الرصيد: موجب = مدين، سالب = دائن
      final net = debitTotal - creditTotal;

      final debitBalance = net > 0 ? net : 0.0;
      final creditBalance = net < 0 ? -net : 0.0;

      if (!_showZeroBalances && net.abs() < 0.01) continue;

      rows.add(_TbRow(
        account: acc,
        debit: debitTotal,
        credit: creditTotal,
        debitBalance: debitBalance,
        creditBalance: creditBalance,
      ));
    }
    return rows;
  }

  // ── Date pickers ───────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final init = isFrom
        ? (_from ?? DateTime(now.year, 1, 1))
        : (_to ?? now);
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

  Color _typeColor(AccountType t) {
    switch (t) {
      case AccountType.asset:
        return const Color(0xFF1976D2);
      case AccountType.liability:
        return const Color(0xFFD32F2F);
      case AccountType.equity:
        return const Color(0xFF7B1FA2);
      case AccountType.revenue:
        return const Color(0xFF2E7D32);
      case AccountType.expense:
        return const Color(0xFFEF6C00);
    }
  }
}

// ── صف ميزان المراجعة ──────────────────────────────────────
class _TbRow {
  final Account account;
  final double debit;
  final double credit;
  final double debitBalance;
  final double creditBalance;

  const _TbRow({
    required this.account,
    required this.debit,
    required this.credit,
    required this.debitBalance,
    required this.creditBalance,
  });
}

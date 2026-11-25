import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_theme.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
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
          _buildOpeningCard(provider, data),
          const SizedBox(height: 8),
          _buildActivitySection(
            'الأنشطة التشغيلية',
            data.operating,
            data.totalOperating,
            const Color(0xFF2E7D32),
            Icons.settings_outlined,
          ),
          const SizedBox(height: 8),
          _buildActivitySection(
            'الأنشطة الاستثمارية',
            data.investing,
            data.totalInvesting,
            const Color(0xFF1976D2),
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _buildActivitySection(
            'الأنشطة التمويلية',
            data.financing,
            data.totalFinancing,
            const Color(0xFF7B1FA2),
            Icons.account_balance,
          ),
          const SizedBox(height: 12),
          _buildClosingCard(provider, data),
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
          }
        });
      },
    );
  }

  // ── Opening balance card ────────────────────────────────
  Widget _buildOpeningCard(AppProvider provider, _CFData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'الرصيد النقدي الافتتاحي',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            provider.formatAmount(data.openingCash),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity section ────────────────────────────────────
  Widget _buildActivitySection(
    String title,
    List<_CFRow> rows,
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
                'لا توجد حركات في هذه الفئة',
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

  Widget _buildRow(_CFRow r, bool isDark) {
    final isInflow = r.amount >= 0;
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
          Icon(
            isInflow ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: isInflow ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              r.label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _fmt(r.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isInflow ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ── Closing card ────────────────────────────────────────
  Widget _buildClosingCard(AppProvider provider, _CFData data) {
    final netChange = data.totalOperating +
        data.totalInvesting +
        data.totalFinancing;
    final closing = data.openingCash + netChange;
    final positive = netChange >= 0;
    final color = positive ? Colors.green : Colors.red;

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
                positive ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'صافي التغير النقدي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              Text(
                _fmt(netChange),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.blueGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'الرصيد النقدي الختامي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                provider.formatAmount(closing),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Compute ─────────────────────────────────────────────
  _CFData _compute(AppProvider provider) {
    final entries = provider.entriesInRange(from: _from, to: _to);
    final cashIds = provider.cashAccounts.map((a) => a.id).toSet();

    // الرصيد الافتتاحي: كل الحركات النقدية قبل `from`
    double openingCash = 0;
    if (_from != null) {
      for (final entry in provider.journalEntries) {
        if (!entry.date.isBefore(_from!)) continue;
        for (final line in entry.lines) {
          if (!cashIds.contains(line.accountId)) continue;
          openingCash += line.debit - line.credit;
        }
      }
    }

    // تجميع الحركات النقدية حسب "الحساب المقابل"
    final operating = <String, double>{};
    final investing = <String, double>{};
    final financing = <String, double>{};

    for (final entry in entries) {
      // هل يحتوي القيد على حساب نقدي؟
      final cashLines =
          entry.lines.where((l) => cashIds.contains(l.accountId)).toList();
      if (cashLines.isEmpty) continue;

      final nonCashLines =
          entry.lines.where((l) => !cashIds.contains(l.accountId)).toList();
      if (nonCashLines.isEmpty) continue;

      // الحركة النقدية الصافية
      final cashDelta = cashLines.fold<double>(
        0,
        (s, l) => s + l.debit - l.credit,
      );
      if (cashDelta.abs() < 0.01) continue;

      // التصنيف حسب الحساب المقابل
      // نأخذ الحساب المقابل ذا أكبر مبلغ (لتجنب التشتيت)
      nonCashLines.sort((a, b) {
        final ma = (a.debit - a.credit).abs();
        final mb = (b.debit - b.credit).abs();
        return mb.compareTo(ma);
      });
      final counterpart = nonCashLines.first;
      final counterpartAcc = provider.accountById(counterpart.accountId);
      if (counterpartAcc == null) continue;

      final classification = _classify(counterpartAcc);
      final label = counterpartAcc.name;

      switch (classification) {
        case _CFClass.operating:
          operating[label] = (operating[label] ?? 0) + cashDelta;
          break;
        case _CFClass.investing:
          investing[label] = (investing[label] ?? 0) + cashDelta;
          break;
        case _CFClass.financing:
          financing[label] = (financing[label] ?? 0) + cashDelta;
          break;
      }
    }

    final operatingRows = _toRows(operating);
    final investingRows = _toRows(investing);
    final financingRows = _toRows(financing);

    return _CFData(
      openingCash: openingCash,
      operating: operatingRows,
      investing: investingRows,
      financing: financingRows,
      totalOperating: operatingRows.fold(0.0, (s, r) => s + r.amount),
      totalInvesting: investingRows.fold(0.0, (s, r) => s + r.amount),
      totalFinancing: financingRows.fold(0.0, (s, r) => s + r.amount),
    );
  }

  List<_CFRow> _toRows(Map<String, double> m) {
    return m.entries
        .where((e) => e.value.abs() >= 0.01)
        .map((e) => _CFRow(label: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
  }

  _CFClass _classify(Account account) {
    switch (account.type) {
      case AccountType.revenue:
      case AccountType.expense:
        // إيرادات ومصروفات = تشغيلية
        return _CFClass.operating;
      case AccountType.asset:
        // أصول أخرى (غير النقدية) = استثمارية
        return _CFClass.investing;
      case AccountType.liability:
        // خصوم طويلة الأجل = تمويلية
        // لكن لو كانت قصيرة الأجل قد تكون تشغيلية — نعتمد على الاسم
        if (account.name.contains('قرض') ||
            account.name.contains('سلفة') ||
            account.name.contains('رأس مال')) {
          return _CFClass.financing;
        }
        return _CFClass.operating;
      case AccountType.equity:
        return _CFClass.financing;
    }
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

enum _QuickPeriod { thisMonth, thisQuarter, thisYear }

enum _CFClass { operating, investing, financing }

class _CFRow {
  final String label;
  final double amount;
  const _CFRow({required this.label, required this.amount});
}

class _CFData {
  final double openingCash;
  final List<_CFRow> operating;
  final List<_CFRow> investing;
  final List<_CFRow> financing;
  final double totalOperating;
  final double totalInvesting;
  final double totalFinancing;

  const _CFData({
    required this.openingCash,
    required this.operating,
    required this.investing,
    required this.financing,
    required this.totalOperating,
    required this.totalInvesting,
    required this.totalFinancing,
  });
}

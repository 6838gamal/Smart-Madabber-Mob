import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';

class OpeningBalancesScreen extends StatefulWidget {
  const OpeningBalancesScreen({super.key});

  @override
  State<OpeningBalancesScreen> createState() =>
      _OpeningBalancesScreenState();
}

class _OpeningBalancesScreenState extends State<OpeningBalancesScreen> {
  DateTime _date = DateTime(DateTime.now().year, 1, 1);

  // accountId → نص الإدخال (نحوله لرقم عند الحساب)
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _values = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFromProvider();
  }

  void _initFromProvider() {
    final provider = context.read<AppProvider>();
    final existing = provider.openingBalancesMap;
    for (final acc in provider.leafAccounts) {
      if (_controllers.containsKey(acc.id)) continue;
      final v = existing[acc.id] ?? 0;
      final ctrl = TextEditingController(
        text: v.abs() < 0.01 ? '' : v.toStringAsFixed(2),
      );
      ctrl.addListener(() {
        final v = double.tryParse(ctrl.text) ?? 0;
        _values[acc.id] = v;
        setState(() {});
      });
      _controllers[acc.id] = ctrl;
      _values[acc.id] = v;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = provider.leafAccounts;

    // حساب الإجماليات
    double totalDebit = 0;
    double totalCredit = 0;
    for (final acc in accounts) {
      final v = _values[acc.id] ?? 0;
      if (v.abs() < 0.01) continue;
      final isDebitNature = acc.type == AccountType.asset ||
          acc.type == AccountType.expense;
      if (isDebitNature) {
        if (v > 0) {
          totalDebit += v;
        } else {
          totalCredit += -v;
        }
      } else {
        if (v > 0) {
          totalCredit += v;
        } else {
          totalDebit += -v;
        }
      }
    }
    final diff = (totalDebit - totalCredit).abs();
    final balanced = diff < 0.01 && totalDebit > 0;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, totalDebit, totalCredit, balanced),
          Expanded(
            child: accounts.isEmpty
                ? _buildEmpty(context)
                : _buildList(provider, accounts),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, provider, balanced),
    );
  }

  // ── Header (تاريخ + إجماليات) ───────────────────────────
  Widget _buildHeader(
    BuildContext context,
    double totalDebit,
    double totalCredit,
    bool balanced,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = balanced ? Colors.green : Colors.orange;
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
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'تاريخ الأرصدة الافتتاحية',
                isDense: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event, size: 18),
              ),
              child: Text(_formatDate(_date)),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  balanced ? Icons.check_circle : Icons.info_outline,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    balanced
                        ? 'الأرصدة متوازنة ✓'
                        : 'الفرق: ${diff2(totalDebit, totalCredit)} — يجب أن يتوازن',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _totalBox('إجمالي المدين', totalDebit, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _totalBox('إجمالي الدائن', totalCredit, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalBox(String label, double v, Color color) {
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
          Text(
            v.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String diff2(double d, double c) => (d - c).abs().toStringAsFixed(2);

  // ── List ────────────────────────────────────────────────
  Widget _buildList(AppProvider provider, List<Account> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
      itemCount: accounts.length,
      itemBuilder: (_, i) => _buildRow(provider, accounts[i]),
    );
  }

  Widget _buildRow(AppProvider provider, Account acc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDebitNature = acc.type == AccountType.asset ||
        acc.type == AccountType.expense;
    final ctrl = _controllers[acc.id];
    if (ctrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      acc.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        acc.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${acc.type.labelAr} • '
                  '${isDebitNature ? "طبيعته مدين" : "طبيعته دائن"}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                suffixText: isDebitNature ? 'مدين' : 'دائن',
                suffixStyle: TextStyle(
                  fontSize: 10,
                  color: isDebitNature ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar (حفظ) ────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    AppProvider provider,
    bool balanced,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearAll,
                child: const Text('مسح الكل'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: balanced ? () => _save(provider) : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ الأرصدة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────
  void _clearAll() {
    for (final c in _controllers.values) {
      c.text = '';
    }
    setState(() {});
  }

  Future<void> _save(AppProvider provider) async {
    try {
      // نبني map من القيم المُدخلة
      final map = <String, double>{};
      for (final entry in _values.entries) {
        if (entry.value.abs() >= 0.01) map[entry.key] = entry.value;
      }
      if (map.isEmpty) {
        _snack('لم تُدخل أي أرصدة');
        return;
      }
      await provider.saveOpeningBalances(date: _date, balances: map);
      if (!mounted) return;
      _snack('تم حفظ الأرصدة الافتتاحية');
    } catch (e) {
      if (!mounted) return;
      _snack('$e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }

  // ── Empty ───────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حسابات ورقية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف حسابات في دليل الحسابات أولاً',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

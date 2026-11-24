import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_theme.dart';

class JournalEntryNewScreen extends StatefulWidget {
  const JournalEntryNewScreen({super.key});

  @override
  State<JournalEntryNewScreen> createState() => _JournalEntryNewScreenState();
}

class _JournalEntryNewScreenState extends State<JournalEntryNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  final List<_EntryLineDraft> _lines = [];

  @override
  void initState() {
    super.initState();
    _referenceCtrl.text = _generateReference();
    // سطرين ابتدائيين (مدين + دائن) لتسهيل الإدخال
    _lines.add(_EntryLineDraft());
    _lines.add(_EntryLineDraft());
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  String _generateReference() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return 'JV-$y$m$d-$hh$mm';
  }

  double get _totalDebit =>
      _lines.fold(0.0, (s, l) => s + (l.debit));

  double get _totalCredit =>
      _lines.fold(0.0, (s, l) => s + (l.credit));

  double get _difference => (_totalDebit - _totalCredit).abs();

  bool get _isBalanced =>
      _totalDebit > 0 && _difference < 0.01;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قيد جديد'),
        actions: [
          TextButton.icon(
            onPressed: _isBalanced ? () => _save(provider) : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            _buildHeaderCard(isDark),
            const SizedBox(height: 12),
            _buildLinesSection(provider, isDark),
            const SizedBox(height: 12),
            _buildTotalsCard(isDark),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(context, provider, isDark),
    );
  }

  // ── Header Card: التاريخ + المرجع + الوصف ────────────────
  Widget _buildHeaderCard(bool isDark) {
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
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(_formatDate(_date)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _referenceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المرجع',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'الوصف العام للقيد',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Lines Section ────────────────────────────────────────
  Widget _buildLinesSection(AppProvider provider, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'البنود',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_EntryLineDraft())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة سطر'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // رأس الأعمدة (للعرض فقط)
            _buildLinesHeader(isDark),
            const Divider(height: 1),
            for (int i = 0; i < _lines.length; i++)
              _buildLineRow(provider, i, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesHeader(bool isDark) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : Colors.black54,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('الحساب', style: style)),
          Expanded(
              flex: 2,
              child: Text('مدين', style: style, textAlign: TextAlign.end)),
          Expanded(
              flex: 2,
              child: Text('دائن', style: style, textAlign: TextAlign.end)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildLineRow(AppProvider provider, int index, bool isDark) {
    final line = _lines[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الحساب
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _pickAccount(index, provider),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'اختر حساباً',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  errorText: line.account == null ? null : null,
                ),
                child: Text(
                  line.account == null
                      ? '— اختر —'
                      : '${line.account!.code} — ${line.account!.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: line.account == null ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // مدين
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.debit == 0 ? '' : line.debit.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                setState(() {
                  line.debit = val;
                  // لا يمكن إدخال مدين ودائن معاً
                  if (val > 0) line.credit = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          // دائن
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.credit == 0 ? '' : line.credit.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                setState(() {
                  line.credit = val;
                  if (val > 0) line.debit = 0;
                });
              },
            ),
          ),
          // حذف السطر
          SizedBox(
            width: 32,
            child: IconButton(
              tooltip: 'حذف السطر',
              icon: Icon(
                Icons.close,
                size: 18,
                color: _lines.length <= 2 ? Colors.grey : Colors.red,
              ),
              onPressed: _lines.length <= 2
                  ? null
                  : () => setState(() {
                        _lines.removeAt(index);
                      }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Totals Card ──────────────────────────────────────────
  Widget _buildTotalsCard(bool isDark) {
    final balanced = _isBalanced;
    final color = balanced ? Colors.green : Colors.orange;
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
                  child: _totalTile('إجمالي المدين', _totalDebit, Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _totalTile('إجمالي الدائن', _totalCredit, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balanced
                          ? 'القيد متوازن ✓'
                          : 'الفرق: ${_difference.toStringAsFixed(2)} '
                              '(يجب أن يكون المدين = الدائن)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalTile(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar: حفظ ───────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    AppProvider provider,
    bool isDark,
  ) {
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
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
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
                onPressed: _isBalanced ? () => _save(provider) : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ القيد'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAccount(int index, AppProvider provider) async {
    // الحسابات القابلة للترحيل فقط (الورقية)
    final accounts = provider.leafAccounts
        .where((a) => a.isActive)
        .toList();
    if (accounts.isEmpty) {
      _snack('لا توجد حسابات ورقية. أضف حسابات في دليل الحسابات أولاً.');
      return;
    }
    final picked = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AccountPickerSheet(accounts: accounts),
    );
    if (picked != null) {
      setState(() => _lines[index].account = picked);
    }
  }

  Future<void> _save(AppProvider provider) async {
    // تحقق نهائي
    if (_referenceCtrl.text.trim().isEmpty) {
      _snack('الرجاء إدخال رقم المرجع');
      return;
    }
    final invalidLines = _lines.where(
      (l) =>
          l.account == null ||
          (l.debit <= 0 && l.credit <= 0) ||
          (l.debit > 0 && l.credit > 0),
    );
    if (invalidLines.isNotEmpty) {
      _snack('تحقق من صحة جميع البنود (حساب + مبلغ في جهة واحدة)');
      return;
    }
    if (!_isBalanced) {
      _snack('القيد غير متوازن');
      return;
    }

    final lines = _lines
        .map(
          (l) => JournalLine(
            accountId: l.account!.id,
            debit: l.debit,
            credit: l.credit,
            description: l.description.isEmpty ? null : l.description,
          ),
        )
        .toList();

    final entry = JournalEntry(
      id: provider.newJournalEntryId(),
      reference: _referenceCtrl.text.trim(),
      date: _date,
      description: _descriptionCtrl.text.trim(),
      lines: lines,
    );

    try {
      await provider.addJournalEntry(entry);
      if (!mounted) return;
      _snack('تم حفظ القيد بنجاح');
      Navigator.pop(context);
    } catch (e) {
      _snack('$e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

// ============================================================
// Draft line
// ============================================================
class _EntryLineDraft {
  Account? account;
  double debit = 0;
  double credit = 0;
  String description = '';

  void dispose() {}
}

// ============================================================
// Account Picker Sheet
// ============================================================
class _AccountPickerSheet extends StatefulWidget {
  final List<Account> accounts;
  const _AccountPickerSheet({required this.accounts});

  @override
  State<_AccountPickerSheet> createState() => _AccountPickerSheetState();
}

class _AccountPickerSheetState extends State<_AccountPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.accounts.where((a) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الرمز...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text('${a.code} — ${a.name}'),
                        subtitle: Text(a.type.labelAr),
                        onTap: () => Navigator.pop(context, a),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

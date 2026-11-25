import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../models/journal_entry.dart';
import '../../models/recurring_journal.dart';
import '../../theme/app_theme.dart';

class RecurringJournalFormScreen extends StatefulWidget {
  final RecurringJournal? existing;

  const RecurringJournalFormScreen({super.key, this.existing});

  @override
  State<RecurringJournalFormScreen> createState() =>
      _RecurringJournalFormScreenState();
}

class _RecurringJournalFormScreenState
    extends State<RecurringJournalFormScreen> {
  final _referenceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  late DateTime _startDate;
  DateTime? _endDate;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  bool _isActive = true;

  final List<_LineDraft> _lines = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _referenceCtrl.text = e?.reference ?? '';
    _descriptionCtrl.text = e?.description ?? '';
    _startDate = e?.startDate ?? DateTime.now();
    _endDate = e?.endDate;
    _frequency = e?.frequency ?? RecurrenceFrequency.monthly;
    _isActive = e?.isActive ?? true;

    if (e != null) {
      for (final line in e.lines) {
        final draft = _LineDraft()
          ..accountId = line.accountId
          ..debit = line.debit
          ..credit = line.credit
          ..description = line.description ?? '';
        _lines.add(draft);
      }
    }
    if (_lines.isEmpty) {
      _lines.add(_LineDraft());
      _lines.add(_LineDraft());
    }
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0.0, (s, l) => s + l.debit);
  double get _totalCredit => _lines.fold(0.0, (s, l) => s + l.credit);
  double get _diff => (_totalDebit - _totalCredit).abs();
  bool get _balanced => _totalDebit > 0 && _diff < 0.01;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل قالب متكرر' : 'قالب قيد متكرر جديد'),
        actions: [
          TextButton.icon(
            onPressed: _balanced ? () => _save(provider) : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Card(
            elevation: 0,
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _referenceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المرجع',
                      hintText: 'مثال: RJ-RENT-01',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      hintText: 'إيجار شهري',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isFrom: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ البداية',
                              isDense: true,
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event, size: 18),
                            ),
                            child: Text(_formatDate(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isFrom: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ النهاية (اختياري)',
                              isDense: true,
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event, size: 18),
                            ),
                            child: Text(
                              _endDate == null
                                  ? '— بدون نهاية —'
                                  : _formatDate(_endDate!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_endDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _endDate = null),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('مسح تاريخ النهاية'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    value: _frequency,
                    decoration: const InputDecoration(
                      labelText: 'التكرار',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: RecurrenceFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.labelAr),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _frequency = v);
                    },
                  ),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('نشط'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLinesSection(provider, isDark),
          const SizedBox(height: 12),
          _buildTotals(isDark),
        ],
      ),
    );
  }

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
                    'بنود القالب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _lines.add(_LineDraft())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة سطر'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < _lines.length; i++)
              _buildLineRow(provider, i, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLineRow(AppProvider provider, int index, bool isDark) {
    final line = _lines[index];
    final account = provider.accountById(line.accountId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _pickAccount(index, provider),
              child: InputDecorator(
                decoration: const InputDecoration(
                  hintText: 'اختر حساباً',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                child: Text(
                  account == null
                      ? '— اختر —'
                      : '${account.code} — ${account.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: account == null ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.debit == 0 ? '' : line.debit.toString(),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                  if (val > 0) line.credit = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.credit == 0 ? '' : line.credit.toString(),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                  : () => setState(() => _lines.removeAt(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(bool isDark) {
    final color = _balanced ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            _balanced ? Icons.check_circle : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _balanced
                  ? 'القالب متوازن ✓'
                  : 'الفرق: ${_diff.toStringAsFixed(2)} '
                      '(مدين=${_totalDebit.toStringAsFixed(2)} '
                      'دائن=${_totalCredit.toStringAsFixed(2)})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final init = isFrom ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickAccount(int index, AppProvider provider) async {
    final accounts =
        provider.leafAccounts.where((a) => a.isActive).toList();
    if (accounts.isEmpty) {
      _snack('لا توجد حسابات ورقية');
      return;
    }
    final picked = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AccountPickerSheet(accounts: accounts),
    );
    if (picked != null) {
      setState(() => _lines[index].accountId = picked.id);
    }
  }

  Future<void> _save(AppProvider provider) async {
    if (_referenceCtrl.text.trim().isEmpty) {
      _snack('الرجاء إدخال المرجع');
      return;
    }
    final invalid = _lines.where(
      (l) =>
          l.accountId.isEmpty ||
          (l.debit <= 0 && l.credit <= 0) ||
          (l.debit > 0 && l.credit > 0),
    );
    if (invalid.isNotEmpty) {
      _snack('تحقق من صحة البنود');
      return;
    }
    if (!_balanced) {
      _snack('القالب غير متوازن');
      return;
    }

    final lines = _lines
        .map((l) => JournalLine(
              accountId: l.accountId,
              debit: l.debit,
              credit: l.credit,
              description: l.description.isEmpty ? null : l.description,
            ))
        .toList();

    final existing = widget.existing;
    try {
      if (existing != null) {
        final updated = existing.copyWith(
          reference: _referenceCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          lines: lines,
          frequency: _frequency,
          startDate: _startDate,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          isActive: _isActive,
        );
        await provider.updateRecurringJournal(updated);
      } else {
        final created = RecurringJournal(
          id: provider.newJournalEntryId(),
          reference: _referenceCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          lines: lines,
          frequency: _frequency,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
        await provider.addRecurringJournal(created);
      }
      if (!mounted) return;
      _snack('تم الحفظ');
      Navigator.pop(context);
    } catch (e) {
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

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

class _LineDraft {
  String accountId = '';
  double debit = 0;
  double credit = 0;
  String description = '';
}

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
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث...',
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
                    controller: ctrl,
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

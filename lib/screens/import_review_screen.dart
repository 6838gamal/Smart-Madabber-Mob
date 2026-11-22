// lib/screens/import_review_screen.dart
import 'package:flutter/material.dart';
import '../models/entry_line_model.dart';
import '../models/import_result_model.dart';
import '../theme/app_theme.dart';

class ImportReviewScreen extends StatefulWidget {
  final ImportResultModel result;
  const ImportReviewScreen({super.key, required this.result});

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late List<_EditLine> _lines;
  late TextEditingController _refCtrl;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _lines = widget.result.lines.map(_EditLine.fromModel).toList();
    if (_lines.isEmpty) _lines.add(_EditLine.empty());
    _refCtrl = TextEditingController(text: widget.result.reference ?? '');
    _date = widget.result.date;
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _refCtrl.dispose();
    super.dispose();
  }

  // ✅ استخدمنا debitVal / creditVal (double) وليس debit / credit (controller)
  double get _debit => _lines.fold(0.0, (s, l) => s + l.debitVal);
  double get _credit => _lines.fold(0.0, (s, l) => s + l.creditVal);
  bool get _balanced => (_debit - _credit).abs() < 0.001 && _debit > 0;

  void _accept() {
    final cleaned = _lines
        .map((l) => l.toModel())
        .where((l) =>
            l.account?.isNotEmpty == true || l.debit > 0 || l.credit > 0)
        .toList();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أسطر صالحة')),
      );
      return;
    }
    Navigator.of(context).pop(
      ImportResultModel(
        source: widget.result.source,
        lines: cleaned,
        reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        date: _date,
        rawText: widget.result.rawText,
        warnings: widget.result.warnings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final srcLabel = switch (widget.result.source) {
      ImportSource.image => 'صورة (OCR)',
      ImportSource.csv => 'ملف CSV',
      ImportSource.xlsx => 'ملف Excel',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('مراجعة الاستيراد — $srcLabel'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _accept,
            icon: const Icon(Icons.check),
            label: const Text('قبول'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.result.warnings.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.result.warnings
                    .map((w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(w,
                                      style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (widget.result.rawText != null)
            ExpansionTile(
              title: const Text('النص المستخرج من الصورة'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color:
                      isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                  child: Text(
                    widget.result.rawText!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _refCtrl,
            decoration: const InputDecoration(
              labelText: 'رقم المرجع',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('تعديل الأسطر (${_lines.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _lines.add(_EditLine.empty())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('سطر'),
              ),
            ],
          ),
          ..._lines.asMap().entries.map((e) => _lineCard(e.key, e.value, isDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_balanced ? Colors.green : Colors.orange)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_balanced ? Colors.green : Colors.orange)
                    .withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي المدين'),
                    Text(_debit.toStringAsFixed(2),
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الدائن'),
                    Text(_credit.toStringAsFixed(2),
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_balanced ? 'متوازن ✓' : 'غير متوازن',
                        style: TextStyle(
                            color: _balanced ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold)),
                    Text((_debit - _credit).abs().toStringAsFixed(2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close),
                  label: const Text('إلغاء'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _accept,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('قبول واستخدام'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineCard(int i, _EditLine l, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.primary)),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _lines[i].dispose();
                    _lines.removeAt(i);
                  });
                },
              ),
            ],
          ),
          TextField(
            controller: l.account,
            decoration: const InputDecoration(
              labelText: 'الحساب',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: l.description,
            decoration: const InputDecoration(
              labelText: 'البيان',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: l.debit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'مدين',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: l.credit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'دائن',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ✅ نسخة نظيفة من _EditLine: فقط الـ getters المطلوبة فعلاً
class _EditLine {
  final TextEditingController account;
  final TextEditingController description;
  final TextEditingController debit;
  final TextEditingController credit;

  _EditLine(this.account, this.description, this.debit, this.credit);

  factory _EditLine.empty() => _EditLine(
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      );

  factory _EditLine.fromModel(EntryLineModel m) => _EditLine(
        TextEditingController(text: m.account ?? ''),
        TextEditingController(text: m.description ?? ''),
        TextEditingController(
            text: m.debit > 0 ? m.debit.toStringAsFixed(2) : ''),
        TextEditingController(
            text: m.credit > 0 ? m.credit.toStringAsFixed(2) : ''),
      );

  // ── القيم الرقمية الفعلية (المستخدمة في الحسابات) ──
  double get debitVal => double.tryParse(debit.text) ?? 0;
  double get creditVal => double.tryParse(credit.text) ?? 0;

  EntryLineModel toModel() => EntryLineModel(
        account: account.text.trim().isEmpty ? null : account.text.trim(),
        description:
            description.text.trim().isEmpty ? null : description.text.trim(),
        debit: debitVal,
        credit: creditVal,
      );

  void dispose() {
    account.dispose();
    description.dispose();
    debit.dispose();
    credit.dispose();
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/import_result_model.dart';
import '../services/entry_import_service.dart';
import '../theme/app_theme.dart';
import 'import_review_screen.dart';

class _EntryLine {
  final TextEditingController accountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController debitController = TextEditingController();
  final TextEditingController creditController = TextEditingController();

  double get debit => double.tryParse(debitController.text) ?? 0;
  double get credit => double.tryParse(creditController.text) ?? 0;
  bool get isEmpty =>
      accountController.text.trim().isEmpty &&
      debitController.text.trim().isEmpty &&
      creditController.text.trim().isEmpty;
  void dispose() {
    accountController.dispose();
    descriptionController.dispose();
    debitController.dispose();
    creditController.dispose();
  }
}

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});
  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _importService = EntryImportService();
  DateTime _selectedDate = DateTime.now();
  final List<_EntryLine> _lines = [_EntryLine(), _EntryLine()];

  final List<Map<String, dynamic>> _accounts = const [
    {'code': '1000', 'name': 'الصندوق'},
    {'code': '1010', 'name': 'البنك'},
    {'code': '1100', 'name': 'العملاء (المدينون)'},
    {'code': '2000', 'name': 'الموردون (الدائنون)'},
    {'code': '2100', 'name': 'ضريبة القيمة المضافة'},
    {'code': '3000', 'name': 'رأس المال'},
    {'code': '4000', 'name': 'إيرادات المبيعات'},
    {'code': '5000', 'name': 'تكلفة المبيعات'},
    {'code': '5100', 'name': 'مصروفات إدارية'},
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0.0, (s, l) => s + l.debit);
  double get _totalCredit => _lines.fold(0.0, (s, l) => s + l.credit);
  double get _difference => (_totalDebit - _totalCredit).abs();
  bool get _isBalanced =>
      _lines.any((l) => !l.isEmpty) && _difference < 0.001;

  void _addLine() => setState(() => _lines.add(_EntryLine()));

  void _removeLine(int i) {
    if (_lines.length <= 2) {
      _showError('يجب أن يحتوي القيد على سطرين على الأقل');
      return;
    }
    setState(() {
      _lines[i].dispose();
      _lines.removeAt(i);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _saveEntry() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final validLines = _lines
        .where((l) => !l.isEmpty && l.accountController.text.isNotEmpty)
        .toList();
    if (validLines.length < 2) {
      _showError('يجب إدخال سطرين على الأقل مع تحديد الحساب');
      return;
    }
    for (final line in validLines) {
      if (line.debit > 0 && line.credit > 0) {
        _showError('لا يمكن إدخال مبلغ في المدين والدائن معاً');
        return;
      }
      if (line.debit == 0 && line.credit == 0) {
        _showError('كل سطر يجب أن يحتوي على مدين أو دائن');
        return;
      }
    }
    if (!_isBalanced) {
      _showError('القيد غير متوازن — الفرق: ${_difference.toStringAsFixed(2)}');
      return;
    }
    // TODO: حفظ في قاعدة البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم حفظ القيد بنجاح'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    await _runImport(() => _importService.analyzeImage(File(file.path)));
  }

  Future<void> _pickCsvOrXlsx() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    await _runImport(() => _importService.importFile(res.files.single));
  }

  Future<void> _runImport(
      Future<ImportResultModel> Function() task) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await task();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (result.lines.isEmpty) {
        _showError('لم يتم استخراج أي أسطر — جرّب ملفاً آخر');
        return;
      }
      final approved = await Navigator.of(context).push<ImportResultModel>(
        MaterialPageRoute(
            builder: (_) => ImportReviewScreen(result: result)),
      );
      if (approved == null) {
        _showError('تم إلغاء الاستيراد');
        return;
      }
      _applyImportedResult(approved);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('فشل التحليل: $e');
    }
  }

  void _applyImportedResult(ImportResultModel approved) {
    setState(() {
      for (final l in _lines) {
        l.dispose();
      }
      _lines.clear();
      for (final m in approved.lines) {
        final l = _EntryLine();
        l.accountController.text = m.account ?? '';
        l.descriptionController.text = m.description ?? '';
        l.debitController.text =
            m.debit > 0 ? m.debit.toStringAsFixed(2) : '';
        l.creditController.text =
            m.credit > 0 ? m.credit.toStringAsFixed(2) : '';
        _lines.add(l);
      }
      if (approved.reference != null) {
        _referenceController.text = approved.reference!;
      }
      if (approved.date != null) {
        _selectedDate = approved.date!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'تم استيراد ${approved.lines.length} سطر — راجع ثم احفظ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة قيد'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.upload_file),
            tooltip: 'استيراد',
            onSelected: (v) {
              if (v == 'image') _pickAndAnalyzeImage();
              if (v == 'file') _pickCsvOrXlsx();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'image',
                child: ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text('تحليل صورة (OCR)'),
                ),
              ),
              PopupMenuItem(
                value: 'file',
                child: ListTile(
                  leading: Icon(Icons.table_chart_outlined),
                  title: Text('استيراد CSV / Excel'),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _saveEntry,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'حفظ',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'رقم المرجع (اختياري)',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Text('أسطر القيد',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('سطر'),
              ),
            ]),
            ..._lines.asMap().entries.map((e) {
              final i = e.key;
              final line = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.15),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _removeLine(i),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                      ),
                    ]),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الحساب',
                        prefixIcon:
                            Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: _accounts
                          .map((a) => DropdownMenuItem<String>(
                                value: '${a['code']} - ${a['name']}',
                                child: Text('${a['code']} - ${a['name']}',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) line.accountController.text = v;
                      },
                      validator: (v) {
                        if (line.isEmpty) return null;
                        return (v == null || v.isEmpty)
                            ? 'اختر الحساب'
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: line.descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'البيان (اختياري)',
                        prefixIcon: Icon(Icons.short_text),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: line.debitController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'مدين',
                            prefixIcon: Icon(Icons.attach_money,
                                color: Colors.green, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: line.creditController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'دائن',
                            prefixIcon: Icon(Icons.attach_money,
                                color: Colors.red, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ]),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isBalanced ? Colors.green : Colors.orange)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: (_isBalanced ? Colors.green : Colors.orange)
                        .withOpacity(0.4)),
              ),
              child: Column(children: [
                Row(children: [
                  Icon(
                      _isBalanced
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: _isBalanced ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Text(_isBalanced ? 'القيد متوازن ✓' : 'القيد غير متوازن',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isBalanced ? Colors.green : Colors.orange)),
                ]),
                const Divider(height: 20),
                _sumRow('إجمالي المدين', _totalDebit, Colors.green),
                _sumRow('إجمالي الدائن', _totalCredit, Colors.red),
                _sumRow('الفرق', _difference,
                    _isBalanced ? Colors.green : Colors.orange),
              ]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('حفظ القيد'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sumRow(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(2),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
          ],
        ),
      );
}

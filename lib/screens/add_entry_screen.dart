// lib/screens/add_entry_screen.dart  (مقتطف أساسي)
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// داخل State:
final _importService = EntryImportService();

Future<void> _pickAndAnalyzeImage() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
  if (file == null) return;
  await _runImport(() => _importService.analyzeImage(File(file.path)));
}

Future<void> _pickCsvOrXlsx() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'xlsx', 'xls'],
  );
  if (res == null || res.files.isEmpty) return;
  await _runImport(() => _importService.importFile(res.files.single));
}

Future<void> _runImport(Future<ImportResultModel> Function() task) async {
  // مؤشر تحميل
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final result = await task();
    if (!mounted) return;
    Navigator.of(context).pop(); // إغلاق اللودر

    if (result.lines.isEmpty) {
      _showError('لم يتم استخراج أي أسطر — جرّب ملفاً آخر');
      return;
    }

    // فتح شاشة المراجعة
    final approved = await Navigator.of(context).push<ImportResultModel>(
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(result: result),
      ),
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
    // إفراغ الأسطر الحالية
    for (final l in _lines) {
      l.dispose();
    }
    _lines.clear();

    for (final m in approved.lines) {
      final l = _EntryLine();
      l.accountController.text = m.account ?? '';
      l.descriptionController.text = m.description ?? '';
      l.debitController.text = m.debit > 0 ? m.debit.toStringAsFixed(2) : '';
      l.creditController.text = m.credit > 0 ? m.credit.toStringAsFixed(2) : '';
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
      content: Text('تم استيراد ${approved.lines.length} سطر — راجع ثم احفظ'),
      backgroundColor: Colors.green,
    ),
  );
}

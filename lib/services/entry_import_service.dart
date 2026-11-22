// lib/services/entry_import_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/entry_line_model.dart';
import '../models/import_result_model.dart';

class EntryImportService {
  // ─────────────────────────────────────────────
  //  1) تحليل صورة (OCR)
  //  نقطة الربط: استبدل هذا بـ Google ML Kit أو API
  // ─────────────────────────────────────────────
  Future<ImportResultModel> analyzeImage(File image) async {
    // TODO: استبدل بـ OCR حقيقي:
    // final recognizer = TextRecognizer();
    // final result = await recognizer.processImage(InputImage.fromFile(image));
    // final text = result.text;
    //
    // ثم استخدم EntryParser.parseFromText(text)

    // ── Mock للتوضيح ──
    await Future.delayed(const Duration(seconds: 2));
    final mockText = '''
فاتورة رقم: INV-2024-001
التاريخ: 2024-06-15
الصندوق           5000
إيرادات المبيعات        5000
''';
    return _parseOcrText(mockText, image.path);
  }

  ImportResultModel _parseOcrText(String text, String imagePath) {
    final lines = <EntryLineModel>[];
    final warnings = <String>[];
    String? reference;
    DateTime? date;

    final refMatch = RegExp(r'فاتورة\s*رقم\s*[:：]?\s*(\S+)').firstMatch(text);
    if (refMatch != null) reference = refMatch.group(1);

    final dateMatch =
        RegExp(r'التاريخ\s*[:：]?\s*(\d{4}-\d{1,2}-\d{1,2})').firstMatch(text);
    if (dateMatch != null) date = DateTime.tryParse(dateMatch.group(1)!);

    // نمط بسيط: اسم الحساب ثم مبلغ
    final lineReg = RegExp(r'^(.+?)\s+(\d+(?:\.\d{1,2})?)$', multiLine: true);
    for (final m in lineReg.allMatches(text)) {
      final name = m.group(1)!.trim();
      final amount = double.tryParse(m.group(2)!) ?? 0;
      if (name.isEmpty || amount == 0) continue;
      // نفترض أولاً مدين؛ المراجع يعدّل
      lines.add(EntryLineModel(
        account: name,
        debit: amount,
        description: 'من صورة',
      ));
    }

    if (lines.isEmpty) warnings.add('لم يتم التعرف على أسطر واضحة');

    // محاولة موازنة تلقائية: لو سطرين وأحدهما مدين فقط
    if (lines.length == 2 &&
        lines[0].debit > 0 &&
        lines[1].debit > 0) {
      lines[1] = lines[1].copyWith(debit: 0, credit: lines[0].debit);
      warnings.add('تم افتراض أن السطر الثاني دائن لموازنة القيد');
    }

    return ImportResultModel(
      source: ImportSource.image,
      lines: lines,
      reference: reference,
      date: date,
      rawText: text,
      warnings: warnings,
    );
  }

  // ─────────────────────────────────────────────
  //  2) تحليل CSV / XLSX
  //  المتوقع: أعمدة (account, description, debit, credit)
  // ─────────────────────────────────────────────
  Future<ImportResultModel> importFile(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    if (ext == 'csv') return _parseCsv(file);
    if (ext == 'xlsx' || ext == 'xls') return _parseXlsx(file);
    throw UnsupportedError('صيغة غير مدعومة: $ext');
  }

  Future<ImportResultModel> _parseCsv(PlatformFile file) async {
    final content = await File(file.path!).readAsString();
    final rows = const CsvToListConverter(
      shouldParseNumbers: true,
      eol: '\n',
    ).convert(content);

    if (rows.isEmpty) {
      return const ImportResultModel(
        source: ImportSource.csv,
        lines: [],
        warnings: ['الملف فارغ'],
      );
    }

    final headers =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final idxAccount = _findCol(headers, ['account', 'الحساب', 'حساب']);
    final idxDesc =
        _findCol(headers, ['description', 'البيان', 'وصف', 'الشرح']);
    final idxDebit = _findCol(headers, ['debit', 'مدين', 'debit_amount']);
    final idxCredit = _findCol(headers, ['credit', 'دائن', 'credit_amount']);

    final warnings = <String>[];
    if (idxAccount == -1) {
      warnings.add('لم يتم العثور على عمود الحساب (account/الحساب)');
    }

    final lines = <EntryLineModel>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.isEmpty) continue;
      final account =
          idxAccount >= 0 && idxAccount < r.length ? r[idxAccount].toString() : null;
      final desc = idxDesc >= 0 && idxDesc < r.length
          ? r[idxDesc]?.toString()
          : null;
      final debit = idxDebit >= 0 && idxDebit < r.length
          ? _toDouble(r[idxDebit])
          : 0.0;
      final credit = idxCredit >= 0 && idxCredit < r.length
          ? _toDouble(r[idxCredit])
          : 0.0;
      if ((account == null || account.trim().isEmpty) &&
          debit == 0 &&
          credit == 0) {
        continue;
      }
      lines.add(EntryLineModel(
        account: account?.trim(),
        description: desc?.trim(),
        debit: debit,
        credit: credit,
      ));
    }

    return ImportResultModel(
      source: ImportSource.csv,
      lines: lines,
      warnings: warnings,
    );
  }

  Future<ImportResultModel> _parseXlsx(PlatformFile file) async {
    final bytes = await File(file.path!).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const ImportResultModel(
        source: ImportSource.xlsx,
        lines: [],
        warnings: ['الملف لا يحتوي أوراق'],
      );
    }
    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.rows.isEmpty) {
      return const ImportResultModel(
        source: ImportSource.xlsx,
        lines: [],
        warnings: ['الورقة فارغة'],
      );
    }
    final headers = sheet.rows.first
        .map((c) => (c?.value?.toString() ?? '').trim().toLowerCase())
        .toList();
    final idxAccount = _findCol(headers, ['account', 'الحساب', 'حساب']);
    final idxDesc =
        _findCol(headers, ['description', 'البيان', 'وصف', 'الشرح']);
    final idxDebit = _findCol(headers, ['debit', 'مدين']);
    final idxCredit = _findCol(headers, ['credit', 'دائن']);

    final warnings = <String>[];
    if (idxAccount == -1) warnings.add('لم يتم العثور على عمود الحساب');

    final lines = <EntryLineModel>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final r = sheet.rows[i];
      if (r.isEmpty) continue;
      String? cell(int idx) =>
          idx >= 0 && idx < r.length ? r[idx]?.value?.toString().trim() : null;
      final account = cell(idxAccount);
      final desc = cell(idxDesc);
      final debit = _toDouble(cell(idxDebit));
      final credit = _toDouble(cell(idxCredit));
      if ((account == null || account.isEmpty) && debit == 0 && credit == 0) {
        continue;
      }
      lines.add(EntryLineModel(
        account: account,
        description: desc,
        debit: debit,
        credit: credit,
      ));
    }

    return ImportResultModel(
      source: ImportSource.xlsx,
      lines: lines,
      warnings: warnings,
    );
  }

  int _findCol(List<String> headers, List<String> aliases) {
    for (final a in aliases) {
      final i = headers.indexOf(a);
      if (i != -1) return i;
    }
    return -1;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(
          v.toString().replaceAll(',', '').replaceAll(' ', ''),
        ) ??
        0;
  }
}

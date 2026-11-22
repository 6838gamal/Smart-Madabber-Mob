// lib/services/ai_assistant_service.dart
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/chat_message.dart';

class AiAssistantService {
  /// يرسل رسالة ويُرجع ردّاً نصياً.
  /// 🔗 نقطة الربط: استبدل هذا بـ HTTP call إلى خادمك.
  Future<String> sendMessage({
    required String text,
    ChatAttachment? attachment,
    List<ChatMessage> history = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    // لو مرفق، نحلله ونُرجع ملخصاً
    if (attachment != null) {
      return _analyzeAttachment(attachment, text);
    }

    // رد تجريبي ذكي بسيط
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return 'كيف أساعدك في المحاسبة اليوم؟';
    if (t.contains('رصيد') || t.contains('balance')) {
      return 'يمكنني مساعدتك في معرفة الأرصدة. '
          'أدخل اسم الحساب أو ارفع كشفاً بصيغة CSV/XLSX وسأحلله لك.';
    }
    if (t.contains('قيد') || t.contains('entry')) {
      return 'لإضافة قيد محاسبي متوازن، انتقل إلى شاشة "إضافة قيد" '
          'أو أرسل لي تفاصيل العملية وسأقترح القيد المناسب.';
    }
    if (t.contains('فاتورة') || t.contains('invoice')) {
      return 'أستطيع تحليل الفواتير من الصور. ارفع صورة الفاتورة '
          'وسأستخرج المبالغ والحسابات المقترحة.';
    }
    return 'فهمت طلبك: "$text".\n'
        'يمكنك رفع ملف (CSV / XLSX / PDF / Word) أو صورة أو رسالة صوتية '
        'وسأساعدك في التحليل والترحيل المحاسبي.';
  }

  Future<String> _analyzeAttachment(
      ChatAttachment att, String userText) async {
    switch (att.type) {
      case AttachmentType.csv:
        return _analyzeCsv(att.path);
      case AttachmentType.xlsx:
        return _analyzeXlsx(att.path);
      case AttachmentType.audio:
        return '🎧 استلمت تسجيلك الصوتي (${att.name}).\n'
            'سأحوّله إلى نص وأقترح القيود المناسبة (ميزة قيد التنفيذ في الخادم).';
      case AttachmentType.image:
        return '🖼️ استلمت الصورة (${att.name}).\n'
            'سأستخرج النصوص والمبالغ منها عبر OCR (ميزة قيد التنفيذ في الخادم).';
      case AttachmentType.pdf:
        return '📄 استلمت ملف PDF (${att.name}).\n'
            'سأستخرج الجداول والمبالغ منه (ميزة قيد التنفيذ في الخادم).';
      case AttachmentType.word:
        return '📝 استلمت ملف Word (${att.name}).\n'
            'سأستخرج المحتوى المحاسبي منه (ميزة قيد التنفيذ في الخادم).';
      default:
        return '📎 استلمت الملف (${att.name}). كيف تريدني أن أساعدك به؟';
    }
  }

  Future<String> _analyzeCsv(String? path) async {
    if (path == null) return 'لا يمكن قراءة مسار الملف.';
    try {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter(
        shouldParseNumbers: true,
        eol: '\n',
      ).convert(content);
      if (rows.isEmpty) return 'الملف فارغ.';
      final headers = rows.first.map((e) => e.toString()).join(' | ');
      final sample = rows.skip(1).take(3).map((r) => r.join(' | ')).join('\n');
      return '📊 حللت ملف CSV:\n'
          '• عدد الصفوف: ${rows.length - 1}\n'
          '• الأعمدة: $headers\n'
          '• عينة:\n$sample\n\n'
          'هل تريد أن أحوّلها إلى قيود محاسبية؟';
    } catch (e) {
      return 'تعذّر قراءة CSV: $e';
    }
  }

  Future<String> _analyzeXlsx(String? path) async {
    if (path == null) return 'لا يمكن قراءة مسار الملف.';
    try {
      final bytes = await File(path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return 'الملف لا يحتوي أوراق.';
      final sheet = excel.tables[excel.tables.keys.first]!;
      final rowCount = sheet.rows.length;
      final firstRow = sheet.rows.first
          .map((c) => c?.value?.toString() ?? '')
          .join(' | ');
      return '📊 حللت ملف Excel:\n'
          '• الورقة: ${excel.tables.keys.first}\n'
          '• عدد الصفوف: $rowCount\n'
          '• الصف الأول: $firstRow\n\n'
          'هل تريد تحويلها إلى قيود؟';
    } catch (e) {
      return 'تعذّر قراءة XLSX: $e';
    }
  }
}

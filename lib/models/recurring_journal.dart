import 'journal_entry.dart';

/// التكرار
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get labelAr {
    switch (this) {
      case RecurrenceFrequency.daily:     return 'يومي';
      case RecurrenceFrequency.weekly:    return 'أسبوعي';
      case RecurrenceFrequency.monthly:   return 'شهري';
      case RecurrenceFrequency.quarterly: return 'ربع سنوي';
      case RecurrenceFrequency.yearly:    return 'سنوي';
    }
  }

  /// الخطوة التالية بعد تاريخ معيّن
  DateTime nextDate(DateTime from) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}

class RecurringJournal {
  final String id;
  final String reference;        // مرجع القالب
  final String description;
  final List<JournalLine> lines; // بنود القالب
  final RecurrenceFrequency frequency;
  final DateTime startDate;      // أول تاريخ
  final DateTime? endDate;       // نهاية التكرار (null = لا نهائي)
  final DateTime? lastGenerated; // آخر قيد تم إنشاؤه
  final bool isActive;

  const RecurringJournal({
    required this.id,
    required this.reference,
    required this.description,
    required this.lines,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastGenerated,
    this.isActive = true,
  });

  double get totalDebit => lines.fold(0.0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold(0.0, (s, l) => s + l.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.001;

  /// موعد الاستحقاق التالي (null إذا انتهى التكرار أو لم يبدأ)
  DateTime? get nextDueDate {
    if (!isActive) return null;
    final from = lastGenerated ?? startDate.subtract(const Duration(days: 1));
    final next = frequency.nextDate(from);
    if (endDate != null && next.isAfter(endDate!)) return null;
    return next;
  }

  /// هل حان موعد إنشاء قيد جديد؟
  bool get isDue {
    final next = nextDueDate;
    if (next == null) return false;
    final now = DateTime.now();
    return !next.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  /// كل التواريخ المستحقة من `lastGenerated` إلى الآن
  List<DateTime> pendingDates({DateTime? now}) {
    final result = <DateTime>[];
    if (!isActive) return result;
    var cursor = lastGenerated ?? startDate.subtract(const Duration(days: 1));
    cursor = frequency.nextDate(cursor);
    final limit = now ?? DateTime.now();
    while (!cursor.isAfter(limit) &&
        (endDate == null || !cursor.isAfter(endDate!))) {
      result.add(cursor);
      cursor = frequency.nextDate(cursor);
      if (result.length > 500) break; // حماية
    }
    return result;
  }

  RecurringJournal copyWith({
    String? reference,
    String? description,
    List<JournalLine>? lines,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastGenerated,
    bool clearEndDate = false,
    bool clearLastGenerated = false,
    bool? isActive,
  }) {
    return RecurringJournal(
      id: id,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      lines: lines ?? this.lines,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGenerated:
          clearLastGenerated ? null : (lastGenerated ?? this.lastGenerated),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'description': description,
        'lines': lines.map((l) => l.toJson()).toList(),
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'lastGenerated': lastGenerated?.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringJournal.fromJson(Map<String, dynamic> j) => RecurringJournal(
        id: j['id'] as String,
        reference: j['reference'] as String,
        description: j['description'] as String,
        lines: (j['lines'] as List)
            .map((e) => JournalLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        frequency: RecurrenceFrequency.values.firstWhere(
          (f) => f.name == j['frequency'],
          orElse: () => RecurrenceFrequency.monthly,
        ),
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: j['endDate'] == null
            ? null
            : DateTime.parse(j['endDate'] as String),
        lastGenerated: j['lastGenerated'] == null
            ? null
            : DateTime.parse(j['lastGenerated'] as String),
        isActive: j['isActive'] as bool? ?? true,
      );
}

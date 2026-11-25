class JournalLine {
  final String accountId;
  final double debit;   // مدين
  final double credit;  // دائن
  final String? description;
  final String? costCenterId;  // مركز التكلفة (اختياري)

  const JournalLine({
    required this.accountId,
    this.debit = 0,
    this.credit = 0,
    this.description,
    this.costCenterId,
  });

  double get net => debit - credit;

  JournalLine copyWith({
    String? accountId,
    double? debit,
    double? credit,
    String? description,
    String? costCenterId,
    bool clearCostCenter = false,
  }) {
    return JournalLine(
      accountId: accountId ?? this.accountId,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      description: description ?? this.description,
      costCenterId:
          clearCostCenter ? null : (costCenterId ?? this.costCenterId),
    );
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'debit': debit,
        'credit': credit,
        'description': description,
        'costCenterId': costCenterId,
      };

  factory JournalLine.fromJson(Map<String, dynamic> j) => JournalLine(
        accountId: j['accountId'] as String,
        debit: (j['debit'] as num?)?.toDouble() ?? 0,
        credit: (j['credit'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String?,
        costCenterId: j['costCenterId'] as String?,
      );
}

/// قيد يومية — يجب أن يكون متوازناً (مجموع المدين = مجموع الدائن)
class JournalEntry {
  final String id;
  final String reference;   // رقم القيد
  final DateTime date;
  final String description;
  final List<JournalLine> lines;

  const JournalEntry({
    required this.id,
    required this.reference,
    required this.date,
    required this.description,
    required this.lines,
  });

  double get totalDebit =>
      lines.fold(0.0, (s, l) => s + l.debit);

  double get totalCredit =>
      lines.fold(0.0, (s, l) => s + l.credit);

  bool get isBalanced =>
      (totalDebit - totalCredit).abs() < 0.001;

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'date': date.toIso8601String(),
        'description': description,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        reference: j['reference'] as String,
        date: DateTime.parse(j['date'] as String),
        description: j['description'] as String,
        lines: (j['lines'] as List)
            .map((e) => JournalLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

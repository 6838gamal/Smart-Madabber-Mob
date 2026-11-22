// lib/models/entry_line_model.dart
class EntryLineModel {
  final String? account;
  final String? description;
  final double debit;
  final double credit;

  const EntryLineModel({
    this.account,
    this.description,
    this.debit = 0,
    this.credit = 0,
  });

  bool get isEmpty => account == null && debit == 0 && credit == 0;
  bool get isValid =>
      account != null &&
      account!.isNotEmpty &&
      ((debit > 0 && credit == 0) || (credit > 0 && debit == 0));

  EntryLineModel copyWith({
    String? account,
    String? description,
    double? debit,
    double? credit,
  }) =>
      EntryLineModel(
        account: account ?? this.account,
        description: description ?? this.description,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
      );
}


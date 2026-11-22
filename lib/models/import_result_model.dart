// lib/models/import_result_model.dart
import 'entry_line_model.dart';

enum ImportSource { image, csv, xlsx }

class ImportResultModel {
  final ImportSource source;
  final List<EntryLineModel> lines;
  final String? reference;
  final DateTime? date;
  final String? rawText;
  final List<String> warnings;

  const ImportResultModel({
    required this.source,
    required this.lines,
    this.reference,
    this.date,
    this.rawText,
    this.warnings = const [],
  });
}

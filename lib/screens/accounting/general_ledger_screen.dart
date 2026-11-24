import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';

class GeneralLedgerScreen extends StatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  String? _selectedAccountId;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month - 3, 1);
    _to = now;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الأستاذ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'تغيير الفترة',
            onPressed: () => _pickPeriod(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: provider.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(context, provider),
                const Divider(height: 1),
                Expanded(
                  child: _selectedAccountId == null
                      ? _buildNoSelection(theme)
                      : _buildLedger(provider),
                ),
              ],
            ),
    );
  }

  // ── الفلاتر (اختيار حساب + عرض الفترة) ───────────────────
  Widget _buildFilters(BuildContext context, AppProvider provider) {
    final accounts = provider.sortedLeafAccounts;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedAccountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'اختر الحساب',
                prefixIcon: Icon(Icons.account_tree_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.code} — ${a.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_periodLabel),
            onPressed: () => _pickPeriod(context),
          ),
        ],
      ),
    );
  }

  String get _periodLabel {
    if (_from == null || _to == null) return 'الفترة';
    final f = '${_from!.year}/${_from!.month.toString().padLeft(2, '0')}/${_from!.day.toString().padLeft(2, '0')}';
    final t = '${_to!.year}/${_to!.month.toString().padLeft(2, '0')}/${_to!.day.toString().padLeft(2, '0')}';
    return '$f → $t';
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'اختر فترة دفتر الأستاذ',
      saveText: 'تطبيق',
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  // ── شاشة فراغ ────────────────────────────────────────────
  Widget _buildNoSelection(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 96,
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'اختر حساباً لعرض حركاته',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر هنا كل القيود التي تؤثر على الرصيد',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── جدول دفتر الأستاذ ────────────────────────────────────
  Widget _buildLedger(AppProvider provider) {
    final account = provider.accountById(_selectedAccountId!);
    if (account == null) return _buildNoSelection(Theme.of(context));

    final movements = provider.movementsForAccount(
      account.id,
      from: _from,
      to: _to,
    );
    final opening = provider.openingBalanceFor(account.id, from: _from);
    final totalDebit = movements.fold<double>(0, (s, m) => s + m.debit);
    final totalCredit = movements.fold<double>(0, (s, m) => s + m.credit);
    final closing = opening + totalDebit - totalCredit;

    return Column(
      children: [
        _buildAccountHeader(account, opening, totalDebit, totalCredit, closing),
        const Divider(height: 1),
        Expanded(
          child: movements.isEmpty
              ? const Center(
                  child: Text('لا توجد حركات في هذه الفترة'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStatePropertyAll(
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                      ),
                      columns: const [
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('رقم القيد')),
                        DataColumn(label: Text('البيان')),
                        DataColumn(label: Text('مدين'), numeric: true),
                        DataColumn(label: Text('دائن'), numeric: true),
                        DataColumn(label: Text('الرصيد'), numeric: true),
                      ],
                      rows: _buildRows(movements, opening),
                    ),
                  ),
                ),
        ),
        _buildTotalsBar(totalDebit, totalCredit, closing),
      ],
    );
  }

  List<DataRow> _buildRows(List<LedgerMovement> movements, double opening) {
    final rows = <DataRow>[];
    double running = opening;

    // صف الرصيد الافتتاحي
    rows.add(DataRow(
      color: MaterialStatePropertyAll(
        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      ),
      cells: [
        const DataCell(Text('—')),
        const DataCell(Text('—')),
        const DataCell(Text('رصيد افتتاحي', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(Text(
          _fmt(opening),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
      ],
    ));

    for (final m in movements) {
      running += m.net;
      rows.add(DataRow(cells: [
        DataCell(Text(_fmtDate(m.date))),
        DataCell(Text(m.reference)),
        DataCell(Text(m.description, overflow: TextOverflow.ellipsis)),
        DataCell(Text(m.debit > 0 ? _fmt(m.debit) : '')),
        DataCell(Text(m.credit > 0 ? _fmt(m.credit) : '')),
        DataCell(Text(
          _fmt(running),
          style: TextStyle(
            color: running >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        )),
      ]));
    }
    return rows;
  }

  Widget _buildAccountHeader(
    Account account,
    double opening,
    double totalDebit,
    double totalCredit,
    double closing,
  ) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      color: color.primaryContainer.withOpacity(0.2),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.primary,
            child: Icon(account.type.icon, color: color.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${account.code} — ${account.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  account.type.labelAr,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _statChip('افتتاحي', opening),
          _statChip('مدين', totalDebit),
          _statChip('دائن', totalCredit),
          _statChip('ختامي', closing, bold: true),
        ],
      ),
    );
  }

  Widget _statChip(String label, double value, {bool bold = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(
            _fmt(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsBar(double debit, double credit, double closing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _totalItem('مجموع المدين', debit),
          _totalItem('مجموع الدائن', credit),
          _totalItem('الرصيد الختامي', closing, highlight: true),
        ],
      ),
    );
  }

  Widget _totalItem(String label, double value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(
          _fmt(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight
                ? (value >= 0 ? Colors.green.shade700 : Colors.red.shade700)
                : null,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v.abs() < 0.001) return '0';
    return v.toStringAsFixed(2);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

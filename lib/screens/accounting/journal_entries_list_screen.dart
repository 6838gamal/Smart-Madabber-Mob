import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_theme.dart';
import 'journal_entry_new_screen.dart';

class JournalEntriesListScreen extends StatefulWidget {
  const JournalEntriesListScreen({super.key});

  @override
  State<JournalEntriesListScreen> createState() =>
      _JournalEntriesListScreenState();
}

class _JournalEntriesListScreenState extends State<JournalEntriesListScreen> {
  String _search = '';
  _DateRange _range = _DateRange.all;

  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = _applyFilters(provider.journalEntries);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: entries.isEmpty
                ? _buildEmpty(context)
                : _buildList(provider, entries),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_entry_from_list',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('قيد جديد'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const JournalEntryNewScreen(),
            ),
          );
        },
      ),
    );
  }

  // ── Toolbar ─────────────────────────────────────────────
  Widget _buildToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث بالمرجع أو الوصف...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _rangeChip('الكل', _DateRange.all),
                const SizedBox(width: 6),
                _rangeChip('هذا الشهر', _DateRange.thisMonth),
                const SizedBox(width: 6),
                _rangeChip('آخر 30 يوم', _DateRange.last30),
                const SizedBox(width: 6),
                _rangeChip('مخصص', _DateRange.custom),
              ],
            ),
          ),
          if (_range == _DateRange.custom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickCustomDate(isFrom: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'من',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event, size: 18),
                      ),
                      child: Text(
                        _customFrom == null
                            ? '—'
                            : _formatDate(_customFrom!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickCustomDate(isFrom: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'إلى',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event, size: 18),
                      ),
                      child: Text(
                        _customTo == null ? '—' : _formatDate(_customTo!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _rangeChip(String label, _DateRange value) {
    final selected = _range == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) async {
        if (value == _DateRange.custom) {
          setState(() => _range = value);
        } else {
          setState(() => _range = value);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  // ── List ────────────────────────────────────────────────
  Widget _buildList(AppProvider provider, List<JournalEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: entries.length,
      itemBuilder: (_, i) => _buildEntryCard(provider, entries[i]),
    );
  }

  Widget _buildEntryCard(AppProvider provider, JournalEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDebit = entry.lines.fold(0.0, (s, l) => s + l.debit);
    final totalCredit = entry.lines.fold(0.0, (s, l) => s + l.credit);
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(
              balanced ? Icons.check : Icons.warning_amber_rounded,
              color: balanced ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(entry.date),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          subtitle: Text(
            entry.description.isEmpty ? '—' : entry.description,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) async {
              if (v == 'delete') {
                await _confirmDelete(provider, entry);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('حذف القيد')),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildLineHeader(isDark),
            const SizedBox(height: 4),
            ...entry.lines.map((l) => _buildLineRow(provider, l)),
            const SizedBox(height: 4),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _totalRow(
                    'مدين',
                    totalDebit,
                    Colors.green,
                    provider,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _totalRow(
                    'دائن',
                    totalCredit,
                    Colors.red,
                    provider,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineHeader(bool isDark) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : Colors.black54,
    );
    return Row(
      children: [
        Expanded(flex: 5, child: Text('الحساب', style: style)),
        Expanded(
            flex: 2,
            child: Text('مدين', style: style, textAlign: TextAlign.end)),
        Expanded(
            flex: 2,
            child: Text('دائن', style: style, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildLineRow(AppProvider provider, JournalLine line) {
    final account = provider.accountById(line.accountId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              account == null
                  ? line.accountId
                  : '${account.code} — ${account.name}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              line.debit > 0 ? line.debit.toStringAsFixed(2) : '—',
              style: const TextStyle(fontSize: 12, color: Colors.green),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              line.credit > 0 ? line.credit.toStringAsFixed(2) : '—',
              style: const TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double amount,
    Color color,
    AppProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            provider.formatAmount(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    final hasFilter = _search.isNotEmpty || _range != _DateRange.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'لا توجد نتائج مطابقة' : 'لا توجد قيود بعد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'جرّب تغيير البحث أو الفترة'
                  : 'ابدأ بإضافة قيد جديد',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtering ──────────────────────────────────────────
  List<JournalEntry> _applyFilters(List<JournalEntry> src) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;

    switch (_range) {
      case _DateRange.all:
        break;
      case _DateRange.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case _DateRange.last30:
        from = now.subtract(const Duration(days: 30));
        to = now;
        break;
      case _DateRange.custom:
        from = _customFrom;
        to = _customTo?.add(const Duration(days: 1));
        break;
    }

    final q = _search.toLowerCase();
    final list = src.where((e) {
      if (from != null && e.date.isBefore(from)) return false;
      if (to != null && e.date.isAfter(to)) return false;
      if (q.isEmpty) return true;
      return e.reference.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> _confirmDelete(
    AppProvider provider,
    JournalEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القيد'),
        content: Text(
          'هل تريد حذف القيد "${entry.reference}"؟\n'
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.deleteJournalEntry(entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف القيد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Date picker ────────────────────────────────────────
  Future<void> _pickCustomDate({required bool isFrom}) async {
    final now = DateTime.now();
    final init = isFrom
        ? (_customFrom ?? now.subtract(const Duration(days: 30)))
        : (_customTo ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _customFrom = picked;
      } else {
        _customTo = picked;
      }
    });
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

enum _DateRange { all, thisMonth, last30, custom }

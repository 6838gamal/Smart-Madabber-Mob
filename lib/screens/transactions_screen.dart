import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import '../models/resource.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filterType;
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cutoff = DateTime.now().subtract(Duration(days: _days));
    var txns = provider.transactions
        .where((t) =>
            t.date.isAfter(cutoff) &&
            (_filterType == null || t.type == _filterType))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        _buildHeader(context, isDark, provider, txns.length),
        Expanded(
          child: txns.isEmpty
              ? EmptyState(
                  emoji: '📋',
                  title: 'No transactions',
                  subtitle: 'Log your first transaction above.',
                  actionLabel: 'Add Transaction',
                  onAction: () => _showAdd(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _TxnRow(txn: txns[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark,
      AppProvider provider, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transactions',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)),
                  Text('$count entries',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAdd(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(
                    label: 'All',
                    selected: _filterType == null,
                    onTap: () =>
                        setState(() => _filterType = null)),
                const SizedBox(width: 6),
                ...TransactionType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Chip(
                          label: '${t.emoji} ${t.label}',
                          selected: _filterType == t,
                          onTap: () => setState(
                              () => _filterType = t)),
                    )),
                const SizedBox(width: 6),
                _Chip(
                    label: '7 days',
                    selected: _days == 7,
                    onTap: () => setState(() => _days = 7)),
                const SizedBox(width: 6),
                _Chip(
                    label: '30 days',
                    selected: _days == 30,
                    onTap: () => setState(() => _days = 30)),
                const SizedBox(width: 6),
                _Chip(
                    label: 'All time',
                    selected: _days == 3650,
                    onTap: () => setState(() => _days = 3650)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdd(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => const _AddTransactionDialog());
  }
}

class _TxnRow extends StatelessWidget {
  final Transaction txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();
    final resource = provider.resources
        .where((r) => r.id == txn.resourceId)
        .firstOrNull;

    final Color typeColor;
    switch (txn.type) {
      case TransactionType.purchase:
        typeColor = AppColors.primary;
        break;
      case TransactionType.consume:
        typeColor = AppColors.warning;
        break;
      case TransactionType.sale:
        typeColor = AppColors.success;
        break;
      case TransactionType.adjustment:
        typeColor = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(txn.type.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource?.name ?? 'Unknown Resource',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${txn.type.label} · ${txn.quantity.toStringAsFixed(1)} ${resource?.unit ?? ''}${txn.note.isNotEmpty ? ' · ${txn.note}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (txn.price > 0)
                Text(
                  '${txn.type == TransactionType.sale ? '+' : '-'}${provider.currency} ${txn.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: txn.type == TransactionType.sale
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              Text(
                DateFormat('MMM d').format(txn.date),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            onPressed: () => provider.deleteTransaction(txn.id),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? AppColors.primary
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  const _AddTransactionDialog();

  @override
  State<_AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState
    extends State<_AddTransactionDialog> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.consume;
  String? _selectedResourceId;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedResourceId,
              decoration:
                  const InputDecoration(labelText: 'Resource *'),
              items: provider.resources
                  .map((r) => DropdownMenuItem(
                      value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedResourceId = v),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              segments: TransactionType.values
                  .map((t) => ButtonSegment(
                      value: t, label: Text(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (v) =>
                  setState(() => _type = v.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Quantity *'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }

  void _save() {
    if (_selectedResourceId == null) return;
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;
    context.read<AppProvider>().addTransaction(Transaction(
          id: const Uuid().v4(),
          resourceId: _selectedResourceId!,
          type: _type,
          quantity: qty,
          price: double.tryParse(_priceCtrl.text) ?? 0,
          date: DateTime.now(),
          note: _noteCtrl.text.trim(),
        ));
    Navigator.pop(context);
  }
}

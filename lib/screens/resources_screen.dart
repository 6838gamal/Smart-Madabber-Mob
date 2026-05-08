import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _search = '';
  ResourceStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var filtered = provider.resources.where((r) {
      final matchSearch =
          r.name.toLowerCase().contains(_search.toLowerCase());
      final matchStatus =
          _filterStatus == null || r.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();

    return Column(
      children: [
        _buildHeader(context, isDark, provider),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  emoji: '📦',
                  title: 'No resources found',
                  subtitle: _search.isNotEmpty
                      ? 'Try a different search term.'
                      : 'Start by adding your first resource.',
                  actionLabel:
                      _search.isEmpty ? 'Add Resource' : null,
                  onAction: _search.isEmpty
                      ? () => _showAddResource(context)
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _ResourceRow(resource: filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resources',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddResource(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Resource'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search resources...',
              prefixIcon:
                  Icon(Icons.search_rounded, size: 18),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () =>
                      setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '🚨 Critical',
                  selected:
                      _filterStatus == ResourceStatus.critical,
                  color: AppColors.critical,
                  onTap: () => setState(() =>
                      _filterStatus = ResourceStatus.critical),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '⚠️ Low',
                  selected:
                      _filterStatus == ResourceStatus.low,
                  color: AppColors.warning,
                  onTap: () => setState(
                      () => _filterStatus = ResourceStatus.low),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '✅ Normal',
                  selected:
                      _filterStatus == ResourceStatus.normal,
                  color: AppColors.success,
                  onTap: () => setState(() =>
                      _filterStatus = ResourceStatus.normal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResource(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _ResourceDialog(),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final Resource resource;
  const _ResourceRow({required this.resource});

  Color get _statusColor {
    switch (resource.status) {
      case ResourceStatus.critical:
        return AppColors.critical;
      case ResourceStatus.low:
        return AppColors.warning;
      case ResourceStatus.inactive:
        return AppColors.inactive;
      case ResourceStatus.normal:
        return AppColors.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();
    final pct = resource.stockPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resource.status == ResourceStatus.critical
              ? AppColors.critical.withOpacity(0.35)
              : resource.status == ResourceStatus.low
                  ? AppColors.warning.withOpacity(0.25)
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _typeEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${resource.type.label} · ${resource.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resource.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                onSelected: (v) {
                  if (v == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _ResourceDialog(resource: resource),
                    );
                  } else if (v == 'delete') {
                    _confirmDelete(context, provider);
                  } else if (v == 'transact') {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _QuickTransactionDialog(resource: resource),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'transact',
                      child: Row(children: [
                        Icon(Icons.swap_horiz_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Add Transaction'),
                      ])),
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 16, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Delete',
                            style:
                                TextStyle(color: AppColors.danger)),
                      ])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${resource.currentQuantity.toStringAsFixed(1)} ${resource.unit}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        Text(
                          'min: ${resource.minThreshold} ${resource.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (resource.dailyConsumptionRate > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      resource.daysRemaining.isFinite
                          ? '~${resource.daysRemaining.toStringAsFixed(0)}d left'
                          : '∞',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${resource.dailyConsumptionRate.toStringAsFixed(1)}/day',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _typeEmoji {
    switch (resource.type) {
      case ResourceType.consumable:
        return '🛒';
      case ResourceType.rawMaterial:
        return '⚙️';
      case ResourceType.product:
        return '📦';
      case ResourceType.asset:
        return '🏢';
      case ResourceType.ingredient:
        return '🍳';
      case ResourceType.other:
        return '📋';
    }
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
            'Delete "${resource.name}"? All related transactions will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              provider.deleteResource(resource.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? c.withOpacity(0.12)
              : isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? c : isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? c
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _ResourceDialog extends StatefulWidget {
  final Resource? resource;
  const _ResourceDialog({this.resource});

  @override
  State<_ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends State<_ResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _qty;
  late TextEditingController _min;
  late TextEditingController _unit;
  late TextEditingController _rate;
  ResourceType _type = ResourceType.consumable;

  @override
  void initState() {
    super.initState();
    final r = widget.resource;
    _name = TextEditingController(text: r?.name ?? '');
    _qty = TextEditingController(
        text: r?.currentQuantity.toString() ?? '');
    _min = TextEditingController(
        text: r?.minThreshold.toString() ?? '');
    _unit = TextEditingController(text: r?.unit ?? '');
    _rate = TextEditingController(
        text: r?.dailyConsumptionRate.toString() ?? '0');
    _type = r?.type ?? ResourceType.consumable;
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _min.dispose();
    _unit.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.resource != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Resource' : 'Add Resource'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: 'Name *'),
                  validator: (v) =>
                      v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ResourceType>(
                  value: _type,
                  decoration:
                      const InputDecoration(labelText: 'Type'),
                  items: ResourceType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qty,
                        decoration: const InputDecoration(
                            labelText: 'Current Qty *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            double.tryParse(v!) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(
                            labelText: 'Unit *'),
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _min,
                        decoration: const InputDecoration(
                            labelText: 'Min Threshold *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            double.tryParse(v!) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _rate,
                        decoration: const InputDecoration(
                            labelText: 'Daily Rate'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final r = widget.resource;
    final resource = Resource(
      id: r?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      type: _type,
      currentQuantity: double.parse(_qty.text),
      minThreshold: double.parse(_min.text),
      unit: _unit.text.trim(),
      dailyConsumptionRate: double.tryParse(_rate.text) ?? 0,
      createdAt: r?.createdAt ?? DateTime.now(),
      lastActivityAt: r?.lastActivityAt,
    );
    if (r != null) {
      provider.updateResource(resource);
    } else {
      provider.addResource(resource);
    }
    Navigator.pop(context);
  }
}

class _QuickTransactionDialog extends StatefulWidget {
  final Resource resource;
  const _QuickTransactionDialog({required this.resource});

  @override
  State<_QuickTransactionDialog> createState() =>
      _QuickTransactionDialogState();
}

class _QuickTransactionDialogState
    extends State<_QuickTransactionDialog> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  var _type = TransactionType.consume;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transaction: ${widget.resource.name}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: TransactionType.values
                  .map((t) => ButtonSegment(
                      value: t, label: Text(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (v) =>
                  setState(() => _type = v.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: InputDecoration(
                      labelText:
                          'Quantity (${widget.resource.unit})',
                    ),
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
                  const InputDecoration(labelText: 'Note (optional)'),
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
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;
    context.read<AppProvider>().addTransaction(
          Transaction(
            id: const Uuid().v4(),
            resourceId: widget.resource.id,
            type: _type,
            quantity: qty,
            price: double.tryParse(_priceCtrl.text) ?? 0,
            date: DateTime.now(),
            note: _noteCtrl.text.trim(),
          ),
        );
    Navigator.pop(context);
  }
}

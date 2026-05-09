import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = L10n.of(context);
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
        _buildHeader(context, isDark, provider, l10n),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  emoji: '📦',
                  title: l10n.noResourcesFound,
                  subtitle: _search.isNotEmpty
                      ? l10n.tryDifferentSearch
                      : l10n.startByAdding,
                  actionLabel:
                      _search.isEmpty ? l10n.addResource : null,
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
      BuildContext context, bool isDark, AppProvider provider, L10n l10n) {
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
                l10n.resources,
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
                label: Text(l10n.addResource),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: l10n.searchResources,
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 18),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.all,
                  selected: _filterStatus == null,
                  onTap: () =>
                      setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '🚨 ${l10n.critical}',
                  selected:
                      _filterStatus == ResourceStatus.critical,
                  color: AppColors.critical,
                  onTap: () => setState(() =>
                      _filterStatus = ResourceStatus.critical),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '⚠️ ${l10n.low}',
                  selected: _filterStatus == ResourceStatus.low,
                  color: AppColors.warning,
                  onTap: () => setState(
                      () => _filterStatus = ResourceStatus.low),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '✅ ${l10n.normal}',
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
    final l10n = L10n.of(context);
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
                    _confirmDelete(context, provider, l10n);
                  } else if (v == 'transact') {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _QuickTransactionDialog(resource: resource),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'transact',
                      child: Row(children: [
                        const Icon(Icons.swap_horiz_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.addTransaction),
                      ])),
                  PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ])),
                  PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_rounded,
                            size: 16, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: const TextStyle(
                                color: AppColors.danger)),
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
                          '${l10n.minPrefix}${resource.minThreshold} ${resource.unit}',
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
                          ? '~${resource.daysRemaining.toStringAsFixed(0)}d'
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

  void _confirmDelete(
      BuildContext context, AppProvider provider, L10n l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(
            '${l10n.deleteConfirmMsg}\n"${resource.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              provider.deleteResource(resource.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete),
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
            color: selected
                ? c
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
    final l10n = L10n.of(context);
    final isEdit = widget.resource != null;
    return AlertDialog(
      title: Text(isEdit ? l10n.editResource : l10n.newResource),
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
                  decoration: InputDecoration(
                      labelText: '${l10n.resourceNameLabel} *'),
                  validator: (v) =>
                      v!.isEmpty ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ResourceType>(
                  value: _type,
                  decoration: InputDecoration(
                      labelText: l10n.resourceTypeLabel),
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
                        decoration: InputDecoration(
                            labelText:
                                '${l10n.currentQuantityLabel} *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            double.tryParse(v!) == null
                                ? '!'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: InputDecoration(
                            labelText: '${l10n.unitLabel} *'),
                        validator: (v) =>
                            v!.isEmpty ? '!' : null,
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
                        decoration: InputDecoration(
                            labelText:
                                '${l10n.minThresholdLabel} *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            double.tryParse(v!) == null
                                ? '!'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _rate,
                        decoration: InputDecoration(
                            labelText: l10n.dailyRateLabel),
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
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? l10n.save : l10n.addResource),
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
    final l10n = L10n.of(context);
    return AlertDialog(
      title: Text('${l10n.addTransaction}: ${widget.resource.name}'),
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
                          '${l10n.quantityLabel} (${widget.resource.unit})',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.priceLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration:
                  InputDecoration(labelText: l10n.notesLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel)),
        ElevatedButton(
            onPressed: _save,
            child: Text(l10n.addTransaction)),
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

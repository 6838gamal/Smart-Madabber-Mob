import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/cost_center.dart';
import '../../theme/app_theme.dart';

class CostCentersScreen extends StatefulWidget {
  const CostCentersScreen({super.key});

  @override
  State<CostCentersScreen> createState() => _CostCentersScreenState();
}

class _CostCentersScreenState extends State<CostCentersScreen> {
  DateTime? _from;
  DateTime? _to;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, 1, 1);
    _to = now;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final centers = _applyFilters(provider.sortedCostCenters);
    final totals = provider.totalsByCostCenter(from: _from, to: _to);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: centers.isEmpty
                ? _buildEmpty(context)
                : _buildList(provider, centers, totals),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_cost_center_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('مركز جديد'),
        onPressed: () => _openForm(provider, null),
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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isFrom: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'من',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event, size: 18),
                    ),
                    child: Text(
                      _from == null ? '—' : _formatDate(_from!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isFrom: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'إلى',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event, size: 18),
                    ),
                    child: Text(_to == null ? '—' : _formatDate(_to!)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الرمز...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
        ],
      ),
    );
  }

  // ── List ────────────────────────────────────────────────
  Widget _buildList(
    AppProvider provider,
    List<CostCenter> centers,
    Map<String, ({double debit, double credit})> totals,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: centers.length,
      itemBuilder: (_, i) {
        final c = centers[i];
        final t = totals[c.id];
        final debit = t?.debit ?? 0;
        final credit = t?.credit ?? 0;
        return _buildRow(provider, c, debit, credit);
      },
    );
  }

  Widget _buildRow(
    AppProvider provider,
    CostCenter c,
    double debit,
    double credit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = debit - credit;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Text(
              c.code,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!c.isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'غير نشط',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'مدين: ${provider.formatAmount(debit)}  |  '
                  'دائن: ${provider.formatAmount(credit)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Text(
                'الصافي: ${provider.formatAmount(net.abs())}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (v) async {
            if (v == 'edit') _openForm(provider, c);
            if (v == 'delete') await _confirmDelete(provider, c);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  // ── Form ────────────────────────────────────────────────
  Future<void> _openForm(AppProvider provider, CostCenter? existing) async {
    final result = await showModalBottomSheet<CostCenter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CostCenterFormSheet(
        provider: provider,
        existing: existing,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      await provider.addCostCenter(result);
    } else {
      await provider.updateCostCenter(result);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'تمت إضافة المركز' : 'تم تحديث المركز',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AppProvider provider, CostCenter c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مركز التكلفة'),
        content: Text(
          'هل تريد حذف "${c.name}"؟\n'
          'لا يمكن الحذف إذا كانت هناك حركات أو مراكز فرعية.',
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
      await provider.deleteCostCenter(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Filters ────────────────────────────────────────────
  List<CostCenter> _applyFilters(List<CostCenter> src) {
    if (_search.isEmpty) return src;
    final q = _search.toLowerCase();
    return src
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q))
        .toList();
  }

  // ── Helpers ─────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final init = isFrom ? (_from ?? now) : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _search.isEmpty
                  ? 'لا توجد مراكز تكلفة بعد'
                  : 'لا توجد نتائج مطابقة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _search.isEmpty
                  ? 'أضف مركزاً لتصنيف الحركات حسب الأقسام'
                  : 'جرّب تغيير البحث',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Form Sheet
// ============================================================
class _CostCenterFormSheet extends StatefulWidget {
  final AppProvider provider;
  final CostCenter? existing;

  const _CostCenterFormSheet({required this.provider, this.existing});

  @override
  State<_CostCenterFormSheet> createState() => _CostCenterFormSheetState();
}

class _CostCenterFormSheetState extends State<_CostCenterFormSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  String? _parentId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _parentId = e?.parentId;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final possibleParents = widget.provider.sortedCostCenters.where((c) {
      if (isEdit && c.id == widget.existing!.id) return false;
      if (isEdit && _isDescendantOf(c.id, widget.existing!.id)) return false;
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'تعديل مركز' : 'مركز تكلفة جديد',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'الرمز',
                hintText: 'مثال: 01 أو CC-01',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المركز',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _parentId,
              decoration: const InputDecoration(
                labelText: 'المركز الأب (اختياري)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— مركز جذر —'),
                ),
                ...possibleParents.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text('${c.code} — ${c.name}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('نشط'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _submit,
                    child: Text(isEdit ? 'حفظ' : 'إضافة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (code.isEmpty) {
      _snack('الرجاء إدخال الرمز');
      return;
    }
    if (name.isEmpty) {
      _snack('الرجاء إدخال الاسم');
      return;
    }
    final isEdit = widget.existing != null;
    final exists = widget.provider.sortedCostCenters.any(
      (c) => c.code == code && (!isEdit || c.id != widget.existing!.id),
    );
    if (exists) {
      _snack('الرمز مستخدم بالفعل');
      return;
    }

    final existing = widget.existing;
    final result = existing != null
        ? existing.copyWith(
            code: code,
            name: name,
            parentId: _parentId,
            clearParent: _parentId == null,
            isActive: _isActive,
          )
        : CostCenter(
            id: 'cc_${DateTime.now().microsecondsSinceEpoch}',
            code: code,
            name: name,
            parentId: _parentId,
            isActive: _isActive,
          );
    Navigator.pop(context, result);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  bool _isDescendantOf(String maybeChildId, String maybeAncestorId) {
    var cur = widget.provider.costCenterById(maybeChildId);
    var safety = 0;
    while (cur != null && cur.parentId != null && safety < 50) {
      if (cur.parentId == maybeAncestorId) return true;
      cur = widget.provider.costCenterById(cur.parentId!);
      safety++;
    }
    return false;
  }
}

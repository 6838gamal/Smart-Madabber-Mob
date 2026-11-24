import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  String _search = '';
  AccountType? _filterType;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final accounts = _applyFilters(provider.sortedAccounts);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context, provider),
          Expanded(
            child: accounts.isEmpty
                ? _buildEmpty(context)
                : _buildList(context, provider, accounts),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_account_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('حساب جديد'),
        onPressed: () => _openAccountForm(context, provider, null),
      ),
    );
  }

  // ── Toolbar ─────────────────────────────────────────────
  Widget _buildToolbar(BuildContext context, AppProvider provider) {
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
              hintText: 'بحث بالاسم أو الرمز...',
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
                _filterChip('الكل', null),
                const SizedBox(width: 6),
                ...AccountType.values.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _filterChip(_typeLabel(t), t),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, AccountType? type) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: AppColors.primary.withOpacity(0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  // ── List ────────────────────────────────────────────────
  Widget _buildList(
    BuildContext context,
    AppProvider provider,
    List<Account> accounts,
  ) {
    // نبني شجرة: الحسابات الجذرية أولاً ثم أبناؤها
    final byParent = <String?, List<Account>>{};
    for (final a in accounts) {
      byParent.putIfAbsent(a.parentId, () => []).add(a);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.code.compareTo(b.code));
    }

    final rows = <Widget>[];
    void walk(String? parentId, int depth) {
      final children = byParent[parentId] ?? [];
      for (final a in children) {
        rows.add(_buildRow(context, provider, a, depth));
        walk(a.id, depth + 1);
      }
    }

    walk(null, 0);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppProvider provider,
    Account account,
    int depth,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = provider.currentBalanceFor(account.id);
    final typeColor = _typeColor(account.type);
    final isLeaf = provider.leafAccounts.any((a) => a.id == account.id);

    return InkWell(
      onTap: () => _openAccountForm(context, provider, account),
      child: Container(
        padding: EdgeInsets.fromLTRB(12 + depth * 16.0, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!isLeaf)
                        const Icon(Icons.folder_rounded,
                            size: 14, color: Colors.grey),
                      if (isLeaf)
                        const Icon(Icons.description_outlined,
                            size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _typeLabel(account.type),
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  provider.formatAmount(balance.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: balance == 0 ? Colors.grey : null,
                  ),
                ),
                Text(
                  _balanceSide(account.type, balance),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    _openAccountForm(context, provider, account);
                    break;
                  case 'delete':
                    await _confirmDelete(context, provider, account);
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _search.isEmpty && _filterType == null
                  ? 'لا توجد حسابات بعد'
                  : 'لا توجد نتائج مطابقة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _search.isEmpty && _filterType == null
                  ? 'ابدأ بإضافة حساب جديد'
                  : 'جرّب تغيير كلمة البحث أو النوع',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ── Form (Add / Edit) ───────────────────────────────────
  Future<void> _openAccountForm(
    BuildContext context,
    AppProvider provider,
    Account? existing,
  ) async {
    final result = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AccountFormSheet(
        provider: provider,
        existing: existing,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      await provider.addAccount(result);
    } else {
      await provider.updateAccount(result);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'تمت إضافة الحساب' : 'تم تحديث الحساب',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppProvider provider,
    Account account,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text(
          'هل تريد حذف "${account.name}"؟\n'
          'لا يمكن الحذف إذا كانت هناك حركات مرتبطة به.',
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
      await provider.deleteAccount(account.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────
  List<Account> _applyFilters(List<Account> src) {
    return src.where((a) {
      if (_filterType != null && a.type != _filterType) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q);
    }).toList();
  }

  String _typeLabel(AccountType t) {
    switch (t) {
      case AccountType.asset:
        return 'أصول';
      case AccountType.liability:
        return 'التزامات';
      case AccountType.equity:
        return 'حقوق ملكية';
      case AccountType.revenue:
        return 'إيرادات';
      case AccountType.expense:
        return 'مصروفات';
    }
  }

  Color _typeColor(AccountType t) {
    switch (t) {
      case AccountType.asset:
        return const Color(0xFF1976D2); // أزرق
      case AccountType.liability:
        return const Color(0xFFD32F2F); // أحمر
      case AccountType.equity:
        return const Color(0xFF7B1FA2); // بنفسجي
      case AccountType.revenue:
        return const Color(0xFF2E7D32); // أخضر
      case AccountType.expense:
        return const Color(0xFFEF6C00); // برتقالي
    }
  }

  String _balanceSide(AccountType type, double balance) {
    // الأصول والمصروفات طبيعتها مدين، الباقي دائن
    final isDebitNature = type == AccountType.asset || type == AccountType.expense;
    if (balance == 0) return '—';
    if (isDebitNature) {
      return balance > 0 ? 'مدين' : 'دائن';
    } else {
      return balance < 0 ? 'مدين' : 'دائن';
    }
  }
}

// ============================================================
// Form Sheet
// ============================================================
class _AccountFormSheet extends StatefulWidget {
  final AppProvider provider;
  final Account? existing;

  const _AccountFormSheet({required this.provider, this.existing});

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late AccountType _type;
  String? _parentId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _type = e?.type ?? AccountType.asset;
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

    // الحسابات الممكنة كأب: نفس النوع، وليست نفس الحساب أو أحد أبنائه
    final possibleParents = widget.provider.sortedAccounts.where((a) {
      if (a.type != _type) return false;
      if (isEdit && a.id == widget.existing!.id) return false;
      // منع الحلقة: لا يمكن أن يكون الأب من أبناء الحساب نفسه
      if (isEdit && _isDescendantOf(a.id, widget.existing!.id)) return false;
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
              isEdit ? 'تعديل حساب' : 'حساب جديد',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // الكود
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'رمز الحساب',
                hintText: 'مثال: 1101',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),

            // الاسم
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الحساب',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // النوع
            DropdownButtonFormField<AccountType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'النوع',
                border: OutlineInputBorder(),
              ),
              items: AccountType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabelStatic(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  // إعادة تعيين الأب إن لم يعد من نفس النوع
                  if (_parentId != null) {
                    final parent = widget.provider.accountById(_parentId!);
                    if (parent == null || parent.type != v) {
                      _parentId = null;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // الأب
            DropdownButtonFormField<String?>(
              value: _parentId,
              decoration: const InputDecoration(
                labelText: 'الحساب الأب (اختياري)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— حساب جذر —'),
                ),
                ...possibleParents.map(
                  (a) => DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text('${a.code} — ${a.name}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),

            // نشط
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('حساب نشط'),
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
      _snack('الرجاء إدخال رمز الحساب');
      return;
    }
    if (name.isEmpty) {
      _snack('الرجاء إدخال اسم الحساب');
      return;
    }

    final isEdit = widget.existing != null;
    final exists = widget.provider.sortedAccounts.any(
      (a) => a.code == code && (!isEdit || a.id != widget.existing!.id),
    );
    if (exists) {
      _snack('رمز الحساب مستخدم بالفعل');
      return;
    }

    final existing = widget.existing;
    final account = existing != null
        ? existing.copyWith(
            code: code,
            name: name,
            type: _type,
            parentId: _parentId,
            clearParent: _parentId == null,
            isActive: _isActive,
          )
        : Account(
            id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
            code: code,
            name: name,
            type: _type,
            parentId: _parentId,
            isActive: _isActive,
          );

    Navigator.pop(context, account);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  bool _isDescendantOf(String maybeChildId, String maybeAncestorId) {
    var cur = widget.provider.accountById(maybeChildId);
    var safety = 0;
    while (cur != null && cur.parentId != null && safety < 50) {
      if (cur.parentId == maybeAncestorId) return true;
      cur = widget.provider.accountById(cur.parentId!);
      safety++;
    }
    return false;
  }

  String _typeLabelStatic(AccountType t) {
    switch (t) {
      case AccountType.asset:
        return 'أصول';
      case AccountType.liability:
        return 'التزامات';
      case AccountType.equity:
        return 'حقوق ملكية';
      case AccountType.revenue:
        return 'إيرادات';
      case AccountType.expense:
        return 'مصروفات';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../providers/purchases_provider.dart';
import '../../theme/app_theme.dart';
import 'supplier_form_screen.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchasesProvider>();
    final items = provider.searchSuppliers(_query);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('مورد جديد'),
        onPressed: () => _openForm(context, null),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الكود أو الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _chip('الإجمالي', '${provider.suppliers.length}',
                        Icons.local_shipping_outlined, AppColors.primary),
                    const SizedBox(width: 8),
                    _chip('نشط', '${provider.activeSuppliers.length}',
                        Icons.check_circle_outlined, Colors.green),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? _empty(provider.suppliers.isEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _tile(context, items[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _empty(bool none) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(none ? 'لا يوجد موردون بعد' : 'لا توجد نتائج'),
            const SizedBox(height: 8),
            if (none)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('أضف أول مورد'),
                onPressed: () => _openForm(context, null),
              ),
          ],
        ),
      );

  Widget _tile(BuildContext context, Supplier s) {
    final statusColor = switch (s.status) {
      SupplierStatus.active => Colors.green,
      SupplierStatus.inactive => Colors.orange,
      SupplierStatus.blocked => Colors.red,
    };
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(
            s.name.isNotEmpty ? s.name[0] : '?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        title: Row(children: [
          Expanded(
              child: Text(s.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              switch (s.status) {
                SupplierStatus.active => 'نشط',
                SupplierStatus.inactive => 'غير نشط',
                SupplierStatus.blocked => 'محظور',
              },
              style: TextStyle(fontSize: 10, color: statusColor),
            ),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${s.code} • ${s.phone ?? "بلا هاتف"}',
                style: const TextStyle(fontSize: 12)),
            if (s.balance != 0)
              Text(
                'مديونيتنا له: ${s.balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: s.balance > 0 ? Colors.redAccent : Colors.green,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            if (v == 'edit') _openForm(context, s);
            if (v == 'delete') _confirmDelete(context, s);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('تعديل'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('حذف', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        onTap: () => _openForm(context, s),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Supplier? s) async {
    final result = await Navigator.push<Supplier>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: s)),
    );
    if (result != null && context.mounted) {
      final provider = context.read<PurchasesProvider>();
      try {
        if (s == null) {
          await provider.addSupplier(result);
        } else {
          await provider.updateSupplier(result);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(s == null ? 'تم إضافة المورد' : 'تم التحديث'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف المورد "${s.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<PurchasesProvider>().deleteSupplier(s.id);
      if (context.mounted) setState(() {});
    }
  }
}

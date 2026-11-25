import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sales_provider.dart';
import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final items = provider.search(_query);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('عميل جديد'),
        onPressed: () => _openForm(context, null),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── شريط البحث ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الكود أو الهاتف...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                ),

                // ── إحصائية سريعة ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _chip('الإجمالي', '${provider.customers.length}',
                          Icons.people_alt_rounded, AppColors.primary),
                      const SizedBox(width: 8),
                      _chip('نشط', '${provider.activeCustomers.length}',
                          Icons.check_circle_rounded, Colors.green),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── القائمة ──
                Expanded(
                  child: items.isEmpty
                      ? _emptyState(provider.customers.isEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _customerTile(
                              context, items[i], isDark),
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
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text('$label: ',
                style: TextStyle(fontSize: 12, color: color)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool noCustomersAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              noCustomersAtAll
                  ? 'لا يوجد عملاء بعد'
                  : 'لا توجد نتائج مطابقة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (noCustomersAtAll)
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('أضف أول عميل'),
                onPressed: () => _openForm(context, null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _customerTile(BuildContext context, Customer c, bool isDark) {
    final statusColor = switch (c.status) {
      CustomerStatus.active => Colors.green,
      CustomerStatus.inactive => Colors.orange,
      CustomerStatus.blocked => Colors.red,
    };

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(
            c.name.isNotEmpty ? c.name[0] : '?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(c.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                switch (c.status) {
                  CustomerStatus.active => 'نشط',
                  CustomerStatus.inactive => 'غير نشط',
                  CustomerStatus.blocked => 'محظور',
                },
                style: TextStyle(fontSize: 10, color: statusColor),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${c.code} • ${c.phone ?? "بلا هاتف"}',
                style: const TextStyle(fontSize: 12)),
            if (c.balance != 0)
              Text(
                'الرصيد: ${c.balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.balance > 0 ? Colors.redAccent : Colors.green,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) {
            switch (v) {
              case 'edit':
                _openForm(context, c);
                break;
              case 'delete':
                _confirmDelete(context, c);
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 8),
                Text('تعديل'),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('حذف', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        onTap: () => _openForm(context, c),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Customer? customer) async {
    final result = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
    if (result != null && context.mounted) {
      final provider = context.read<SalesProvider>();
      try {
        if (customer == null) {
          await provider.addCustomer(result);
        } else {
          await provider.updateCustomer(result);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(customer == null
                  ? 'تم إضافة العميل'
                  : 'تم تحديث العميل'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف العميل "${c.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SalesProvider>().deleteCustomer(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف العميل'),
              backgroundColor: Colors.green),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/purchase_invoice.dart';
import '../../providers/purchases_provider.dart';
import '../../theme/app_theme.dart';
import 'purchase_invoice_new_screen.dart';

class PurchaseInvoicesListScreen extends StatefulWidget {
  const PurchaseInvoicesListScreen({super.key});

  @override
  State<PurchaseInvoicesListScreen> createState() =>
      _PurchaseInvoicesListScreenState();
}

class _PurchaseInvoicesListScreenState
    extends State<PurchaseInvoicesListScreen> {
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
    final all = provider.sortedInvoices;
    final filtered = _query.isEmpty
        ? all
        : all.where((i) {
            final q = _query.toLowerCase();
            return i.invoiceNumber.toLowerCase().contains(q) ||
                i.supplierName.toLowerCase().contains(q);
          }).toList();

    final total = filtered.fold<double>(0, (s, i) => s + i.grandTotal);
    final unpaid = filtered
        .where((i) => i.paymentStatus != PurchasePaymentStatus.paid)
        .length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('فاتورة شراء جديدة'),
        onPressed: () => _openNew(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'بحث برقم الفاتورة أو اسم المورد...',
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
              _stat('العدد', '${filtered.length}', Icons.receipt_long, Colors.blue),
              const SizedBox(width: 8),
              _stat('إجمالي', total.toStringAsFixed(0), Icons.attach_money, Colors.green),
              const SizedBox(width: 8),
              _stat('غير مسدّدة', '$unpaid', Icons.pending_actions, Colors.orange),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? _empty(all.isEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tile(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(label,
                        style: TextStyle(fontSize: 11, color: color),
                        overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ],
          ),
        ),
      );

  Widget _empty(bool none) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(none ? 'لا توجد فواتير بعد' : 'لا توجد نتائج'),
            const SizedBox(height: 8),
            if (none)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إنشاء أول فاتورة'),
                onPressed: () => _openNew(context),
              ),
          ],
        ),
      );

  Widget _tile(PurchaseInvoice inv) {
    final statusColor = switch (inv.status) {
      PurchaseInvoiceStatus.draft => Colors.grey,
      PurchaseInvoiceStatus.confirmed => Colors.blue,
      PurchaseInvoiceStatus.cancelled => Colors.red,
    };
    final paymentColor = switch (inv.paymentStatus) {
      PurchasePaymentStatus.unpaid => Colors.orange,
      PurchasePaymentStatus.partial => Colors.amber,
      PurchasePaymentStatus.paid => Colors.green,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: const Icon(Icons.shopping_bag_outlined,
              color: AppColors.primary),
        ),
        title: Row(children: [
          Expanded(
              child: Text(inv.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              switch (inv.status) {
                PurchaseInvoiceStatus.draft => 'مسودة',
                PurchaseInvoiceStatus.confirmed => 'مؤكدة',
                PurchaseInvoiceStatus.cancelled => 'ملغاة',
              },
              style: TextStyle(fontSize: 10, color: statusColor),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: paymentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              switch (inv.paymentStatus) {
                PurchasePaymentStatus.unpaid => 'غير مسدّدة',
                PurchasePaymentStatus.partial => 'جزئي',
                PurchasePaymentStatus.paid => 'مسدّدة',
              },
              style: TextStyle(fontSize: 10, color: paymentColor),
            ),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(inv.supplierName, style: const TextStyle(fontSize: 12)),
            Text('${_fmt(inv.date)} • ${inv.lines.length} بند',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(inv.grandTotal.toStringAsFixed(0),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary)),
            const Text('الإجمالي',
                style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
        onTap: () => _openEdit(context, inv),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openNew(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseInvoiceNewScreen()),
    );
    if (ok == true && context.mounted) setState(() {});
  }

  Future<void> _openEdit(BuildContext context, PurchaseInvoice inv) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PurchaseInvoiceNewScreen(invoice: inv)),
    );
    if (ok == true && context.mounted) setState(() {});
  }
}

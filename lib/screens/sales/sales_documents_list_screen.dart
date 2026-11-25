import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sales_document.dart';
import '../../providers/sales_provider.dart';
import '../../theme/app_theme.dart';
import 'sales_document_form_screen.dart';

class SalesDocumentsListScreen extends StatefulWidget {
  final SalesDocType type;
  const SalesDocumentsListScreen({super.key, required this.type});

  @override
  State<SalesDocumentsListScreen> createState() =>
      _SalesDocumentsListScreenState();
}

class _SalesDocumentsListScreenState extends State<SalesDocumentsListScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        SalesDocType.quotation => 'عروض الأسعار',
        SalesDocType.salesOrder => 'أوامر البيع',
        SalesDocType.salesReturn => 'مرتجع المبيعات',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final all = provider.documentsByType(widget.type);
    final filtered = _query.isEmpty
        ? all
        : all.where((d) {
            final q = _query.toLowerCase();
            return d.docNumber.toLowerCase().contains(q) ||
                d.customerName.toLowerCase().contains(q);
          }).toList();

    final total = filtered.fold<double>(0, (s, d) => s + d.grandTotal);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('$_title جديد'),
        onPressed: () => _openForm(context, null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'بحث...',
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
              _stat('العدد', '${filtered.length}', Colors.blue),
              const SizedBox(width: 8),
              _stat('الإجمالي', total.toStringAsFixed(0), Colors.green),
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

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Text('$label: ',
                style: TextStyle(fontSize: 12, color: color)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
          ]),
        ),
      );

  Widget _empty(bool none) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(widget.type),
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(none ? 'لا توجد مستندات بعد' : 'لا توجد نتائج'),
            const SizedBox(height: 8),
            if (none)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text('إنشاء $_title جديد'),
                onPressed: () => _openForm(context, null),
              ),
          ],
        ),
      );

  IconData _iconFor(SalesDocType t) => switch (t) {
        SalesDocType.quotation => Icons.request_quote_outlined,
        SalesDocType.salesOrder => Icons.shopping_cart_outlined,
        SalesDocType.salesReturn => Icons.assignment_return_outlined,
      };

  Widget _tile(SalesDocument d) {
    final statusColor = switch (d.status) {
      SalesDocStatus.draft => Colors.grey,
      SalesDocStatus.sent => Colors.blue,
      SalesDocStatus.accepted => Colors.green,
      SalesDocStatus.rejected => Colors.red,
      SalesDocStatus.converted => Colors.purple,
      SalesDocStatus.cancelled => Colors.red,
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
          child: Icon(_iconFor(d.type), color: AppColors.primary),
        ),
        title: Row(children: [
          Expanded(
              child: Text(d.docNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_statusLabel(d.status),
                style: TextStyle(fontSize: 10, color: statusColor)),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(d.customerName, style: const TextStyle(fontSize: 12)),
            Text('${_fmt(d.date)} • ${d.lines.length} بند',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(d.grandTotal.toStringAsFixed(0),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary)),
            Text('الإجمالي',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ],
        ),
        onTap: () => _showActions(context, d),
      ),
    );
  }

  String _statusLabel(SalesDocStatus s) => switch (s) {
        SalesDocStatus.draft => 'مسودة',
        SalesDocStatus.sent => 'مُرسل',
        SalesDocStatus.accepted => 'مُعتمد',
        SalesDocStatus.rejected => 'مرفوض',
        SalesDocStatus.converted => 'مُحوّل',
        SalesDocStatus.cancelled => 'ملغى',
      };

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openForm(BuildContext context, SalesDocument? doc) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesDocumentFormScreen(
          type: widget.type,
          document: doc,
        ),
      ),
    );
    if (ok == true && context.mounted) setState(() {});
  }

  Future<void> _showActions(BuildContext context, SalesDocument doc) async {
    final provider = context.read<SalesProvider>();
    final canConvert = doc.type != SalesDocType.salesReturn &&
        doc.convertedToInvoiceId == null &&
        doc.status == SalesDocStatus.accepted;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (canConvert)
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green),
                title: const Text('تحويل إلى فاتورة بيع'),
                onTap: () => Navigator.pop(context, 'convert'),
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        _openForm(context, doc);
        break;
      case 'convert':
        try {
          final invoice = await provider.convertDocumentToInvoice(doc);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('تم إنشاء فاتورة ${invoice.invoiceNumber}'),
                  backgroundColor: Colors.green),
            );
            setState(() {});
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
            );
          }
        }
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('حذف ${doc.docNumber}؟'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حذف')),
            ],
          ),
        );
        if (ok == true) {
          await provider.deleteDocument(doc.id);
          if (context.mounted) setState(() {});
        }
        break;
    }
  }
}

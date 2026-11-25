import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/customer.dart';
import '../../models/sales_invoice.dart';
import '../../providers/sales_provider.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

class SalesInvoiceNewScreen extends StatefulWidget {
  final SalesInvoice? invoice; // للتعديل لاحقاً
  const SalesInvoiceNewScreen({super.key, this.invoice});

  @override
  State<SalesInvoiceNewScreen> createState() => _SalesInvoiceNewScreenState();
}

class _SalesInvoiceNewScreenState extends State<SalesInvoiceNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _invoiceDiscountCtrl = TextEditingController(text: '0');

  Customer? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  final List<_LineDraft> _lines = [];

  bool get isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    if (inv != null) {
      _invoiceDate = inv.date;
      _dueDate = inv.dueDate;
      _notesCtrl.text = inv.notes ?? '';
      _invoiceDiscountCtrl.text = inv.invoiceDiscountPercent.toStringAsFixed(0);
      _lines.addAll(inv.lines.map((l) => _LineDraft.fromLine(l)));
    } else {
      _addLine(); // بند افتراضي
    }
    // اختيار العميل لاحقاً في build (بعد توفر provider)
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _invoiceDiscountCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lines.add(_LineDraft(id: _uuid.v4()));
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    // اختيار العميل الأول إن لم يُحدّد
    if (_selectedCustomer == null && provider.activeCustomers.isNotEmpty) {
      _selectedCustomer = provider.activeCustomers.first;
    }
    if (isEdit && widget.invoice != null && _selectedCustomer == null) {
      _selectedCustomer = provider.customerById(widget.invoice!.customerId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل فاتورة بيع' : 'فاتورة بيع جديدة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _buildHeaderCard(provider),
            const SizedBox(height: 16),
            _buildLinesCard(),
            const SizedBox(height: 16),
            _buildTotalsCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _buildHeaderCard(SalesProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بيانات الفاتورة',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // العميل
            provider.activeCustomers.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'لا يوجد عملاء. أضف عميلاً أولاً من قائمة العملاء.')),
                      ],
                    ),
                  )
                : DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'العميل',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: provider.activeCustomers
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.code})',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCustomer = v),
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _invoiceDate = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الفاتورة',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_fmtDate(_invoiceDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _dueDate = d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ الاستحقاق',
                        prefixIcon: const Icon(Icons.event_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: _dueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                              )
                            : null,
                      ),
                      child: Text(_dueDate == null
                          ? 'غير محدد'
                          : _fmtDate(_dueDate!)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('البنود',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة بند'),
                  onPressed: _addLine,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ..._lines.asMap().entries.map((e) => _buildLineRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineRow(int index, _LineDraft line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: line.nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصنف *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              if (_lines.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _removeLine(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numField(
                  controller: line.qtyCtrl,
                  label: 'الكمية',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  controller: line.priceCtrl,
                  label: 'السعر',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  controller: line.discountCtrl,
                  label: 'خصم %',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  controller: line.taxCtrl,
                  label: 'ضريبة %',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'إجمالي البند: ${line.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'مطلوب';
        if (double.tryParse(v) == null) return 'رقم';
        return null;
      },
    );
  }

  Widget _buildTotalsCard() {
    final subtotal = _lines.fold<double>(0, (s, l) => s + l.grossTotal);
    final lineDiscounts =
        _lines.fold<double>(0, (s, l) => s + l.discountAmount);
    final lineTax = _lines.fold<double>(0, (s, l) => s + l.taxAmount);
    final invDiscPct = double.tryParse(_invoiceDiscountCtrl.text) ?? 0;
    final afterLineDisc = subtotal - lineDiscounts;
    final invDisc = afterLineDisc * (invDiscPct / 100);
    final grand = afterLineDisc - invDisc + lineTax;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _totalRow('المجموع الفرعي', subtotal),
            _totalRow('خصم البنود', -lineDiscounts),
            Row(
              children: [
                const Expanded(child: Text('خصم إضافي على الفاتورة %')),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _invoiceDiscountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (invDisc > 0) _totalRow('قيمة الخصم الإضافي', -invDisc),
            _totalRow('الضريبة', lineTax),
            const Divider(),
            _totalRow('الإجمالي', grand, bold: true, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return TextFormField(
      controller: _notesCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'ملاحظات',
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ كمسودة'),
                onPressed: () => _save(InvoiceStatus.draft),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تأكيد الفاتورة'),
                onPressed: () => _save(InvoiceStatus.confirmed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(InvoiceStatus status) async {
    if (_selectedCustomer == null) {
      _snack('اختر عميلاً أولاً', Colors.orange);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _snack('تحقق من صحة البيانات', Colors.red);
      return;
    }

    final provider = context.read<SalesProvider>();
    final lines = _lines
        .map((l) => l.toInvoiceLine())
        .where((l) => l.quantity > 0 && l.unitPrice >= 0)
        .toList();
    if (lines.isEmpty) {
      _snack('أضف بنداً واحداً على الأقل', Colors.orange);
      return;
    }

    final invoice = SalesInvoice(
      id: widget.invoice?.id ?? _uuid.v4(),
      invoiceNumber:
          widget.invoice?.invoiceNumber ?? provider.generateInvoiceNumber(),
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      date: _invoiceDate,
      dueDate: _dueDate,
      lines: lines,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: status,
      paymentStatus: PaymentStatus.unpaid,
      paidAmount: 0,
      invoiceDiscountPercent:
          double.tryParse(_invoiceDiscountCtrl.text.trim()) ?? 0,
      createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );

    try {
      if (isEdit) {
        await provider.updateInvoice(invoice);
      } else {
        await provider.addInvoice(invoice);
      }
      if (mounted) {
        _snack('تم حفظ الفاتورة ${invoice.invoiceNumber}', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('خطأ: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── مسودة بند (تتعامل مع TextEditingControllers) ─────────────
class _LineDraft {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController taxCtrl;

  _LineDraft({required this.id})
      : nameCtrl = TextEditingController(),
        descCtrl = TextEditingController(),
        qtyCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: '0'),
        discountCtrl = TextEditingController(text: '0'),
        taxCtrl = TextEditingController(text: '0');

  factory _LineDraft.fromLine(InvoiceLine l) {
    return _LineDraft(id: l.id)
      ..nameCtrl.text = l.itemName
      ..descCtrl.text = l.description ?? ''
      ..qtyCtrl.text = l.quantity.toString()
      ..priceCtrl.text = l.unitPrice.toString()
      ..discountCtrl.text = l.discountPercent.toString()
      ..taxCtrl.text = l.taxPercent.toString();
  }

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get discount => double.tryParse(discountCtrl.text) ?? 0;
  double get tax => double.tryParse(taxCtrl.text) ?? 0;

  double get grossTotal => qty * price;
  double get discountAmount => grossTotal * (discount / 100);
  double get netBeforeTax => grossTotal - discountAmount;
  double get taxAmount => netBeforeTax * (tax / 100);
  double get lineTotal => netBeforeTax + taxAmount;

  InvoiceLine toInvoiceLine() => InvoiceLine(
        id: id,
        itemName: nameCtrl.text.trim(),
        description:
            descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        quantity: qty,
        unitPrice: price,
        discountPercent: discount,
        taxPercent: tax,
      );

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    taxCtrl.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/supplier.dart';
import '../../models/purchase_document.dart';
import '../../models/sales_invoice.dart' show InvoiceLine;
import '../../providers/purchases_provider.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

class PurchaseDocumentFormScreen extends StatefulWidget {
  final PurchaseDocType type;
  final PurchaseDocument? document;

  const PurchaseDocumentFormScreen({
    super.key,
    required this.type,
    this.document,
  });

  @override
  State<PurchaseDocumentFormScreen> createState() =>
      _PurchaseDocumentFormScreenState();
}

class _PurchaseDocumentFormScreenState
    extends State<PurchaseDocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');

  Supplier? _selectedSupplier;
  DateTime _date = DateTime.now();
  DateTime? _deliveryDate;
  final List<_LineDraft> _lines = [];

  bool get isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    if (d != null) {
      _date = d.date;
      _deliveryDate = d.deliveryDate;
      _notesCtrl.text = d.notes ?? '';
      _discountCtrl.text = d.discountPercent.toStringAsFixed(0);
      _lines.addAll(d.lines.map((l) => _LineDraft.fromLine(l)));
    } else {
      _addLine();
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  void _addLine() => setState(() => _lines.add(_LineDraft(id: _uuid.v4())));

  void _removeLine(int i) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines[i].dispose();
      _lines.removeAt(i);
    });
  }

  String get _typeLabel => switch (widget.type) {
        PurchaseDocType.purchaseOrder => 'أمر شراء',
        PurchaseDocType.purchaseReturn => 'مرتجع شراء',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchasesProvider>();
    if (_selectedSupplier == null && provider.activeSuppliers.isNotEmpty) {
      _selectedSupplier = provider.activeSuppliers.first;
    }
    if (isEdit && _selectedSupplier == null) {
      _selectedSupplier =
          provider.supplierById(widget.document!.supplierId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل $_typeLabel' : '$_typeLabel جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _header(provider),
            const SizedBox(height: 16),
            _linesCard(),
            const SizedBox(height: 16),
            _totalsCard(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _saveBar(),
    );
  }

  Widget _header(PurchasesProvider provider) {
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
            Text('بيانات $_typeLabel',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            provider.activeSuppliers.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text('أضف مورداً أولاً')),
                    ]),
                  )
                : DropdownButtonFormField<Supplier>(
                    value: _selectedSupplier,
                    decoration: const InputDecoration(
                      labelText: 'المورد',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: provider.activeSuppliers
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (${s.code})',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSupplier = v),
                  ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _dateField('التاريخ', _date,
                    (d) => setState(() => _date = d)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField('تاريخ التسليم', _deliveryDate,
                    (d) => setState(() => _deliveryDate = d),
                    allowClear: true),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime> onChange,
      {bool allowClear = false}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChange(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: allowClear && value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () =>
                      onChange(DateTime.fromMillisecondsSinceEpoch(0)),
                )
              : null,
        ),
        child: Text(value == null || value.year < 2000
            ? 'غير محدد'
            : _fmt(value)),
      ),
    );
  }

  Widget _linesCard() {
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
            Row(children: [
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
            ]),
            ..._lines.asMap().entries.map((e) => _lineRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _lineRow(int index, _LineDraft line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Row(children: [
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
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _num(line.qtyCtrl, 'الكمية')),
          const SizedBox(width: 8),
          Expanded(child: _num(line.priceCtrl, 'السعر')),
          const SizedBox(width: 8),
          Expanded(child: _num(line.discountCtrl, 'خصم %')),
          const SizedBox(width: 8),
          Expanded(child: _num(line.taxCtrl, 'ضريبة %')),
        ]),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('إجمالي البند: ${line.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _num(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'مطلوب';
          if (double.tryParse(v) == null) return 'رقم';
          return null;
        },
      );

  Widget _totalsCard() {
    final subtotal = _lines.fold<double>(0, (s, l) => s + l.grossTotal);
    final lineDisc = _lines.fold<double>(0, (s, l) => s + l.discountAmount);
    final lineTax = _lines.fold<double>(0, (s, l) => s + l.taxAmount);
    final discPct = double.tryParse(_discountCtrl.text) ?? 0;
    final afterDisc = subtotal - lineDisc;
    final disc = afterDisc * (discPct / 100);
    final grand = afterDisc - disc + lineTax;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _row('المجموع الفرعي', subtotal),
          _row('خصم البنود', -lineDisc),
          Row(children: [
            const Expanded(child: Text('خصم إضافي %')),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _discountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          if (disc > 0) _row('قيمة الخصم', -disc),
          _row('الضريبة', lineTax),
          const Divider(),
          _row('الإجمالي', grand, bold: true, color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.normal))),
          Text(value.toStringAsFixed(2),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ]),
      );

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ كمسودة'),
              onPressed: () => _save(PurchaseDocStatus.draft),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(widget.type == PurchaseDocType.purchaseReturn
                  ? 'تأكيد المرتجع'
                  : 'حفظ واعتماد'),
              onPressed: () => _save(PurchaseDocStatus.accepted),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _save(PurchaseDocStatus status) async {
    if (_selectedSupplier == null) {
      _snack('اختر مورداً أولاً', Colors.orange);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _snack('تحقق من البيانات', Colors.red);
      return;
    }
    final lines = _lines.map((l) => l.toInvoiceLine()).toList();
    if (lines.isEmpty) {
      _snack('أضف بنداً واحداً على الأقل', Colors.orange);
      return;
    }
    final provider = context.read<PurchasesProvider>();
    final doc = PurchaseDocument(
      id: widget.document?.id ?? _uuid.v4(),
      type: widget.type,
      docNumber: widget.document?.docNumber ??
          provider.generateDocNumber(widget.type),
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      date: _date,
      deliveryDate: _deliveryDate,
      lines: lines,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: status,
      discountPercent: double.tryParse(_discountCtrl.text) ?? 0,
      originalInvoiceId: widget.document?.originalInvoiceId,
      originalInvoiceNumber: widget.document?.originalInvoiceNumber,
      convertedToInvoiceId: widget.document?.convertedToInvoiceId,
      createdAt: widget.document?.createdAt ?? DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );
    try {
      if (isEdit) {
        await provider.updateDocument(doc);
      } else {
        await provider.addDocument(doc);
      }
      if (mounted) {
        _snack('تم الحفظ', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('خطأ: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color));

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _LineDraft {
  final String id;
  final TextEditingController nameCtrl, descCtrl, qtyCtrl, priceCtrl,
      discountCtrl, taxCtrl;

  _LineDraft({required this.id})
      : nameCtrl = TextEditingController(),
        descCtrl = TextEditingController(),
        qtyCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: '0'),
        discountCtrl = TextEditingController(text: '0'),
        taxCtrl = TextEditingController(text: '0');

  factory _LineDraft.fromLine(InvoiceLine l) => _LineDraft(id: l.id)
    ..nameCtrl.text = l.itemName
    ..descCtrl.text = l.description ?? ''
    ..qtyCtrl.text = l.quantity.toString()
    ..priceCtrl.text = l.unitPrice.toString()
    ..discountCtrl.text = l.discountPercent.toString()
    ..taxCtrl.text = l.taxPercent.toString();

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
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
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

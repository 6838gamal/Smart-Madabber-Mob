import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/supplier.dart';
import '../../providers/purchases_provider.dart';

const _uuid = Uuid();

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;
  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl, _codeCtrl, _phoneCtrl,
      _emailCtrl, _addressCtrl, _taxCtrl, _creditCtrl, _notesCtrl;
  SupplierStatus _status = SupplierStatus.active;

  bool get isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    final provider = context.read<PurchasesProvider>();
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl =
        TextEditingController(text: s?.code ?? provider.generateSupplierCode());
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _taxCtrl = TextEditingController(text: s?.taxNumber ?? '');
    _creditCtrl = TextEditingController(
        text: (s?.creditLimit ?? 0) == 0 ? '' : s!.creditLimit.toStringAsFixed(0));
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _status = s?.status ?? SupplierStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _taxCtrl.dispose();
    _creditCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'تعديل المورد' : 'مورد جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('البيانات الأساسية'),
            _field(_nameCtrl, 'اسم المورد *', Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _field(_codeCtrl, 'الكود *', Icons.tag,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<SupplierStatus>(
                  value: _status,
                  decoration: _dec('الحالة', Icons.flag_outlined),
                  items: const [
                    DropdownMenuItem(
                        value: SupplierStatus.active, child: Text('نشط')),
                    DropdownMenuItem(
                        value: SupplierStatus.inactive,
                        child: Text('غير نشط')),
                    DropdownMenuItem(
                        value: SupplierStatus.blocked,
                        child: Text('محظور')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('معلومات التواصل'),
            _field(_phoneCtrl, 'الهاتف', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'البريد الإلكتروني', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_addressCtrl, 'العنوان', Icons.location_on_outlined,
                maxLines: 2),
            const SizedBox(height: 20),
            _sectionTitle('بيانات مالية'),
            _field(_taxCtrl, 'الرقم الضريبي', Icons.receipt_outlined),
            const SizedBox(height: 12),
            _field(_creditCtrl, 'حد الائتمان (0 = بلا حد)',
                Icons.credit_card_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ]),
            const SizedBox(height: 12),
            _field(_notesCtrl, 'ملاحظات', Icons.notes, maxLines: 3),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة المورد'),
              onPressed: _save,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary));

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: _dec(label, icon),
        ),
      );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final s = Supplier(
      id: widget.supplier?.id ?? _uuid.v4(),
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      taxNumber: _taxCtrl.text.trim().isEmpty ? null : _taxCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      creditLimit: double.tryParse(_creditCtrl.text.trim()) ?? 0,
      balance: widget.supplier?.balance ?? 0,
      status: _status,
      accountId: widget.supplier?.accountId,
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );
    Navigator.pop(context, s);
  }
}

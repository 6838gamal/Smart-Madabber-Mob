import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/customer.dart';
import '../../providers/sales_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _creditLimitCtrl;
  late final TextEditingController _notesCtrl;

  CustomerStatus _status = CustomerStatus.active;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final provider = context.read<SalesProvider>();

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(
        text: c?.code ?? provider.generateCode());
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _taxCtrl = TextEditingController(text: c?.taxNumber ?? '');
    _creditLimitCtrl = TextEditingController(
        text: (c?.creditLimit ?? 0) == 0 ? '' : c!.creditLimit.toStringAsFixed(0));
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _status = c?.status ?? CustomerStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _taxCtrl.dispose();
    _creditLimitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل العميل' : 'عميل جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('البيانات الأساسية'),
            const SizedBox(height: 8),
            _field(
              controller: _nameCtrl,
              label: 'اسم العميل *',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _codeCtrl,
                    label: 'الكود *',
                    icon: Icons.tag_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<CustomerStatus>(
                    value: _status,
                    decoration: _dec('الحالة', Icons.flag_outlined),
                    items: const [
                      DropdownMenuItem(
                          value: CustomerStatus.active,
                          child: Text('نشط')),
                      DropdownMenuItem(
                          value: CustomerStatus.inactive,
                          child: Text('غير نشط')),
                      DropdownMenuItem(
                          value: CustomerStatus.blocked,
                          child: Text('محظور')),
                    ],
                    onChanged: (v) =>
                        setState(() => _status = v ?? _status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('معلومات التواصل'),
            const SizedBox(height: 8),
            _field(
              controller: _phoneCtrl,
              label: 'الهاتف',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _emailCtrl,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _addressCtrl,
              label: 'العنوان',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _sectionTitle('بيانات مالية'),
            const SizedBox(height: 8),
            _field(
              controller: _taxCtrl,
              label: 'الرقم الضريبي',
              icon: Icons.receipt_outlined,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _creditLimitCtrl,
              label: 'حد الائتمان (0 = بلا حد)',
              icon: Icons.credit_card_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              controller: _notesCtrl,
              label: 'ملاحظات',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة العميل'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: _dec(label, icon),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final c = Customer(
      id: widget.customer?.id ?? _uuid.v4(),
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      taxNumber: _taxCtrl.text.trim().isEmpty ? null : _taxCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      creditLimit:
          double.tryParse(_creditLimitCtrl.text.trim()) ?? 0,
      balance: widget.customer?.balance ?? 0,
      status: _status,
      accountId: widget.customer?.accountId,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );

    Navigator.pop(context, c);
  }
}

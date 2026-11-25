import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

/// مزوّد وحدة المبيعات — يدير العملاء حالياً، وسيُوسَّع للفواتير لاحقاً
class SalesProvider extends ChangeNotifier {
  final StorageService _storage;

  SalesProvider(this._storage);

  List<Customer> _customers = [];
  bool _isLoading = true;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;

  List<Customer> get activeCustomers =>
      _customers.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Customer> get sortedCustomers =>
      List<Customer>.from(_customers)..sort((a, b) => a.code.compareTo(b.code));

  Customer? customerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// بحث بالاسم/الكود/الهاتف
  List<Customer> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sortedCustomers;
    return sortedCustomers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false);
    }).toList();
  }

  // ── Init ─────────────────────────────────────────────────
  Future<void> init() async {
    _customers = await _storage.loadCustomers();
    _isLoading = false;
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────
  Future<void> addCustomer(Customer customer) async {
    if (_customers.any((c) => c.code == customer.code)) {
      throw ArgumentError('كود العميل مستخدم مسبقاً: ${customer.code}');
    }
    _customers = [..._customers, customer];
    await _storage.saveCustomers(_customers);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    _customers = _customers
        .map((c) => c.id == customer.id ? customer : c)
        .toList();
    await _storage.saveCustomers(_customers);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    _customers = _customers.where((c) => c.id != id).toList();
    await _storage.saveCustomers(_customers);
    notifyListeners();
  }

  /// توليد كود فريد جديد (C-0001, C-0002, ...)
  String generateCode() {
    if (_customers.isEmpty) return 'C-0001';
    final nums = _customers
        .map((c) {
          final m = RegExp(r'C-(\d+)').firstMatch(c.code);
          return m != null ? int.parse(m.group(1)!) : 0;
        })
        .where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'C-${(max + 1).toString().padLeft(4, '0')}';
  }

  String newCustomerId() => _uuid.v4();
}

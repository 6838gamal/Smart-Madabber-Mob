import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../models/sales_invoice.dart';
import '../models/sales_document.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

/// مزوّد وحدة المبيعات — العملاء + الفواتير + المستندات (عروض/أوامر/مرتجعات)
class SalesProvider extends ChangeNotifier {
  final StorageService _storage;

  SalesProvider(this._storage);

  List<Customer> _customers = [];
  List<SalesInvoice> _invoices = [];
  List<SalesDocument> _documents = [];
  bool _isLoading = true;

  // ── Getters ──────────────────────────────────────────────
  List<Customer> get customers => List.unmodifiable(_customers);
  List<SalesInvoice> get invoices => List.unmodifiable(_invoices);
  List<SalesDocument> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;

  List<Customer> get activeCustomers =>
      _customers.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Customer> get sortedCustomers =>
      List<Customer>.from(_customers)..sort((a, b) => a.code.compareTo(b.code));

  List<SalesInvoice> get sortedInvoices =>
      List<SalesInvoice>.from(_invoices)
        ..sort((a, b) => b.date.compareTo(a.date));

  // ── Lookups ──────────────────────────────────────────────
  Customer? customerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  SalesInvoice? invoiceById(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  SalesDocument? documentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SalesInvoice> invoicesForCustomer(String customerId) =>
      _invoices.where((i) => i.customerId == customerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<SalesDocument> documentsByType(SalesDocType type) =>
      _documents.where((d) => d.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// بحث العملاء بالاسم/الكود/الهاتف
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
    _invoices = await _storage.loadSalesInvoices();
    _documents = await _storage.loadSalesDocuments();
    _isLoading = false;
    notifyListeners();
  }

  // ── Customers CRUD ───────────────────────────────────────
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

  // ── Invoices CRUD ────────────────────────────────────────
  Future<void> addInvoice(SalesInvoice invoice) async {
    _invoices = [invoice, ..._invoices];
    _updateCustomerBalance(invoice.customerId, invoice.grandTotal);
    await Future.wait([
      _storage.saveSalesInvoices(_invoices),
      _storage.saveCustomers(_customers),
    ]);
    notifyListeners();
  }

  Future<void> updateInvoice(SalesInvoice invoice) async {
    final old = invoiceById(invoice.id);
    if (old != null) {
      _updateCustomerBalance(old.customerId, -old.grandTotal);
    }
    _invoices =
        _invoices.map((i) => i.id == invoice.id ? invoice : i).toList();
    _updateCustomerBalance(invoice.customerId, invoice.grandTotal);
    await Future.wait([
      _storage.saveSalesInvoices(_invoices),
      _storage.saveCustomers(_customers),
    ]);
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    final old = invoiceById(id);
    if (old != null) {
      _updateCustomerBalance(old.customerId, -old.grandTotal);
    }
    _invoices = _invoices.where((i) => i.id != id).toList();
    await Future.wait([
      _storage.saveSalesInvoices(_invoices),
      _storage.saveCustomers(_customers),
    ]);
    notifyListeners();
  }

  /// تحديث رصيد العميل (موجب = مدين لنا)
  void _updateCustomerBalance(String customerId, double delta) {
    _customers = _customers.map((c) {
      if (c.id != customerId) return c;
      return c.copyWith(
        balance: c.balance + delta,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  /// توليد رقم فاتورة فريد (INV-0001)
  String generateInvoiceNumber() {
    if (_invoices.isEmpty) return 'INV-0001';
    final nums = _invoices.map((i) {
      final m = RegExp(r'INV-(\d+)').firstMatch(i.invoiceNumber);
      return m != null ? int.parse(m.group(1)!) : 0;
    }).where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'INV-${(max + 1).toString().padLeft(4, '0')}';
  }

  // ── Documents (عروض/أوامر/مرتجعات) ────────────────────────
  Future<void> addDocument(SalesDocument doc) async {
    _documents = [doc, ..._documents];
    // المرتجع المعتمد يخصم من رصيد العميل
    if (doc.type == SalesDocType.salesReturn &&
        doc.status == SalesDocStatus.accepted) {
      _updateCustomerBalance(doc.customerId, -doc.grandTotal);
      await _storage.saveCustomers(_customers);
    }
    await _storage.saveSalesDocuments(_documents);
    notifyListeners();
  }

  Future<void> updateDocument(SalesDocument doc) async {
    final old = documentById(doc.id);
    if (old != null &&
        old.type == SalesDocType.salesReturn &&
        old.status == SalesDocStatus.accepted) {
      // عكس أثر المرتجع القديم
      _updateCustomerBalance(old.customerId, old.grandTotal);
    }
    _documents =
        _documents.map((d) => d.id == doc.id ? doc : d).toList();
    if (doc.type == SalesDocType.salesReturn &&
        doc.status == SalesDocStatus.accepted) {
      _updateCustomerBalance(doc.customerId, -doc.grandTotal);
    }
    await Future.wait([
      _storage.saveSalesDocuments(_documents),
      _storage.saveCustomers(_customers),
    ]);
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    final old = documentById(id);
    if (old != null &&
        old.type == SalesDocType.salesReturn &&
        old.status == SalesDocStatus.accepted) {
      _updateCustomerBalance(old.customerId, old.grandTotal);
    }
    _documents = _documents.where((d) => d.id != id).toList();
    await Future.wait([
      _storage.saveSalesDocuments(_documents),
      _storage.saveCustomers(_customers),
    ]);
    notifyListeners();
  }

  /// توليد رقم مستند فريد (QT-0001 / SO-0001 / SR-0001)
  String generateDocNumber(SalesDocType type) {
    final prefix = SalesDocument.prefixFor(type);
    final sameType = _documents.where((d) => d.type == type);
    if (sameType.isEmpty) return '$prefix-0001';
    final nums = sameType.map((d) {
      final m = RegExp('$prefix-(\\d+)').firstMatch(d.docNumber);
      return m != null ? int.parse(m.group(1)!) : 0;
    }).where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return '$prefix-${(max + 1).toString().padLeft(4, '0')}';
  }

  /// تحويل مستند (عرض/أمر) إلى فاتورة بيع
  Future<SalesInvoice> convertDocumentToInvoice(SalesDocument doc) async {
    if (doc.type == SalesDocType.salesReturn) {
      throw ArgumentError('لا يمكن تحويل مرتجع إلى فاتورة');
    }
    if (doc.convertedToInvoiceId != null) {
      throw ArgumentError('تم تحويل هذا المستند مسبقاً');
    }
    final invoice = SalesInvoice(
      id: newInvoiceId(),
      invoiceNumber: generateInvoiceNumber(),
      customerId: doc.customerId,
      customerName: doc.customerName,
      date: DateTime.now(),
      lines: doc.lines,
      notes: doc.notes,
      status: InvoiceStatus.confirmed,
      paymentStatus: PaymentStatus.unpaid,
      invoiceDiscountPercent: doc.discountPercent,
      createdAt: DateTime.now(),
    );
    await addInvoice(invoice);

    final updated = doc.copyWith(
      status: SalesDocStatus.converted,
      convertedToInvoiceId: invoice.id,
      updatedAt: DateTime.now(),
    );
    await updateDocument(updated);

    return invoice;
  }

  // ── ID generators ────────────────────────────────────────
  String newCustomerId() => _uuid.v4();
  String newInvoiceId() => _uuid.v4();
  String newDocumentId() => _uuid.v4();
}

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/supplier.dart';
import '../models/purchase_invoice.dart';
import '../models/purchase_document.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

/// مزوّد وحدة المشتريات — الموردون + الفواتير + المستندات
class PurchasesProvider extends ChangeNotifier {
  final StorageService _storage;
  PurchasesProvider(this._storage);

  List<Supplier> _suppliers = [];
  List<PurchaseInvoice> _invoices = [];
  List<PurchaseDocument> _documents = [];
  bool _isLoading = true;

  // ── Getters ─────────────────────────────────────────────
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<PurchaseInvoice> get invoices => List.unmodifiable(_invoices);
  List<PurchaseDocument> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;

  List<Supplier> get activeSuppliers =>
      _suppliers.where((s) => s.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Supplier> get sortedSuppliers =>
      List<Supplier>.from(_suppliers)..sort((a, b) => a.code.compareTo(b.code));

  List<PurchaseInvoice> get sortedInvoices =>
      List<PurchaseInvoice>.from(_invoices)
        ..sort((a, b) => b.date.compareTo(a.date));

  // ── Lookups ─────────────────────────────────────────────
  Supplier? supplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  PurchaseInvoice? invoiceById(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  PurchaseDocument? documentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PurchaseInvoice> invoicesForSupplier(String supplierId) =>
      _invoices.where((i) => i.supplierId == supplierId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<PurchaseDocument> documentsByType(PurchaseDocType type) =>
      _documents.where((d) => d.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Supplier> searchSuppliers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sortedSuppliers;
    return sortedSuppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          (s.phone?.contains(q) ?? false);
    }).toList();
  }

  // ── Init ────────────────────────────────────────────────
  Future<void> init() async {
    _suppliers = await _storage.loadSuppliers();
    _invoices = await _storage.loadPurchaseInvoices();
    _documents = await _storage.loadPurchaseDocuments();
    _isLoading = false;
    notifyListeners();
  }

  // ── Suppliers CRUD ──────────────────────────────────────
  Future<void> addSupplier(Supplier s) async {
    if (_suppliers.any((x) => x.code == s.code)) {
      throw ArgumentError('كود المورد مستخدم مسبقاً: ${s.code}');
    }
    _suppliers = [..._suppliers, s];
    await _storage.saveSuppliers(_suppliers);
    notifyListeners();
  }

  Future<void> updateSupplier(Supplier s) async {
    _suppliers = _suppliers.map((x) => x.id == s.id ? s : x).toList();
    await _storage.saveSuppliers(_suppliers);
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    _suppliers = _suppliers.where((s) => s.id != id).toList();
    await _storage.saveSuppliers(_suppliers);
    notifyListeners();
  }

  String generateSupplierCode() {
    if (_suppliers.isEmpty) return 'S-0001';
    final nums = _suppliers.map((s) {
      final m = RegExp(r'S-(\d+)').firstMatch(s.code);
      return m != null ? int.parse(m.group(1)!) : 0;
    }).where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'S-${(max + 1).toString().padLeft(4, '0')}';
  }

  // ── Purchase Invoices CRUD ──────────────────────────────
  Future<void> addInvoice(PurchaseInvoice inv) async {
    _invoices = [inv, ..._invoices];
    _updateSupplierBalance(inv.supplierId, inv.grandTotal); // نزيد مديونيتنا
    await Future.wait([
      _storage.savePurchaseInvoices(_invoices),
      _storage.saveSuppliers(_suppliers),
    ]);
    notifyListeners();
  }

  Future<void> updateInvoice(PurchaseInvoice inv) async {
    final old = invoiceById(inv.id);
    if (old != null) {
      _updateSupplierBalance(old.supplierId, -old.grandTotal);
    }
    _invoices = _invoices.map((i) => i.id == inv.id ? inv : i).toList();
    _updateSupplierBalance(inv.supplierId, inv.grandTotal);
    await Future.wait([
      _storage.savePurchaseInvoices(_invoices),
      _storage.saveSuppliers(_suppliers),
    ]);
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    final old = invoiceById(id);
    if (old != null) {
      _updateSupplierBalance(old.supplierId, -old.grandTotal);
    }
    _invoices = _invoices.where((i) => i.id != id).toList();
    await Future.wait([
      _storage.savePurchaseInvoices(_invoices),
      _storage.saveSuppliers(_suppliers),
    ]);
    notifyListeners();
  }

  void _updateSupplierBalance(String supplierId, double delta) {
    _suppliers = _suppliers.map((s) {
      if (s.id != supplierId) return s;
      return s.copyWith(
        balance: s.balance + delta,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  String generateInvoiceNumber() {
    if (_invoices.isEmpty) return 'PUR-0001';
    final nums = _invoices.map((i) {
      final m = RegExp(r'PUR-(\d+)').firstMatch(i.invoiceNumber);
      return m != null ? int.parse(m.group(1)!) : 0;
    }).where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'PUR-${(max + 1).toString().padLeft(4, '0')}';
  }

  // ── Purchase Documents ──────────────────────────────────
  Future<void> addDocument(PurchaseDocument doc) async {
    _documents = [doc, ..._documents];
    // مرتجع شراء معتمد يخصم من مديونيتنا للمورد
    if (doc.type == PurchaseDocType.purchaseReturn &&
        doc.status == PurchaseDocStatus.accepted) {
      _updateSupplierBalance(doc.supplierId, -doc.grandTotal);
      await _storage.saveSuppliers(_suppliers);
    }
    await _storage.savePurchaseDocuments(_documents);
    notifyListeners();
  }

  Future<void> updateDocument(PurchaseDocument doc) async {
    final old = documentById(doc.id);
    if (old != null &&
        old.type == PurchaseDocType.purchaseReturn &&
        old.status == PurchaseDocStatus.accepted) {
      _updateSupplierBalance(old.supplierId, old.grandTotal);
    }
    _documents = _documents.map((d) => d.id == doc.id ? doc : d).toList();
    if (doc.type == PurchaseDocType.purchaseReturn &&
        doc.status == PurchaseDocStatus.accepted) {
      _updateSupplierBalance(doc.supplierId, -doc.grandTotal);
    }
    await Future.wait([
      _storage.savePurchaseDocuments(_documents),
      _storage.saveSuppliers(_suppliers),
    ]);
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    final old = documentById(id);
    if (old != null &&
        old.type == PurchaseDocType.purchaseReturn &&
        old.status == PurchaseDocStatus.accepted) {
      _updateSupplierBalance(old.supplierId, old.grandTotal);
    }
    _documents = _documents.where((d) => d.id != id).toList();
    await Future.wait([
      _storage.savePurchaseDocuments(_documents),
      _storage.saveSuppliers(_suppliers),
    ]);
    notifyListeners();
  }

  String generateDocNumber(PurchaseDocType type) {
    final prefix = PurchaseDocument.prefixFor(type);
    final sameType = _documents.where((d) => d.type == type);
    if (sameType.isEmpty) return '$prefix-0001';
    final nums = sameType.map((d) {
      final m = RegExp('$prefix-(\\d+)').firstMatch(d.docNumber);
      return m != null ? int.parse(m.group(1)!) : 0;
    }).where((n) => n > 0);
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return '$prefix-${(max + 1).toString().padLeft(4, '0')}';
  }

  Future<PurchaseInvoice> convertDocumentToInvoice(PurchaseDocument doc) async {
    if (doc.type == PurchaseDocType.purchaseReturn) {
      throw ArgumentError('لا يمكن تحويل مرتجع إلى فاتورة');
    }
    if (doc.convertedToInvoiceId != null) {
      throw ArgumentError('تم تحويل هذا المستند مسبقاً');
    }
    final invoice = PurchaseInvoice(
      id: newInvoiceId(),
      invoiceNumber: generateInvoiceNumber(),
      supplierId: doc.supplierId,
      supplierName: doc.supplierName,
      date: DateTime.now(),
      lines: doc.lines,
      notes: doc.notes,
      status: PurchaseInvoiceStatus.confirmed,
      paymentStatus: PurchasePaymentStatus.unpaid,
      invoiceDiscountPercent: doc.discountPercent,
      createdAt: DateTime.now(),
    );
    await addInvoice(invoice);
    await updateDocument(doc.copyWith(
      status: PurchaseDocStatus.converted,
      convertedToInvoiceId: invoice.id,
      updatedAt: DateTime.now(),
    ));
    return invoice;
  }

  // ── ID generators ───────────────────────────────────────
  String newSupplierId() => _uuid.v4();
  String newInvoiceId() => _uuid.v4();
  String newDocumentId() => _uuid.v4();
}

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../models/rule.dart';
import '../models/insight.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../engine/rules_engine.dart';
import '../engine/seed_data.dart';
import '../engine/seed_accounts.dart';

const _uuid = Uuid();

/// ---------------------------------------------------------------
/// الشاشات المتاحة في التطبيق
/// ---------------------------------------------------------------
enum AppScreen {
  // ── أساسية ─────────────────────────────────────────────────
  dashboard,
  resources,
  transactions,
  insights,
  reports,
  settings,
  help,

  // ── المحاسبة ───────────────────────────────────────────────
  chartOfAccounts,
  journalEntryNew,
  journalEntriesList,
  recurringJournals,
  generalLedger,
  trialBalance,
  profitLoss,
  balanceSheet,
  cashFlow,
  costCenters,
  openingBalances,

  // ── المبيعات ───────────────────────────────────────────────
  salesInvoiceNew,
  salesInvoicesList,
  salesReturns,
  quotations,
  salesOrders,
  customersList,
  discounts,

  // ── المشتريات ──────────────────────────────────────────────
  purchaseInvoiceNew,
  purchaseInvoicesList,
  purchaseReturns,
  purchaseOrders,
  suppliersList,

  // ── المخزون ────────────────────────────────────────────────
  itemsList,
  itemGroups,
  units,
  warehousesList,
  stockTransfer,
  stockBalance,
  stockAdjustment,
  stockDamage,

  // ── الخزينة والبنوك ────────────────────────────────────────
  receiptVouchers,
  paymentVouchers,
  paymentMethods,
  cashboxes,
  bankAccounts,
  chequesIn,
  chequesOut,
  chequesDue,
  bankReconciliation,
}

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Resource> _resources = [];
  List<Transaction> _transactions = [];
  List<Rule> _rules = [];
  List<Insight> _insights = [];
  List<Account> _accounts = [];
  List<JournalEntry> _journalEntries = [];

  // ── التنقل ─────────────────────────────────────────────────
  AppScreen _currentScreen = AppScreen.dashboard;
  final List<AppScreen> _navigationStack = [AppScreen.dashboard];
  Map<String, dynamic> _screenArgs = {};

  bool _isDarkMode = false;
  bool _isLoading = true;
  String _currency = 'YER_NEW';
  String _language = 'ar';

  // ── Getters ────────────────────────────────────────────────
  List<Resource> get resources => List.unmodifiable(_resources);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Rule> get rules => List.unmodifiable(_rules);
  List<Insight> get insights => List.unmodifiable(_insights);
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<JournalEntry> get journalEntries => List.unmodifiable(_journalEntries);

  AppScreen get currentScreen => _currentScreen;
  Map<String, dynamic> get screenArgs => Map.unmodifiable(_screenArgs);
  bool get canGoBack => _navigationStack.length > 1;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String get currency => _currency;
  String get language => _language;
  bool get isArabic => _language == 'ar';

  List<Insight> get activeInsights =>
      _insights.where((i) => i.isActive).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

  Insight? get decisionOfTheDay => RulesEngine.decisionOfTheDay(_insights);

  int get criticalCount =>
      _resources.where((r) => r.status == ResourceStatus.critical).length;

  int get lowStockCount =>
      _resources.where((r) => r.status == ResourceStatus.low).length;

  // ── Currency formatting ────────────────────────────────────
  String formatAmount(double amount) {
    final n = amount.toStringAsFixed(0);
    switch (_currency) {
      case 'YER_NEW':
        return '$n ر.ي.ج';
      case 'YER_OLD':
        return '$n ر.ي.ق';
      case 'USD':
        return '\$$n';
      default:
        return '$n $_currency';
    }
  }

  String get currencySymbol {
    switch (_currency) {
      case 'YER_NEW':
        return 'ر.ي.ج';
      case 'YER_OLD':
        return 'ر.ي.ق';
      case 'USD':
        return '\$';
      default:
        return _currency;
    }
  }

  // ── Init ──────────────────────────────────────────────────
  Future<void> init() async {
    await _storage.init();

    if (!_storage.isSeeded) {
      await _seedData();
      await _storage.markSeeded();
    } else {
      _resources = await _storage.loadResources();
      _transactions = await _storage.loadTransactions();
      _rules = await _storage.loadRules();
      _insights = await _storage.loadInsights();
    }

    // ── تحميل الحسابات والقيود (مؤقتاً من seed) ───────────
    if (_accounts.isEmpty) {
      _accounts = seedAccounts;
      _journalEntries = buildSeedJournalEntries();
    }

    final settings = await _storage.loadSettings();
    _isDarkMode = settings['darkMode'] as bool? ?? false;
    _currency = settings['currency'] as String? ?? 'YER_NEW';
    _language = settings['language'] as String? ?? 'ar';

    _runEngine();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _seedData() async {
    _resources = seedResources;
    _transactions = buildSeedTransactions(_resources);
    _rules = seedRules;

    await _storage.saveResources(_resources);
    await _storage.saveTransactions(_transactions);
    await _storage.saveRules(_rules);

    _runEngine();
    await _storage.saveInsights(_insights);
  }

  void _runEngine() {
    _insights = RulesEngine.run(
      resources: _resources,
      transactions: _transactions,
      rules: _rules,
    );
  }

  Future<void> _persist() async {
    await Future.wait([
      _storage.saveResources(_resources),
      _storage.saveTransactions(_transactions),
      _storage.saveInsights(_insights),
    ]);
  }

  Future<void> _saveSettings() async {
    await _storage.saveSettings({
      'darkMode': _isDarkMode,
      'currency': _currency,
      'language': _language,
    });
  }

  // ── Navigation ────────────────────────────────────────────
  void navigateTo(AppScreen screen, {Map<String, dynamic>? args}) {
    if (screen == _currentScreen && args == null) return;
    _navigationStack.add(screen);
    _currentScreen = screen;
    _screenArgs = args ?? {};
    notifyListeners();
  }

  bool goBack() {
    if (_navigationStack.length <= 1) return false;
    _navigationStack.removeLast();
    _currentScreen = _navigationStack.last;
    _screenArgs = {};
    notifyListeners();
    return true;
  }

  void replaceWith(AppScreen screen, {Map<String, dynamic>? args}) {
    if (_navigationStack.isNotEmpty) {
      _navigationStack[_navigationStack.length - 1] = screen;
    } else {
      _navigationStack.add(screen);
    }
    _currentScreen = screen;
    _screenArgs = args ?? {};
    notifyListeners();
  }

  void resetNavigation() {
    _navigationStack
      ..clear()
      ..add(AppScreen.dashboard);
    _currentScreen = AppScreen.dashboard;
    _screenArgs = {};
    notifyListeners();
  }

  // ── Resources ─────────────────────────────────────────────
  Future<void> addResource(Resource resource) async {
    _resources = [..._resources, resource];
    _runEngine();
    await _persist();
    notifyListeners();
  }

  Future<void> updateResource(Resource resource) async {
    _resources =
        _resources.map((r) => r.id == resource.id ? resource : r).toList();
    _runEngine();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteResource(String id) async {
    _resources = _resources.where((r) => r.id != id).toList();
    _transactions = _transactions.where((t) => t.resourceId != id).toList();
    _runEngine();
    await Future.wait([
      _storage.saveResources(_resources),
      _storage.saveTransactions(_transactions),
      _storage.saveInsights(_insights),
    ]);
    notifyListeners();
  }

  // ── Transactions ──────────────────────────────────────────
  Future<void> addTransaction(Transaction txn) async {
    _transactions = [..._transactions, txn];

    final idx = _resources.indexWhere((r) => r.id == txn.resourceId);
    if (idx != -1) {
      final r = _resources[idx];
      final newQty =
          (r.currentQuantity + txn.signedQuantity).clamp(0.0, double.infinity);

      final recentConsume = _transactions
          .where((t) =>
              t.resourceId == txn.resourceId &&
              t.type == TransactionType.consume &&
              DateTime.now().difference(t.date).inDays <= 7)
          .fold(0.0, (s, t) => s + t.quantity);
      final newRate = recentConsume / 7;

      _resources[idx] = r.copyWith(
        currentQuantity: newQty,
        dailyConsumptionRate:
            newRate > 0 ? newRate : r.dailyConsumptionRate,
        lastActivityAt: txn.date,
      );
    }

    _runEngine();
    await Future.wait([
      _storage.saveResources(_resources),
      _storage.saveTransactions(_transactions),
      _storage.saveInsights(_insights),
    ]);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions = _transactions.where((t) => t.id != id).toList();
    _runEngine();
    await Future.wait([
      _storage.saveTransactions(_transactions),
      _storage.saveInsights(_insights),
    ]);
    notifyListeners();
  }

  // ── Rules ─────────────────────────────────────────────────
  Future<void> toggleRule(String id) async {
    _rules = _rules
        .map((r) => r.id == id ? r.copyWith(enabled: !r.enabled) : r)
        .toList();
    _runEngine();
    await Future.wait([
      _storage.saveRules(_rules),
      _storage.saveInsights(_insights),
    ]);
    notifyListeners();
  }

  Future<void> saveRule(Rule rule) async {
    final exists = _rules.any((r) => r.id == rule.id);
    if (exists) {
      _rules = _rules.map((r) => r.id == rule.id ? rule : r).toList();
    } else {
      _rules = [..._rules, rule];
    }
    _runEngine();
    await Future.wait([
      _storage.saveRules(_rules),
      _storage.saveInsights(_insights),
    ]);
    notifyListeners();
  }

  // ── Insights ──────────────────────────────────────────────
  Future<void> dismissInsight(String id) async {
    _insights = _insights
        .map((i) =>
            i.id == id ? i.copyWith(status: InsightStatus.dismissed) : i)
        .toList();
    await _storage.saveInsights(_insights);
    notifyListeners();
  }

  Future<void> resolveInsight(String id) async {
    _insights = _insights
        .map((i) =>
            i.id == id ? i.copyWith(status: InsightStatus.resolved) : i)
        .toList();
    await _storage.saveInsights(_insights);
    notifyListeners();
  }

  Future<void> refreshInsights() async {
    _runEngine();
    await _storage.saveInsights(_insights);
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    _currency = c;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _saveSettings();
    notifyListeners();
  }

  // ── Analytics helpers ─────────────────────────────────────
  List<Transaction> transactionsForResource(String resourceId) =>
      _transactions.where((t) => t.resourceId == resourceId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Transaction> recentTransactions({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _transactions.where((t) => t.date.isAfter(cutoff)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double totalSpent({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _transactions
        .where((t) =>
            t.type == TransactionType.purchase && t.date.isAfter(cutoff))
        .fold(0.0, (s, t) => s + t.price);
  }

  double totalRevenue({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _transactions
        .where(
            (t) => t.type == TransactionType.sale && t.date.isAfter(cutoff))
        .fold(0.0, (s, t) => s + (t.price * t.quantity));
  }

  String newResourceId() => _uuid.v4();
  String newTransactionId() => _uuid.v4();
  String newJournalEntryId() => _uuid.v4();

  // ── Accounts ──────────────────────────────────────────────
  Account? accountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// الحسابات الورقية فقط (ليس لها أبناء) — هي القابلة للترحيل
  List<Account> get leafAccounts {
    final parentIds = _accounts
        .where((a) => a.parentId != null)
        .map((a) => a.parentId!)
        .toSet();
    return _accounts
        .where((a) => !parentIds.contains(a.id))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  List<Account> get sortedLeafAccounts => leafAccounts;

  List<Account> get sortedAccounts =>
      List<Account>.from(_accounts)..sort((a, b) => a.code.compareTo(b.code));

  /// كل الحسابات من نوع معيّن
  List<Account> accountsByType(AccountType type) =>
      _accounts.where((a) => a.type == type).toList()
        ..sort((a, b) => a.code.compareTo(b.code));

  /// الحسابات النقدية (تقريبي: أصول بأسماء/أكواد نقدية)
  List<Account> get cashAccounts {
    return _accounts.where((a) {
      if (a.type != AccountType.asset) return false;
      final name = a.name;
      final code = a.code;
      return name.contains('نقد') ||
          name.contains('صندوق') ||
          name.contains('بنك') ||
          name.contains('خزينة') ||
          code.startsWith('111') ||
          code.startsWith('112');
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  /// هل هذا الحساب نقدي؟
  bool isCashAccount(String accountId) {
    final acc = accountById(accountId);
    if (acc == null) return false;
    if (acc.type != AccountType.asset) return false;
    final name = acc.name;
    final code = acc.code;
    return name.contains('نقد') ||
        name.contains('صندوق') ||
        name.contains('بنك') ||
        name.contains('خزينة') ||
        code.startsWith('111') ||
        code.startsWith('112');
  }

  // ── Journal Entries / Ledger ──────────────────────────────

  /// حركات حساب معيّن ضمن فترة
  List<LedgerMovement> movementsForAccount(
    String accountId, {
    DateTime? from,
    DateTime? to,
  }) {
    final result = <LedgerMovement>[];
    for (final entry in _journalEntries) {
      if (from != null && entry.date.isBefore(from)) continue;
      if (to != null && entry.date.isAfter(to.add(const Duration(days: 1)))) {
        continue;
      }
      for (final line in entry.lines) {
        if (line.accountId != accountId) continue;
        result.add(LedgerMovement(
          entryId: entry.id,
          reference: entry.reference,
          date: entry.date,
          description: line.description ?? entry.description,
          debit: line.debit,
          credit: line.credit,
        ));
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// الرصيد الافتتاحي للحساب (كل ما قبل `from`)
  double openingBalanceFor(String accountId, {DateTime? from}) {
    if (from == null) return 0;
    double total = 0;
    for (final entry in _journalEntries) {
      if (!entry.date.isBefore(from)) continue;
      for (final line in entry.lines) {
        if (line.accountId != accountId) continue;
        total += line.debit - line.credit;
      }
    }
    return total;
  }

  /// رصيد الحساب الحالي (كل القيود حتى الآن)
  double currentBalanceFor(String accountId) {
    double total = 0;
    for (final entry in _journalEntries) {
      for (final line in entry.lines) {
        if (line.accountId != accountId) continue;
        total += line.debit - line.credit;
      }
    }
    return total;
  }

  /// مجموع مدين/دائن لكل حساب ضمن فترة
  /// القيمة المعادة: accountId → (debit, credit)
  Map<String, ({double debit, double credit})> totalsByAccount({
    DateTime? from,
    DateTime? to,
  }) {
    final result = <String, ({double debit, double credit})>{};
    for (final entry in _journalEntries) {
      if (from != null && entry.date.isBefore(from)) continue;
      if (to != null && entry.date.isAfter(to.add(const Duration(days: 1)))) {
        continue;
      }
      for (final line in entry.lines) {
        final cur = result[line.accountId] ?? (debit: 0.0, credit: 0.0);
        result[line.accountId] = (
          debit: cur.debit + line.debit,
          credit: cur.credit + line.credit,
        );
      }
    }
    return result;
  }

  /// القيود ضمن فترة (مفيد للتقارير)
  List<JournalEntry> entriesInRange({DateTime? from, DateTime? to}) {
    return _journalEntries.where((e) {
      if (from != null && e.date.isBefore(from)) return false;
      if (to != null && e.date.isAfter(to.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// إضافة قيد جديد (يتحقق من التوازن)
  Future<void> addJournalEntry(JournalEntry entry) async {
    if (!entry.isBalanced) {
      throw ArgumentError('القيد غير متوازن: مجموع المدين ≠ مجموع الدائن');
    }
    _journalEntries = [entry, ..._journalEntries];
    // await _storage.saveJournalEntries(_journalEntries);
    notifyListeners();
  }

  /// حذف قيد
  Future<void> deleteJournalEntry(String id) async {
    _journalEntries = _journalEntries.where((e) => e.id != id).toList();
    // await _storage.saveJournalEntries(_journalEntries);
    notifyListeners();
  }

  /// إضافة حساب
  Future<void> addAccount(Account account) async {
    _accounts = [..._accounts, account];
    // await _storage.saveAccounts(_accounts);
    notifyListeners();
  }

  /// تحديث حساب
  Future<void> updateAccount(Account account) async {
    _accounts = _accounts.map((a) => a.id == account.id ? account : a).toList();
    // await _storage.saveAccounts(_accounts);
    notifyListeners();
  }

  /// حذف حساب (إن لم يكن له حركات أو أبناء)
  Future<void> deleteAccount(String id) async {
    final hasMovements = _journalEntries.any(
      (e) => e.lines.any((l) => l.accountId == id),
    );
    if (hasMovements) {
      throw ArgumentError('لا يمكن حذف حساب له حركات مرتبطة');
    }
    final hasChildren = _accounts.any((a) => a.parentId == id);
    if (hasChildren) {
      throw ArgumentError('لا يمكن حذف حساب له حسابات فرعية');
    }
    _accounts = _accounts.where((a) => a.id != id).toList();
    // await _storage.saveAccounts(_accounts);
    notifyListeners();
  }

  // ── Opening Balances (الأرصدة الافتتاحية) ─────────────────
  static const String openingBalanceRefPrefix = 'OB-';

  /// هل القيد هو قيد الأرصدة الافتتاحية؟
  bool isOpeningBalanceEntry(JournalEntry e) =>
      e.reference.startsWith(openingBalanceRefPrefix);

  /// جلب قيد الأرصدة الافتتاحية (إن وجد)
  JournalEntry? get openingBalanceEntry {
    try {
      return _journalEntries.firstWhere(
        (e) => isOpeningBalanceEntry(e),
      );
    } catch (_) {
      return null;
    }
  }

  /// استخراج الأرصدة الافتتاحية الحالية كـ map (accountId → signed balance)
  /// الإشارة: موجب = في اتجاه طبيعة الحساب، سالب = عكسها
  Map<String, double> get openingBalancesMap {
    final entry = openingBalanceEntry;
    if (entry == null) return {};
    final result = <String, double>{};
    for (final line in entry.lines) {
      final acc = accountById(line.accountId);
      if (acc == null) continue;
      final isDebitNature = acc.type == AccountType.asset ||
          acc.type == AccountType.expense;
      result[line.accountId] =
          isDebitNature ? (line.debit - line.credit) : (line.credit - line.debit);
    }
    return result;
  }

  /// حفظ الأرصدة الافتتاحية (يحذف القيد القديم ويُنشئ جديداً)
  Future<void> saveOpeningBalances({
    required DateTime date,
    required Map<String, double> balances,
  }) async {
    // حذف القيد القديم
    _journalEntries = _journalEntries
        .where((e) => !isOpeningBalanceEntry(e))
        .toList();

    // بناء سطور القيد
    final lines = <JournalLine>[];
    for (final entry in balances.entries) {
      if (entry.value.abs() < 0.01) continue;
      final acc = accountById(entry.key);
      if (acc == null) continue;
      final isDebitNature = acc.type == AccountType.asset ||
          acc.type == AccountType.expense;
      final v = entry.value;
      final debit = isDebitNature
          ? (v > 0 ? v : 0)
          : (v < 0 ? -v : 0);
      final credit = isDebitNature
          ? (v < 0 ? -v : 0)
          : (v > 0 ? v : 0);
      if (debit < 0.01 && credit < 0.01) continue;
      lines.add(JournalLine(
        accountId: entry.key,
        debit: debit,
        credit: credit,
        description: 'رصيد افتتاحي',
      ));
    }

    if (lines.isEmpty) return;

    // التحقق من التوازن
    final totalDebit = lines.fold<double>(0, (s, l) => s + l.debit);
    final totalCredit = lines.fold<double>(0, (s, l) => s + l.credit);
    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw ArgumentError(
        'الأرصدة غير متوازنة: مدين=$totalDebit دائن=$totalCredit',
      );
    }

    final entry = JournalEntry(
      id: newJournalEntryId(),
      reference: '$openingBalanceRefPrefix${date.year}',
      date: date,
      description: 'الأرصدة الافتتاحية للسنة ${date.year}',
      lines: lines,
    );

    _journalEntries = [entry, ..._journalEntries];
    // await _storage.saveJournalEntries(_journalEntries);
    notifyListeners();
  }
}

// ── LedgerMovement: حركة واحدة في دفتر الأستاذ ──────────────
class LedgerMovement {
  final String entryId;
  final String reference;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;

  const LedgerMovement({
    required this.entryId,
    required this.reference,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
  });

  double get net => debit - credit;
}

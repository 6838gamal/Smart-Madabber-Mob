import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../models/rule.dart';
import '../models/insight.dart';
import '../services/storage_service.dart';
import '../engine/rules_engine.dart';
import '../engine/seed_data.dart';

const _uuid = Uuid();

enum AppScreen {
  dashboard,
  resources,
  transactions,
  insights,
  reports,
  settings,
  help,
}

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Resource> _resources = [];
  List<Transaction> _transactions = [];
  List<Rule> _rules = [];
  List<Insight> _insights = [];

  AppScreen _currentScreen = AppScreen.dashboard;
  bool _isDarkMode = false;
  bool _isLoading = true;
  String _currency = 'YER_NEW';
  String _language = 'ar';

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Resource> get resources => List.unmodifiable(_resources);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Rule> get rules => List.unmodifiable(_rules);
  List<Insight> get insights => List.unmodifiable(_insights);
  AppScreen get currentScreen => _currentScreen;
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

  // ── Currency formatting ───────────────────────────────────────────────────
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

  // ── Init ──────────────────────────────────────────────────────────────────
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

  // ── Navigation ────────────────────────────────────────────────────────────
  void navigateTo(AppScreen screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  // ── Resources ─────────────────────────────────────────────────────────────
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

  // ── Transactions ──────────────────────────────────────────────────────────
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

  // ── Rules ─────────────────────────────────────────────────────────────────
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

  // ── Insights ──────────────────────────────────────────────────────────────
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

  // ── Settings ──────────────────────────────────────────────────────────────
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

  // ── Analytics helpers ─────────────────────────────────────────────────────
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
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../models/rule.dart';
import '../models/insight.dart';

class StorageService {
  static const _resourcesKey = 'sm_resources';
  static const _transactionsKey = 'sm_transactions';
  static const _rulesKey = 'sm_rules';
  static const _insightsKey = 'sm_insights';
  static const _settingsKey = 'sm_settings';
  static const _seededKey = 'sm_seeded';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw StateError('StorageService not initialized');
    return _prefs!;
  }

  // ─── Resources ────────────────────────────────────────────────────────────

  Future<List<Resource>> loadResources() async {
    final json = prefs.getString(_resourcesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Resource.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveResources(List<Resource> resources) async {
    await prefs.setString(_resourcesKey, jsonEncode(resources.map((r) => r.toJson()).toList()));
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  Future<List<Transaction>> loadTransactions() async {
    final json = prefs.getString(_transactionsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await prefs.setString(_transactionsKey, jsonEncode(transactions.map((t) => t.toJson()).toList()));
  }

  // ─── Rules ────────────────────────────────────────────────────────────────

  Future<List<Rule>> loadRules() async {
    final json = prefs.getString(_rulesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveRules(List<Rule> rules) async {
    await prefs.setString(_rulesKey, jsonEncode(rules.map((r) => r.toJson()).toList()));
  }

  // ─── Insights ─────────────────────────────────────────────────────────────

  Future<List<Insight>> loadInsights() async {
    final json = prefs.getString(_insightsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Insight.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveInsights(List<Insight> insights) async {
    await prefs.setString(_insightsKey, jsonEncode(insights.map((i) => i.toJson()).toList()));
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadSettings() async {
    final json = prefs.getString(_settingsKey);
    if (json == null) return {};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  // ─── Seed check ───────────────────────────────────────────────────────────

  bool get isSeeded => prefs.getBool(_seededKey) ?? false;
  Future<void> markSeeded() => prefs.setBool(_seededKey, true);
}

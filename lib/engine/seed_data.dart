import 'package:uuid/uuid.dart';
import '../models/resource.dart';
import '../models/transaction.dart';
import '../models/rule.dart';

const _uuid = Uuid();

List<Resource> get seedResources {
  final now = DateTime.now();
  return [
    Resource(
      id: _uuid.v4(),
      name: 'Rice',
      type: ResourceType.ingredient,
      currentQuantity: 4.5,
      minThreshold: 2.0,
      unit: 'kg',
      dailyConsumptionRate: 0.4,
      createdAt: now.subtract(const Duration(days: 60)),
      lastActivityAt: now.subtract(const Duration(days: 1)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Cooking Oil',
      type: ResourceType.ingredient,
      currentQuantity: 0.8,
      minThreshold: 2.0,
      unit: 'L',
      dailyConsumptionRate: 0.1,
      createdAt: now.subtract(const Duration(days: 45)),
      lastActivityAt: now.subtract(const Duration(days: 2)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Sugar',
      type: ResourceType.ingredient,
      currentQuantity: 3.2,
      minThreshold: 1.0,
      unit: 'kg',
      dailyConsumptionRate: 0.15,
      createdAt: now.subtract(const Duration(days: 45)),
      lastActivityAt: now.subtract(const Duration(days: 3)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Water Gallons',
      type: ResourceType.consumable,
      currentQuantity: 8.0,
      minThreshold: 3.0,
      unit: 'gal',
      dailyConsumptionRate: 1.0,
      createdAt: now.subtract(const Duration(days: 30)),
      lastActivityAt: now.subtract(const Duration(days: 1)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Product A (Units)',
      type: ResourceType.product,
      currentQuantity: 45.0,
      minThreshold: 10.0,
      unit: 'units',
      dailyConsumptionRate: 3.0,
      createdAt: now.subtract(const Duration(days: 90)),
      lastActivityAt: now.subtract(const Duration(days: 1)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Raw Material B',
      type: ResourceType.rawMaterial,
      currentQuantity: 6.0,
      minThreshold: 10.0,
      unit: 'kg',
      dailyConsumptionRate: 1.2,
      createdAt: now.subtract(const Duration(days: 60)),
      lastActivityAt: now.subtract(const Duration(days: 1)),
    ),
    Resource(
      id: _uuid.v4(),
      name: 'Cleaning Supplies',
      type: ResourceType.consumable,
      currentQuantity: 5.0,
      minThreshold: 2.0,
      unit: 'units',
      dailyConsumptionRate: 0.0,
      createdAt: now.subtract(const Duration(days: 120)),
      lastActivityAt: now.subtract(const Duration(days: 30)),
    ),
  ];
}

List<Transaction> buildSeedTransactions(List<Resource> resources) {
  final txns = <Transaction>[];
  final now = DateTime.now();

  Resource? res(String name) {
    try {
      return resources.firstWhere((r) => r.name == name);
    } catch (_) {
      return null;
    }
  }

  void addTxn(Resource? r, TransactionType type, double qty, int daysAgo,
      {double price = 0, String note = ''}) {
    if (r == null) return;
    txns.add(Transaction(
      id: _uuid.v4(),
      resourceId: r.id,
      type: type,
      quantity: qty,
      price: price,
      date: now.subtract(Duration(days: daysAgo)),
      note: note,
    ));
  }

  final rice = res('Rice');
  final oil = res('Cooking Oil');
  final sugar = res('Sugar');
  final water = res('Water Gallons');
  final prodA = res('Product A (Units)');
  final rawB = res('Raw Material B');

  addTxn(rice, TransactionType.purchase, 5.0, 14, price: 12.5, note: 'Monthly restock');
  addTxn(rice, TransactionType.consume, 0.5, 12);
  addTxn(rice, TransactionType.consume, 0.4, 10);
  addTxn(rice, TransactionType.consume, 0.5, 8);
  addTxn(rice, TransactionType.consume, 0.6, 6);
  addTxn(rice, TransactionType.consume, 0.5, 4);
  addTxn(rice, TransactionType.consume, 0.4, 2);
  addTxn(rice, TransactionType.consume, 0.5, 1);

  addTxn(oil, TransactionType.purchase, 2.0, 20, price: 8.0);
  addTxn(oil, TransactionType.consume, 0.15, 15);
  addTxn(oil, TransactionType.consume, 0.2, 10);
  addTxn(oil, TransactionType.consume, 0.25, 7);
  addTxn(oil, TransactionType.consume, 0.2, 4);
  addTxn(oil, TransactionType.consume, 0.35, 2);
  addTxn(oil, TransactionType.consume, 0.05, 0);

  addTxn(sugar, TransactionType.purchase, 4.0, 25, price: 5.5);
  addTxn(sugar, TransactionType.consume, 0.2, 20);
  addTxn(sugar, TransactionType.consume, 0.15, 15);
  addTxn(sugar, TransactionType.consume, 0.15, 10);
  addTxn(sugar, TransactionType.consume, 0.1, 5);
  addTxn(sugar, TransactionType.consume, 0.15, 2);

  addTxn(water, TransactionType.purchase, 12.0, 10, price: 18.0);
  addTxn(water, TransactionType.consume, 1.0, 9);
  addTxn(water, TransactionType.consume, 1.0, 7);
  addTxn(water, TransactionType.consume, 1.0, 5);
  addTxn(water, TransactionType.consume, 1.0, 3);
  addTxn(water, TransactionType.consume, 1.0, 1);

  addTxn(prodA, TransactionType.purchase, 50.0, 15, price: 250.0, note: 'Batch order');
  addTxn(prodA, TransactionType.sale, 2.0, 12, price: 30.0);
  addTxn(prodA, TransactionType.sale, 3.0, 10, price: 45.0);
  addTxn(prodA, TransactionType.sale, 3.0, 7, price: 45.0);
  addTxn(prodA, TransactionType.sale, 2.0, 4, price: 30.0);

  addTxn(rawB, TransactionType.purchase, 10.0, 18, price: 80.0);
  addTxn(rawB, TransactionType.consume, 1.5, 14);
  addTxn(rawB, TransactionType.consume, 1.2, 9);
  addTxn(rawB, TransactionType.consume, 1.3, 4);

  return txns;
}

List<Rule> get seedRules => [
      Rule(
        id: _uuid.v4(),
        name: 'Low Stock Warning',
        conditionType: RuleConditionType.lowStock,
        conditionValue: 1.0,
        action: 'Generate restock alert',
        severity: RuleSeverity.medium,
        enabled: true,
      ),
      Rule(
        id: _uuid.v4(),
        name: 'Critical Level Alert',
        conditionType: RuleConditionType.criticalLevel,
        conditionValue: 0.5,
        action: 'Generate critical alert',
        severity: RuleSeverity.critical,
        enabled: true,
      ),
      Rule(
        id: _uuid.v4(),
        name: 'High Consumption Detection',
        conditionType: RuleConditionType.highConsumption,
        conditionValue: 1.5,
        action: 'Flag for review',
        severity: RuleSeverity.high,
        enabled: true,
      ),
      Rule(
        id: _uuid.v4(),
        name: 'Inactive Resource Check',
        conditionType: RuleConditionType.inactiveResource,
        conditionValue: 21,
        action: 'Review resource usage',
        severity: RuleSeverity.low,
        enabled: true,
      ),
      Rule(
        id: _uuid.v4(),
        name: 'Waste Detection',
        conditionType: RuleConditionType.wasteDetection,
        conditionValue: 0.8,
        action: 'Audit consumption patterns',
        severity: RuleSeverity.medium,
        enabled: true,
      ),
    ];

import '../models/account.dart';
import '../models/journal_entry.dart';

/// دليل حسابات مبسط (شجرة)
final List<Account> seedAccounts = [
  // ── أصول ─────────────────────────────────────────────
  const Account(id: 'a_1000', code: '1000', name: 'الأصول',        type: AccountType.asset),
  const Account(id: 'a_1100', code: '1100', name: 'الأصول المتداولة', type: AccountType.asset, parentId: 'a_1000'),
  const Account(id: 'a_1101', code: '1101', name: 'النقدية بالصندوق', type: AccountType.asset, parentId: 'a_1100'),
  const Account(id: 'a_1102', code: '1102', name: 'النقدية بالبنك',   type: AccountType.asset, parentId: 'a_1100'),
  const Account(id: 'a_1103', code: '1103', name: 'العملاء (مدينون)', type: AccountType.asset, parentId: 'a_1100'),
  const Account(id: 'a_1104', code: '1104', name: 'المخزون',          type: AccountType.asset, parentId: 'a_1100'),

  // ── خصوم ─────────────────────────────────────────────
  const Account(id: 'a_2000', code: '2000', name: 'الخصوم',           type: AccountType.liability),
  const Account(id: 'a_2100', code: '2100', name: 'الخصوم المتداولة', type: AccountType.liability, parentId: 'a_2000'),
  const Account(id: 'a_2101', code: '2101', name: 'الموردون (دائنون)', type: AccountType.liability, parentId: 'a_2100'),
  const Account(id: 'a_2102', code: '2102', name: 'ضريبة القيمة المضافة', type: AccountType.liability, parentId: 'a_2100'),

  // ── حقوق ملكية ───────────────────────────────────────
  const Account(id: 'a_3000', code: '3000', name: 'حقوق الملكية', type: AccountType.equity),
  const Account(id: 'a_3100', code: '3100', name: 'رأس المال',     type: AccountType.equity, parentId: 'a_3000'),
  const Account(id: 'a_3200', code: '3200', name: 'الأرباح المحتجزة', type: AccountType.equity, parentId: 'a_3000'),

  // ── إيرادات ──────────────────────────────────────────
  const Account(id: 'a_4000', code: '4000', name: 'الإيرادات',       type: AccountType.revenue),
  const Account(id: 'a_4100', code: '4100', name: 'إيرادات المبيعات', type: AccountType.revenue, parentId: 'a_4000'),
  const Account(id: 'a_4200', code: '4200', name: 'إيرادات أخرى',     type: AccountType.revenue, parentId: 'a_4000'),

  // ── مصروفات ──────────────────────────────────────────
  const Account(id: 'a_5000', code: '5000', name: 'المصروفات',         type: AccountType.expense),
  const Account(id: 'a_5100', code: '5100', name: 'تكلفة المبيعات',    type: AccountType.expense, parentId: 'a_5000'),
  const Account(id: 'a_5200', code: '5200', name: 'مصروفات إدارية',    type: AccountType.expense, parentId: 'a_5000'),
  const Account(id: 'a_5300', code: '5300', name: 'مصروفات بيعية',     type: AccountType.expense, parentId: 'a_5000'),
];

/// قيود تجريبية موزعة على الأشهر الثلاثة الماضية
List<JournalEntry> buildSeedJournalEntries() {
  final now = DateTime.now();
  final entries = <JournalEntry>[];

  void add({
    required String ref,
    required DateTime date,
    required String desc,
    required List<JournalLine> lines,
  }) {
    entries.add(JournalEntry(
      id: ref,
      reference: ref,
      date: date,
      description: desc,
      lines: lines,
    ));
  }

  // JE-001: رأس مال افتتاحي
  add(
    ref: 'JE-001',
    date: DateTime(now.year, now.month - 2, 1),
    desc: 'إيداع رأس المال',
    lines: const [
      JournalLine(accountId: 'a_1102', debit: 500000, description: 'بنك'),
      JournalLine(accountId: 'a_3100', credit: 500000, description: 'رأس المال'),
    ],
  );

  // JE-002: شراء مخزون نقداً
  add(
    ref: 'JE-002',
    date: DateTime(now.year, now.month - 2, 5),
    desc: 'شراء مخزون نقداً',
    lines: const [
      JournalLine(accountId: 'a_1104', debit: 80000, description: 'مخزون'),
      JournalLine(accountId: 'a_1101', credit: 80000, description: 'صندوق'),
    ],
  );

  // JE-003: بيع آجل
  add(
    ref: 'JE-003',
    date: DateTime(now.year, now.month - 1, 10),
    desc: 'بيع بضاعة بالأجل',
    lines: const [
      JournalLine(accountId: 'a_1103', debit: 120000, description: 'عملاء'),
      JournalLine(accountId: 'a_4100', credit: 120000, description: 'مبيعات'),
    ],
  );

  // JE-004: تكلفة مبيعات
  add(
    ref: 'JE-004',
    date: DateTime(now.year, now.month - 1, 10),
    desc: 'تكلفة البضاعة المباعة',
    lines: const [
      JournalLine(accountId: 'a_5100', debit: 70000, description: 'تكلفة'),
      JournalLine(accountId: 'a_1104', credit: 70000, description: 'مخزون'),
    ],
  );

  // JE-005: مصروف إيجار
  add(
    ref: 'JE-005',
    date: DateTime(now.year, now.month - 1, 15),
    desc: 'سداد إيجار شهري',
    lines: const [
      JournalLine(accountId: 'a_5200', debit: 15000, description: 'إيجار'),
      JournalLine(accountId: 'a_1102', credit: 15000, description: 'بنك'),
    ],
  );

  // JE-006: تحصيل من عميل
  add(
    ref: 'JE-006',
    date: DateTime(now.year, now.month, 3),
    desc: 'تحصيل نقدي من عميل',
    lines: const [
      JournalLine(accountId: 'a_1101', debit: 40000, description: 'صندوق'),
      JournalLine(accountId: 'a_1103', credit: 40000, description: 'عملاء'),
    ],
  );

  // JE-007: شراء بالأجل
  add(
    ref: 'JE-007',
    date: DateTime(now.year, now.month, 5),
    desc: 'شراء مخزون بالأجل',
    lines: const [
      JournalLine(accountId: 'a_1104', debit: 60000, description: 'مخزون'),
      JournalLine(accountId: 'a_2101', credit: 60000, description: 'موردون'),
    ],
  );

  // JE-008: سداد مورد
  add(
    ref: 'JE-008',
    date: DateTime(now.year, now.month, 8),
    desc: 'سداد دفعة لمورد',
    lines: const [
      JournalLine(accountId: 'a_2101', debit: 25000, description: 'موردون'),
      JournalLine(accountId: 'a_1102', credit: 25000, description: 'بنك'),
    ],
  );

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

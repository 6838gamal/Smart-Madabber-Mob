import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class L10n {
  final bool isAr;
  const L10n(this.isAr);

  static L10n of(BuildContext context) {
    final lang = context.watch<AppProvider>().language;
    return L10n(lang == 'ar');
  }

  static L10n read(BuildContext context) {
    final lang = context.read<AppProvider>().language;
    return L10n(lang == 'ar');
  }

  // ── App ──────────────────────────────────────────────────────────────────
  String get appName => isAr ? 'المدبّر الذكي' : 'Smart Advisor';
  String get appSubtitle => isAr ? 'Smart Advisor' : 'المدبّر الذكي';

  // ── Sidebar / Navigation ─────────────────────────────────────────────────
  String get dashboard => isAr ? 'لوحة التحكم' : 'Dashboard';
  String get resources => isAr ? 'المخزون' : 'Inventory';
  String get transactions => isAr ? 'الحركات المالية والمخزنية' : 'Financial & Inventory Transactions';
  String get insights => isAr ? 'القرارات الذكية' : 'Smart Decisions';
  String get reports => isAr ? 'التقارير' : 'Reports';
  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get help => isAr ? 'تواصل معنا' : 'Contact Us';

  // ── Theme footer ─────────────────────────────────────────────────────────
  String get lightMode => isAr ? 'فاتح' : 'Light';
  String get darkMode => isAr ? 'داكن' : 'Dark';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get intelligentOverview => isAr ? 'نظرتك التشغيلية الذكية الشاملة' : 'Your intelligent operational overview';
  String get today => isAr ? 'اليوم' : 'Today';
  String get trends => isAr ? 'الاتجاهات' : 'Trends';
  String get stock => isAr ? 'المخزون' : 'Inventory';
  String get intelligence => isAr ? 'القرارات' : 'Decisions';
  String get refreshInsights => isAr ? 'تحديث القرارات الذكية' : 'Refresh Smart Decisions';
  String get quickStats => isAr ? 'إحصائيات سريعة' : 'Quick Stats';
  String get totalResources => isAr ? 'إجمالي أصناف المخزون' : 'Inventory Items';
  String get activeAlerts => isAr ? 'تنبيهات نشطة' : 'Active Alerts';
  String get needAttention => isAr ? 'تحتاج انتباهاً' : 'Need attention';
  String get critical => isAr ? 'حرج' : 'Critical';
  String get immediateAction => isAr ? 'إجراء فوري' : 'Immediate action';
  String get lowStock => isAr ? 'مخزون منخفض' : 'Low Stock';
  String get restockSoon => isAr ? 'أعد التخزين قريباً' : 'Restock soon';
  String get seeAll => isAr ? 'عرض الكل' : 'See all';
  String get recentActivity => isAr ? 'آخر الحركات' : 'Recent Movements';
  String get noRecentTransactions => isAr ? 'لا توجد حركات مالية حديثة' : 'No recent movements';
  String get addTransactionsForTrends => isAr
      ? 'أضف حركات مالية ومخزنية لرؤية الاتجاهات الأسبوعية.'
      : 'Add financial or inventory movements to see weekly trends.';
  String get units => isAr ? 'وحدات' : 'units';
  String get activeRulesLabel => isAr ? 'قواعد القرارات النشطة' : 'Active Decision Rules';
  String get engineSummary => isAr ? 'ملخص محرك القرارات' : 'Decision Engine Summary';
  String get insightsGenerated => isAr ? 'القرارات الذكية المولّدة' : 'Smart Decisions Generated';
  String get active => isAr ? 'نشط' : 'Active';
  String get rulesActive => isAr ? 'قواعد نشطة' : 'Rules Active';
  String get totalRulesLabel => isAr ? 'إجمالي القواعد' : 'Total Rules';
  String get engineDescription => isAr
      ? 'يراقب محرك القرارات مخزونك وحركاتك المالية باستمرار ويولّد توصيات تشغيلية تلقائياً.'
      : 'The decision engine continuously monitors your inventory and financial movements, generating actionable business insights automatically.';
  String get criticalSection => isAr ? '🚨 مخزون حرج' : '🚨 Critical Stock';
  String get lowStockSection => isAr ? '⚠️ تنبيه مخزون منخفض' : '⚠️ Low Stock Alert';
  String get inactiveSection => isAr ? '😴 غير نشط' : '😴 Inactive';
  String get normalSection => isAr ? '✅ متوفر' : '✅ In Stock';
  String get noResourcesYet => isAr ? 'لا توجد أصناف في المخزون بعد' : 'No inventory items yet';
  String get addResourcesToTrack => isAr ? 'أضف أصنافاً لتتبع مستوياتها.' : 'Add inventory items to track their stock levels.';

  // ── Spent / Revenue ──────────────────────────────────────────────────────
  String get spent30d => isAr ? 'المصروفات (30 يوم)' : 'Expenses (30d)';
  String get revenue30d => isAr ? 'الإيرادات (30 يوم)' : 'Revenue (30d)';
  String get txns7d => isAr ? 'الحركات (7 أيام)' : 'Movements (7d)';
  String get txns30d => isAr ? 'الحركات (30 يوم)' : 'Movements (30d)';

  // ── Decision Card ─────────────────────────────────────────────────────────
  String get decisionOfTheDay => isAr ? 'قرار اليوم' : 'Decision of the Day';
  String get allSystemsNormal => isAr ? '✅ المخزون بحالة جيدة' : '✅ Inventory in good standing';
  String get noIssuesDetected => isAr
      ? 'لا توجد تنبيهات مخزنية أو مالية حرجة. استمر في مراقبة الحركات.'
      : 'No critical inventory or financial alerts. Keep monitoring your stock movements.';
  String get markResolved => isAr ? 'تحديد كمحلول' : 'Mark Resolved';

  // ── Insight Card ──────────────────────────────────────────────────────────
  String get dismiss => isAr ? 'تجاهل' : 'Dismiss';
  String get resolve => isAr ? 'حل' : 'Resolve';

  // ── Resource Card ─────────────────────────────────────────────────────────
  String get daysRemaining => isAr ? 'أيام متبقية' : 'days remaining';
  String get consumptionRateNotSet => isAr ? 'معدل الاستهلاك غير محدد' : 'Consumption rate not set';
  String get minPrefix => isAr ? 'الحد الأدنى: ' : 'min stock: ';

  // ── Inventory Screen ──────────────────────────────────────────────────────
  String get searchResources => isAr ? 'ابحث عن صنف...' : 'Search inventory items...';
  String get addResource => isAr ? 'إضافة صنف' : 'Add Item';
  String get all => isAr ? 'الكل' : 'All';
  String get low => isAr ? 'منخفض' : 'Low Stock';
  String get normal => isAr ? 'متوفر' : 'In Stock';
  String get inactive => isAr ? 'غير نشط' : 'Inactive';
  String get noResourcesFound => isAr ? 'لم يتم العثور على أصناف' : 'No inventory items found';
  String get tryDifferentSearch => isAr ? 'جرب مصطلح بحث مختلف.' : 'Try a different search term.';
  String get startByAdding => isAr ? 'ابدأ بإضافة أول صنف في المخزون.' : 'Start by adding your first inventory item.';
  String get addTransaction => isAr ? 'إضافة حركة' : 'Add Movement';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get delete => isAr ? 'حذف' : 'Delete';
  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get resourceNameLabel => isAr ? 'اسم الصنف' : 'Item Name';
  String get unitLabel => isAr ? 'وحدة القياس (كجم، لتر...)' : 'Unit (kg, L, pcs...)';
  String get currentQuantityLabel => isAr ? 'الكمية الحالية' : 'Stock Quantity';
  String get minThresholdLabel => isAr ? 'الحد الأدنى للمخزون' : 'Minimum Stock';
  String get dailyRateLabel => isAr ? 'معدل الاستهلاك اليومي' : 'Daily Consumption Rate';
  String get resourceTypeLabel => isAr ? 'تصنيف الصنف' : 'Item Category';
  String get editResource => isAr ? 'تعديل الصنف' : 'Edit Item';
  String get newResource => isAr ? 'صنف جديد' : 'New Inventory Item';
  String get confirmDelete => isAr ? 'تأكيد الحذف' : 'Confirm Delete';
  String get deleteConfirmMsg => isAr
      ? 'هل أنت متأكد من حذف هذا الصنف؟ سيتم حذف جميع حركاته المالية والمخزنية أيضاً.'
      : 'Are you sure you want to delete this item? All its stock movements will also be deleted.';
  String get quantityLabel => isAr ? 'الكمية' : 'Quantity';
  String get priceLabel => isAr ? 'السعر / التكلفة' : 'Price / Cost';
  String get notesLabel => isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)';
  String get typeLabel => isAr ? 'التصنيف' : 'Category';

  // ── Transactions Screen ───────────────────────────────────────────────────
  String get noTransactions => isAr ? 'لا توجد حركات مالية أو مخزنية' : 'No movements recorded';
  String get logFirstTransaction => isAr ? 'سجّل أول حركة مالية أو مخزنية.' : 'Log your first stock movement or financial entry.';
  String get allTypes => isAr ? 'جميع الأنواع' : 'All Types';
  String get last7Days => isAr ? 'آخر 7 أيام' : 'Last 7 days';
  String get last30Days => isAr ? 'آخر 30 يوم' : 'Last 30 days';
  String get last90Days => isAr ? 'آخر 90 يوم' : 'Last 90 days';

  // ── Smart Decisions Screen ────────────────────────────────────────────────
  String get resolved => isAr ? 'محلولة' : 'Resolved';
  String get dismissed => isAr ? 'مؤجلة' : 'Dismissed';
  String get noActiveInsights => isAr ? 'لا توجد قرارات ذكية نشطة' : 'No active smart decisions';
  String get noResolvedInsights => isAr ? 'لا توجد قرارات محلولة' : 'No resolved decisions';
  String get noDismissedInsights => isAr ? 'لا توجد قرارات مؤجلة' : 'No dismissed decisions';
  String get rulesWillGenerate => isAr
      ? 'سيولّد محرك القرارات توصيات تشغيلية تلقائياً عند رصد أي مشكلة.'
      : 'The decision engine will automatically generate business insights when issues are detected.';
  String get refresh => isAr ? 'تحديث' : 'Refresh';

  // ── Reports Screen ────────────────────────────────────────────────────────
  String get dataAtAGlance => isAr ? 'تقاريرك المالية والمخزنية' : 'Financial & Inventory Reports';
  String get resourceHealth => isAr ? 'حالة المخزون' : 'Inventory Status';
  String get transactionSummary => isAr ? 'ملخص الحركات' : 'Movement Summary';
  String get topResourcesByConsumption => isAr ? 'أعلى الأصناف استهلاكاً' : 'Top Items by Consumption';
  String get financialOverview => isAr ? 'النظرة المالية' : 'Financial Overview';
  String get noDataForChart => isAr ? 'لا توجد بيانات بعد' : 'No data yet';
  String get resource => isAr ? 'الصنف' : 'Item';
  String get dailyRate => isAr ? 'معدل الاستهلاك' : 'Consumption Rate';
  String get status => isAr ? 'الحالة' : 'Status';
  String get totalSpentLabel => isAr ? 'إجمالي المصروفات' : 'Total Expenses';
  String get totalRevenueLabel => isAr ? 'إجمالي الإيرادات' : 'Total Revenue';
  String get netLabel => isAr ? 'تقدير الربح' : 'Profit Estimation';
  String get transactionsCountLabel => isAr ? 'عدد الحركات' : 'Total Movements';

  // ── Settings Screen ───────────────────────────────────────────────────────
  String get customizeExperience => isAr
      ? 'خصص إعدادات المدبّر الذكي'
      : 'Customize your Smart Advisor settings';
  String get appearance => isAr ? 'المظهر' : 'Appearance';
  String get darkModeLabel => isAr ? 'الوضع الداكن' : 'Dark Mode';
  String get switchTheme => isAr ? 'التبديل بين الوضعين الفاتح والداكن' : 'Switch between light and dark theme';
  String get languageLabel => isAr ? 'اللغة' : 'Language';
  String get currencyLabel => isAr ? 'العملة' : 'Currency';
  String get displayCurrencyLabel => isAr ? 'عملة العرض' : 'Display Currency';
  String get rulesEngineLabel => isAr ? 'محرك القرارات الذكية' : 'Smart Decision Rules';
  String get aboutLabel => isAr ? 'حول التطبيق' : 'About';
  String get versionInfo => isAr ? 'الإصدار 1.0.0 · مساعد تشغيلي ذكي' : 'Version 1.0.0 · Smart operational assistant';
  String get dataStorageLabel => isAr ? 'تخزين البيانات' : 'Data Storage';
  String get dataStoredLocally => isAr ? 'جميع البيانات مخزنة محلياً على جهازك' : 'All data stored locally on your device';
  String get systemLabel => isAr ? 'النظام' : 'System';
  String get arabicLanguage => 'العربية';
  String get englishLanguage => 'English';

  // ── Contact Us Screen ─────────────────────────────────────────────────────
  String get helpContactTitle => isAr ? 'تواصل معنا' : 'Contact Us';
  String get hereToHelp => isAr ? 'نحن هنا للمساعدة' : 'We\'re here to help';
  String get helpSubtitle => isAr
      ? 'اكتب رسالتك وتواصل معنا عبر قناتك المفضلة'
      : 'Write your message and reach us through your preferred channel';
  String get yourNameLabel => isAr ? 'اسمك' : 'Your Name';
  String get emailOptionalLabel => isAr ? 'البريد الإلكتروني (اختياري)' : 'Email (Optional)';
  String get yourMessageLabel => isAr ? 'رسالتك' : 'Your Message';
  String get sendViaWhatsApp => isAr ? 'إرسال عبر واتساب' : 'Send via WhatsApp';
  String get sendViaTelegram => isAr ? 'إرسال عبر تيليغرام' : 'Send via Telegram';
  String get sendViaEmail => isAr ? 'إرسال عبر البريد الإلكتروني' : 'Send via Email';
  String get contactChannels => isAr ? 'قنوات التواصل' : 'Contact Channels';
  String get nameRequired => isAr ? 'الاسم مطلوب' : 'Name is required';
  String get messageRequired => isAr ? 'الرسالة مطلوبة' : 'Message is required';
  String get appInfo => isAr ? 'المدبّر الذكي — الإصدار 1.0.0' : 'Smart Advisor — Version 1.0.0';
  String get offlineFirst => isAr ? 'يعمل بدون اتصال بالإنترنت' : 'Works fully offline';
  String get feedbackWelcome => isAr
      ? 'آراؤك تهمنا! ساعدنا في تحسين التطبيق بمشاركة تجربتك.'
      : 'Your feedback matters! Help us improve by sharing your experience.';
}

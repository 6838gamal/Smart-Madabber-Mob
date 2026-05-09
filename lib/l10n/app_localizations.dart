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
  String get resources => isAr ? 'الموارد' : 'Resources';
  String get transactions => isAr ? 'المعاملات' : 'Transactions';
  String get insights => isAr ? 'التوصيات' : 'Insights';
  String get reports => isAr ? 'التقارير' : 'Reports';
  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get help => isAr ? 'المساعدة' : 'Help';

  // ── Theme footer ─────────────────────────────────────────────────────────
  String get lightMode => isAr ? 'فاتح' : 'Light';
  String get darkMode => isAr ? 'داكن' : 'Dark';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get intelligentOverview => isAr ? 'نظرتك الذكية الشاملة' : 'Your intelligent overview';
  String get today => isAr ? 'اليوم' : 'Today';
  String get trends => isAr ? 'الاتجاهات' : 'Trends';
  String get stock => isAr ? 'المخزون' : 'Stock';
  String get intelligence => isAr ? 'الذكاء' : 'Intelligence';
  String get refreshInsights => isAr ? 'تحديث التوصيات' : 'Refresh Insights';
  String get quickStats => isAr ? 'إحصائيات سريعة' : 'Quick Stats';
  String get totalResources => isAr ? 'إجمالي الموارد' : 'Total Resources';
  String get activeAlerts => isAr ? 'التنبيهات النشطة' : 'Active Alerts';
  String get needAttention => isAr ? 'تحتاج انتباهاً' : 'Need attention';
  String get critical => isAr ? 'حرج' : 'Critical';
  String get immediateAction => isAr ? 'إجراء فوري' : 'Immediate action';
  String get lowStock => isAr ? 'مخزون منخفض' : 'Low Stock';
  String get restockSoon => isAr ? 'أعد التخزين قريباً' : 'Restock soon';
  String get seeAll => isAr ? 'عرض الكل' : 'See all';
  String get recentActivity => isAr ? 'النشاط الأخير' : 'Recent Activity';
  String get noRecentTransactions => isAr ? 'لا توجد معاملات حديثة' : 'No recent transactions';
  String get addTransactionsForTrends => isAr
      ? 'أضف معاملات لرؤية الاتجاهات الأسبوعية هنا.'
      : 'Add transactions to see weekly trends here.';
  String get units => isAr ? 'وحدات' : 'units';
  String get activeRulesLabel => isAr ? 'القواعد النشطة' : 'Active Rules';
  String get engineSummary => isAr ? 'ملخص المحرك' : 'Engine Summary';
  String get insightsGenerated => isAr ? 'التوصيات المولّدة' : 'Insights Generated';
  String get active => isAr ? 'نشط' : 'Active';
  String get rulesActive => isAr ? 'قواعد نشطة' : 'Rules Active';
  String get totalRulesLabel => isAr ? 'إجمالي القواعد' : 'Total Rules';
  String get engineDescription => isAr
      ? 'يراقب محرك القواعد مواردك باستمرار ويولّد قرارات فورية تلقائياً.'
      : 'The rules engine continuously monitors your resources and automatically generates actionable decisions.';
  String get criticalSection => isAr ? '🚨 حرج' : '🚨 Critical';
  String get lowStockSection => isAr ? '⚠️ مخزون منخفض' : '⚠️ Low Stock';
  String get inactiveSection => isAr ? '😴 غير نشط' : '😴 Inactive';
  String get normalSection => isAr ? '✅ طبيعي' : '✅ Normal';
  String get noResourcesYet => isAr ? 'لا توجد موارد بعد' : 'No resources yet';
  String get addResourcesToTrack => isAr ? 'أضف موارد لتتبع حالتها.' : 'Add resources to track their status.';

  // ── Spent / Revenue ──────────────────────────────────────────────────────
  String get spent30d => isAr ? 'مصروف (30 يوم)' : 'Spent (30d)';
  String get revenue30d => isAr ? 'إيرادات (30 يوم)' : 'Revenue (30d)';
  String get txns7d => isAr ? 'معاملات (7 أيام)' : 'Transactions (7d)';
  String get txns30d => isAr ? 'معاملات (30 يوم)' : 'Transactions (30d)';

  // ── Decision Card ─────────────────────────────────────────────────────────
  String get decisionOfTheDay => isAr ? 'قرار اليوم' : 'Decision of the Day';
  String get allSystemsNormal => isAr ? '✅ كل شيء طبيعي' : '✅ All systems normal';
  String get noIssuesDetected => isAr
      ? 'لا توجد مشكلات حرجة. استمر في مراقبة مواردك.'
      : 'No critical issues detected. Keep monitoring your resources.';
  String get markResolved => isAr ? 'تحديد كمحلول' : 'Mark Resolved';

  // ── Insight Card ──────────────────────────────────────────────────────────
  String get dismiss => isAr ? 'تجاهل' : 'Dismiss';
  String get resolve => isAr ? 'حل' : 'Resolve';

  // ── Resource Card ─────────────────────────────────────────────────────────
  String get daysRemaining => isAr ? 'أيام متبقية' : 'days remaining';
  String get consumptionRateNotSet => isAr ? 'معدل الاستهلاك غير محدد' : 'Consumption rate not set';
  String get minPrefix => isAr ? 'الحد الأدنى: ' : 'min: ';

  // ── Resources Screen ──────────────────────────────────────────────────────
  String get searchResources => isAr ? 'ابحث عن مورد...' : 'Search resources...';
  String get addResource => isAr ? 'إضافة مورد' : 'Add Resource';
  String get all => isAr ? 'الكل' : 'All';
  String get low => isAr ? 'منخفض' : 'Low';
  String get normal => isAr ? 'طبيعي' : 'Normal';
  String get inactive => isAr ? 'غير نشط' : 'Inactive';
  String get noResourcesFound => isAr ? 'لم يتم العثور على موارد' : 'No resources found';
  String get tryDifferentSearch => isAr ? 'جرب مصطلح بحث مختلف.' : 'Try a different search term.';
  String get startByAdding => isAr ? 'ابدأ بإضافة أول مورد.' : 'Start by adding your first resource.';
  String get addTransaction => isAr ? 'إضافة معاملة' : 'Add Transaction';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get delete => isAr ? 'حذف' : 'Delete';
  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get resourceNameLabel => isAr ? 'اسم المورد' : 'Resource Name';
  String get unitLabel => isAr ? 'الوحدة (كجم، لتر...)' : 'Unit (kg, L, pcs...)';
  String get currentQuantityLabel => isAr ? 'الكمية الحالية' : 'Current Quantity';
  String get minThresholdLabel => isAr ? 'الحد الأدنى للتنبيه' : 'Min Threshold';
  String get dailyRateLabel => isAr ? 'معدل الاستهلاك اليومي' : 'Daily Consumption Rate';
  String get resourceTypeLabel => isAr ? 'نوع المورد' : 'Resource Type';
  String get editResource => isAr ? 'تعديل المورد' : 'Edit Resource';
  String get newResource => isAr ? 'مورد جديد' : 'New Resource';
  String get confirmDelete => isAr ? 'تأكيد الحذف' : 'Confirm Delete';
  String get deleteConfirmMsg => isAr
      ? 'هل أنت متأكد من حذف هذا المورد؟ سيتم حذف جميع معاملاته أيضاً.'
      : 'Are you sure you want to delete this resource? All its transactions will also be deleted.';
  String get quantityLabel => isAr ? 'الكمية' : 'Quantity';
  String get priceLabel => isAr ? 'السعر' : 'Price';
  String get notesLabel => isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)';
  String get typeLabel => isAr ? 'النوع' : 'Type';

  // ── Transactions Screen ───────────────────────────────────────────────────
  String get noTransactions => isAr ? 'لا توجد معاملات' : 'No transactions';
  String get logFirstTransaction => isAr ? 'سجّل أول معاملة أعلاه.' : 'Log your first transaction above.';
  String get allTypes => isAr ? 'كل الأنواع' : 'All Types';
  String get last7Days => isAr ? 'آخر 7 أيام' : 'Last 7 days';
  String get last30Days => isAr ? 'آخر 30 يوم' : 'Last 30 days';
  String get last90Days => isAr ? 'آخر 90 يوم' : 'Last 90 days';

  // ── Insights Screen ───────────────────────────────────────────────────────
  String get resolved => isAr ? 'محلولة' : 'Resolved';
  String get dismissed => isAr ? 'مرفوضة' : 'Dismissed';
  String get noActiveInsights => isAr ? 'لا توجد توصيات نشطة' : 'No active insights';
  String get noResolvedInsights => isAr ? 'لا توجد توصيات محلولة' : 'No resolved insights';
  String get noDismissedInsights => isAr ? 'لا توجد توصيات مرفوضة' : 'No dismissed insights';
  String get rulesWillGenerate => isAr
      ? 'سيولّد محرك القواعد توصيات تلقائياً عند رصد أي مشكلة.'
      : 'The rules engine will generate insights automatically.';
  String get refresh => isAr ? 'تحديث' : 'Refresh';

  // ── Reports Screen ────────────────────────────────────────────────────────
  String get dataAtAGlance => isAr ? 'بياناتك في لمحة' : 'Your data at a glance';
  String get resourceHealth => isAr ? 'صحة الموارد' : 'Resource Health';
  String get transactionSummary => isAr ? 'ملخص المعاملات' : 'Transaction Summary';
  String get topResourcesByConsumption => isAr ? 'أعلى الموارد استهلاكاً' : 'Top Resources by Consumption';
  String get financialOverview => isAr ? 'النظرة المالية' : 'Financial Overview';
  String get noDataForChart => isAr ? 'لا توجد بيانات بعد' : 'No data yet';
  String get resource => isAr ? 'المورد' : 'Resource';
  String get dailyRate => isAr ? 'المعدل اليومي' : 'Daily Rate';
  String get status => isAr ? 'الحالة' : 'Status';
  String get totalSpentLabel => isAr ? 'إجمالي المصروف' : 'Total Spent';
  String get totalRevenueLabel => isAr ? 'إجمالي الإيرادات' : 'Total Revenue';
  String get netLabel => isAr ? 'الصافي' : 'Net';
  String get transactionsCountLabel => isAr ? 'عدد المعاملات' : 'Transactions';

  // ── Settings Screen ───────────────────────────────────────────────────────
  String get customizeExperience => isAr
      ? 'خصص تجربتك مع المدبّر الذكي'
      : 'Customize your Smart Advisor experience';
  String get appearance => isAr ? 'المظهر' : 'Appearance';
  String get darkModeLabel => isAr ? 'الوضع الداكن' : 'Dark Mode';
  String get switchTheme => isAr ? 'التبديل بين الوضعين الفاتح والداكن' : 'Switch between light and dark theme';
  String get languageLabel => isAr ? 'اللغة' : 'Language';
  String get currencyLabel => isAr ? 'العملة' : 'Currency';
  String get displayCurrencyLabel => isAr ? 'عملة العرض' : 'Display Currency';
  String get rulesEngineLabel => isAr ? 'محرك القواعد' : 'Rules Engine';
  String get aboutLabel => isAr ? 'حول التطبيق' : 'About';
  String get versionInfo => isAr ? 'الإصدار 1.0.0 · يعمل بدون اتصال' : 'Version 1.0.0 · Offline-first decision engine';
  String get dataStorageLabel => isAr ? 'تخزين البيانات' : 'Data Storage';
  String get dataStoredLocally => isAr ? 'جميع البيانات مخزنة محلياً على جهازك' : 'All data stored locally on your device';
  String get systemLabel => isAr ? 'النظام' : 'System';
  String get arabicLanguage => 'العربية';
  String get englishLanguage => 'English';

  // ── Help Screen ───────────────────────────────────────────────────────────
  String get helpContactTitle => isAr ? 'المساعدة والتواصل' : 'Help & Contact';
  String get hereToHelp => isAr ? 'نحن هنا للمساعدة' : 'We\'re here to help';
  String get helpSubtitle => isAr
      ? 'اكتب رسالتك وتواصل معنا عبر قناتك المفضلة'
      : 'Write your message and contact us through your preferred channel';
  String get yourNameLabel => isAr ? 'اسمك' : 'Your Name';
  String get emailOptionalLabel => isAr ? 'البريد الإلكتروني (اختياري)' : 'Email (Optional)';
  String get yourMessageLabel => isAr ? 'رسالتك' : 'Your Message';
  String get sendViaWhatsApp => isAr ? 'إرسال عبر واتساب' : 'Send via WhatsApp';
  String get sendViaTelegram => isAr ? 'إرسال عبر تيليغرام' : 'Send via Telegram';
  String get sendViaEmail => isAr ? 'إرسال عبر البريد' : 'Send via Email';
  String get contactChannels => isAr ? 'قنوات التواصل' : 'Contact Channels';
  String get nameRequired => isAr ? 'الاسم مطلوب' : 'Name is required';
  String get messageRequired => isAr ? 'الرسالة مطلوبة' : 'Message is required';
  String get appInfo => isAr ? 'المدبّر الذكي — الإصدار 1.0.0' : 'Smart Advisor — Version 1.0.0';
  String get offlineFirst => isAr ? 'يعمل بدون اتصال بالإنترنت' : 'Works fully offline';
  String get feedbackWelcome => isAr
      ? 'آراؤك تهمنا! ساعدنا في تحسين التطبيق بمشاركة تجربتك.'
      : 'Your feedback matters! Help us improve by sharing your experience.';
}

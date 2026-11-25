import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../models/recurring_journal.dart';
import '../../theme/app_theme.dart';
import 'recurring_journal_form_screen.dart';

class RecurringJournalsScreen extends StatelessWidget {
  const RecurringJournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final list = provider.sortedRecurringJournals;

    return Scaffold(
      body: Column(
        children: [
          if (provider.dueRecurringCount > 0)
            _buildDueBanner(context, provider),
          Expanded(
            child: list.isEmpty
                ? _buildEmpty(context)
                : _buildList(context, provider, list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_recurring_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('قالب جديد'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RecurringJournalFormScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDueBanner(BuildContext context, AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${provider.dueRecurringCount} قالب مستحق للإنشاء',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('إنشاء الكل'),
            onPressed: () async {
              final count = await provider.generateAllDueEntries();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إنشاء $count قيد'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppProvider provider,
    List<RecurringJournal> list,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(context, provider, list[i]),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppProvider provider,
    RecurringJournal r,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final next = r.nextDueDate;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      (r.isActive ? Colors.green : Colors.grey).withOpacity(0.15),
                  child: Icon(
                    r.isActive ? Icons.repeat : Icons.pause,
                    color: r.isActive ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.reference,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        r.description.isEmpty ? '—' : r.description,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RecurringJournalFormScreen(existing: r),
                          ),
                        );
                        break;
                      case 'toggle':
                        await provider.toggleRecurringJournal(r.id);
                        break;
                      case 'generate':
                        final n =
                            await provider.generateDueEntriesFor(r.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(n == 0
                                  ? 'لا توجد قيود مستحقة'
                                  : 'تم إنشاء $n قيد'),
                            ),
                          );
                        }
                        break;
                      case 'delete':
                        await _confirmDelete(context, provider, r);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(r.isActive ? 'إيقاف مؤقت' : 'تنشيط'),
                    ),
                    const PopupMenuItem(
                        value: 'generate',
                        child: Text('إنشاء المستحق الآن')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  'التكرار: ${r.frequency.labelAr}',
                  Colors.blue,
                ),
                _chip(
                  'يبدأ: ${_formatDate(r.startDate)}',
                  Colors.blueGrey,
                ),
                if (r.endDate != null)
                  _chip(
                    'ينتهي: ${_formatDate(r.endDate!)}',
                    Colors.purple,
                  ),
                if (next != null)
                  _chip(
                    'التالي: ${_formatDate(next)}',
                    r.isDue ? Colors.orange : Colors.green,
                  ),
                if (r.lastGenerated != null)
                  _chip(
                    'آخر إنشاء: ${_formatDate(r.lastGenerated!)}',
                    Colors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _amountBox(
                    'مدين',
                    r.totalDebit,
                    Colors.green,
                    provider,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _amountBox(
                    'دائن',
                    r.totalCredit,
                    Colors.red,
                    provider,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _amountBox(
    String label,
    double v,
    Color color,
    AppProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          Text(
            provider.formatAmount(v),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppProvider provider,
    RecurringJournal r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القالب'),
        content: Text('هل تريد حذف "${r.reference}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await provider.deleteRecurringJournal(r.id);
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد قيود متكررة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أنشئ قالباً يتكرر تلقائياً (إيجار، رواتب...)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y/$m/$dd';
  }
}

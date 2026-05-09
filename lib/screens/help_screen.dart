import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  String _buildMessage() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final msg = _msgCtrl.text.trim();
    final buffer = StringBuffer();
    buffer.writeln('*المدبّر الذكي — Smart Advisor*');
    buffer.writeln('');
    if (name.isNotEmpty) buffer.writeln('👤 $name');
    if (email.isNotEmpty) buffer.writeln('📧 $email');
    buffer.writeln('');
    buffer.writeln(msg);
    return buffer.toString();
  }

  bool _validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _sendWhatsApp() {
    if (!_validate()) return;
    final text = Uri.encodeComponent(_buildMessage());
    html.window.open('https://wa.me/967770000000?text=$text', '_blank');
  }

  void _sendTelegram() {
    if (!_validate()) return;
    final text = Uri.encodeComponent(_buildMessage());
    html.window.open('https://t.me/smartadvisorye?start=$text', '_blank');
  }

  void _sendEmail() {
    if (!_validate()) return;
    final name = _nameCtrl.text.trim();
    final msg = Uri.encodeComponent(_msgCtrl.text.trim());
    final subject = Uri.encodeComponent('Smart Advisor — رسالة من $name');
    html.window
        .open('mailto:support@smartadvisor.ye?subject=$subject&body=$msg', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark, l10n),
          const SizedBox(height: 24),
          _buildInfoBanner(isDark, l10n),
          const SizedBox(height: 24),
          _buildForm(isDark, l10n),
          const SizedBox(height: 24),
          _buildChannels(isDark, l10n),
          const SizedBox(height: 24),
          _buildAppInfo(isDark, l10n, provider),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.helpContactTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.helpSubtitle,
          style: TextStyle(
            fontSize: 13,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(bool isDark, L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hereToHelp,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.feedbackWelcome,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, L10n l10n) {
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.contactChannels,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.yourNameLabel,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: l10n.emailOptionalLabel,
                prefixIcon:
                    const Icon(Icons.email_outlined, size: 18),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                labelText: l10n.yourMessageLabel,
                prefixIcon:
                    const Icon(Icons.message_outlined, size: 18),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.messageRequired : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannels(bool isDark, L10n l10n) {
    return Column(
      children: [
        _ChannelButton(
          icon: Icons.chat_rounded,
          label: l10n.sendViaWhatsApp,
          color: const Color(0xFF25D366),
          onTap: _sendWhatsApp,
        ),
        const SizedBox(height: 10),
        _ChannelButton(
          icon: Icons.send_rounded,
          label: l10n.sendViaTelegram,
          color: const Color(0xFF0088CC),
          onTap: _sendTelegram,
        ),
        const SizedBox(height: 10),
        _ChannelButton(
          icon: Icons.email_rounded,
          label: l10n.sendViaEmail,
          color: AppColors.primary,
          onTap: _sendEmail,
        ),
      ],
    );
  }

  Widget _buildAppInfo(bool isDark, L10n l10n, AppProvider provider) {
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _InfoRow(
            isDark: isDark,
            icon: Icons.psychology_rounded,
            text: l10n.appInfo,
          ),
          Divider(height: 20, color: borderColor),
          _InfoRow(
            isDark: isDark,
            icon: Icons.wifi_off_rounded,
            text: l10n.offlineFirst,
          ),
          Divider(height: 20, color: borderColor),
          _InfoRow(
            isDark: isDark,
            icon: Icons.storage_rounded,
            text:
                '${provider.resources.length} ${l10n.resources} · ${provider.transactions.length} ${l10n.transactions} · ${provider.insights.length} ${l10n.insights}',
          ),
        ],
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ChannelButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;

  const _InfoRow(
      {required this.isDark, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// lib/screens/ai_assistant_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../models/chat_message.dart';
import '../services/ai_assistant_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _messages = <ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = AiAssistantService();
  final _tts = TtsService();
  final _audioPlayer = AudioPlayer();
  final _recorder = AudioRecorder();

  ChatAttachment? _pendingAttachment;
  bool _isSending = false;
  bool _autoSpeak = true;

  // تسجيل صوتي
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      id: 'welcome',
      role: MessageRole.assistant,
      text: 'مرحباً 👋 أنا مساعدك المحاسبي الذكي.\n'
          'يمكنك:\n'
          '• كتابة سؤالك نصياً\n'
          '• رفع ملف CSV / XLSX / Word / PDF\n'
          '• إرسال صورة فاتورة\n'
          '• تسجيل رسالة صوتية\n\n'
          'كيف أساعدك اليوم؟',
      timestamp: DateTime.now(),
    ));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _tts.stop();
    _recordTimer?.cancel();
    super.dispose();
  }

  // ── مساعدات ──
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── إرسال رسالة ──
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    if (_isSending) return;

    final userMsg = ChatMessage(
      id: _newId(),
      role: MessageRole.user,
      text: text.isEmpty ? '📎 ${_pendingAttachment!.name}' : text,
      timestamp: DateTime.now(),
      attachment: _pendingAttachment,
    );

    setState(() {
      _messages.add(userMsg);
      _pendingAttachment = null;
      _inputCtrl.clear();
      _isSending = true;
    });
    _scrollToBottom();

    // فقاعة مؤقتة للمساعد مع مؤشر كتابة
    final placeholder = ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      text: '...',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(placeholder));
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        text: text,
        attachment: userMsg.attachment,
        history: List.unmodifiable(_messages),
      );
      if (!mounted) return;

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == placeholder.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            text: reply,
            isStreaming: false,
          );
        }
        _isSending = false;
      });
      _scrollToBottom();

      // النطق التلقائي للرد
      if (_autoSpeak) {
        _speakText(reply);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == placeholder.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            text: 'تعذّر الاتصال بالمساعد: $e',
            isStreaming: false,
            isError: true,
          );
        }
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      // تجاهل أخطاء TTS
    }
  }

  // ── رفع ملف ──
  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'doc', 'docx', 'pdf'],
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.single;
    final ext = (f.extension ?? '').toLowerCase();
    final type = switch (ext) {
      'csv' => AttachmentType.csv,
      'xlsx' || 'xls' => AttachmentType.xlsx,
      'doc' || 'docx' => AttachmentType.word,
      'pdf' => AttachmentType.pdf,
      _ => AttachmentType.other,
    };
    setState(() {
      _pendingAttachment = ChatAttachment(
        name: f.name,
        path: f.path,
        type: type,
        sizeBytes: f.size,
      );
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _pendingAttachment = ChatAttachment(
        name: file.name,
        path: file.path,
        type: AttachmentType.image,
      );
    });
  }

  // ── تسجيل صوتي ──
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      _showError('تم رفض إذن الميكروفون');
      return;
    }
    if (!await _recorder.hasPermission()) {
      _showError('لا يوجد إذن للتسجيل');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordDuration = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (path != null && path.isNotEmpty) {
        _pendingAttachment = ChatAttachment(
          name: 'رسالة صوتية (${_formatDuration(_recordDuration)})',
          path: path,
          type: AttachmentType.audio,
        );
      }
    });
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingPath = null;
      _recordDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      _showError('تعذّر التشغيل: $e');
    }
  }

  // ── البناء ──
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _autoSpeak ? 'إيقاف النطق التلقائي' : 'تشغيل النطق التلقائي',
            icon: Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            ),
            onPressed: () {
              setState(() => _autoSpeak = !_autoSpeak);
              if (!_autoSpeak) _tts.stop();
            },
          ),
          IconButton(
            tooltip: 'مسح المحادثة',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                _messages.removeWhere((m) => m.id != 'welcome');
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _bubble(_messages[i], isDark),
            ),
          ),
          if (_pendingAttachment != null) _attachmentPreview(isDark),
          _inputBar(isDark),
        ],
      ),
    );
  }

  // ── فقاعة رسالة ──
  Widget _bubble(ChatMessage m, bool isDark) {
    final isUser = m.role == MessageRole.user;
    final maxW = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxW),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withOpacity(0.9)
              : (isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: m.isError
              ? Border.all(color: Colors.red, width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.attachment != null) _attachmentChip(m.attachment!),
            if (m.attachment != null && m.text.isNotEmpty)
              const SizedBox(height: 6),
            if (m.isStreaming)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Text(
                m.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            if (!isUser && !m.isStreaming && !m.isError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _miniAction(
                      icon: Icons.volume_up_rounded,
                      tooltip: 'اسمع الرد',
                      onTap: () => _speakText(m.text),
                    ),
                    _miniAction(
                      icon: Icons.copy_rounded,
                      tooltip: 'نسخ',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: m.text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم النسخ')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _attachmentChip(ChatAttachment att) {
    final icon = switch (att.type) {
      AttachmentType.audio => Icons.mic_rounded,
      AttachmentType.image => Icons.image_rounded,
      AttachmentType.csv => Icons.table_chart_rounded,
      AttachmentType.xlsx => Icons.grid_on_rounded,
      AttachmentType.word => Icons.description_rounded,
      AttachmentType.pdf => Icons.picture_as_pdf_rounded,
      _ => Icons.attach_file_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              att.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (att.type == AttachmentType.audio && att.path != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _playAudio(att.path!),
              child: const Icon(Icons.play_arrow_rounded, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  // ── معاينة المرفق قبل الإرسال ──
  Widget _attachmentPreview(bool isDark) {
    final att = _pendingAttachment!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? Colors.black26 : Colors.grey.shade200,
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (att.type == AttachmentType.audio && att.path != null)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => _playAudio(att.path!),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _pendingAttachment = null),
          ),
        ],
      ),
    );
  }

  // ── شريط الإدخال ──
  Widget _inputBar(bool isDark) {
    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.all(10),
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _cancelRecording,
              ),
              const Icon(Icons.fiber_manual_record, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _toggleRecording,
                icon: const Icon(Icons.stop),
                label: const Text('إيقاف'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'إرفاق',
              onSelected: (v) {
                if (v == 'file') _pickFile();
                if (v == 'image') _pickImage();
                if (v == 'audio') _startRecording();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'file',
                  child: ListTile(
                    leading: Icon(Icons.attach_file),
                    title: Text('ملف (CSV/XLSX/Word/PDF)'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'image',
                  child: ListTile(
                    leading: Icon(Icons.image_outlined),
                    title: Text('صورة'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'audio',
                  child: ListTile(
                    leading: Icon(Icons.mic_none_rounded),
                    title: Text('تسجيل صوتي'),
                    dense: true,
                  ),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: _isSending ? Colors.grey : AppColors.primary,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

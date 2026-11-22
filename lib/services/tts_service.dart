// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // iOS/بعض الأجهزة تحتاج تحديد الصوت
    try {
      final voices = await _tts.getVoices;
      final arabic = (voices as List?)?.firstWhere(
        (v) => v.toString().toLowerCase().contains('ar'),
        orElse: () => null,
      );
      if (arabic != null) await _tts.setVoice(arabic as Map<String, String>);
    } catch (_) {}
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
  Future<void> pause() => _tts.pause();
}

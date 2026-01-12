import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses efektleri servisi - Singleton
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _initialized = false;

  /// Başlangıçta ayarları yükle
  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _initialized = true;

    // Preload sounds
    await _preloadSounds();
  }

  Future<void> _preloadSounds() async {
    try {
      await _buttonPlayer.setSource(AssetSource('sounds/button_click.mp3'));
      await _effectPlayer.setSource(AssetSource('sounds/win.mp3'));
    } catch (e) {
      print('🔇 Error preloading sounds: $e');
    }
  }

  /// Ses ayarını güncelle
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
  }

  /// Ses açık mı?
  bool get isSoundEnabled => _soundEnabled;

  /// Buton tıklama sesi
  Future<void> playButtonClick() async {
    if (!_soundEnabled) return;
    try {
      await _buttonPlayer.stop();
      await _buttonPlayer.setSource(AssetSource('sounds/button_click.mp3'));
      await _buttonPlayer.resume();
    } catch (e) {
      print('🔇 Error playing button click: $e');
    }
  }

  /// Hata sesi
  Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setSource(AssetSource('sounds/error.mp3'));
      await _effectPlayer.resume();
    } catch (e) {
      print('🔇 Error playing error sound: $e');
    }
  }

  /// Kazanma sesi
  Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setSource(AssetSource('sounds/win.mp3'));
      await _effectPlayer.resume();
    } catch (e) {
      print('🔇 Error playing win sound: $e');
    }
  }

  /// Kaybetme sesi
  Future<void> playLose() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setSource(AssetSource('sounds/lose.mp3'));
      await _effectPlayer.resume();
    } catch (e) {
      print('🔇 Error playing lose sound: $e');
    }
  }

  /// Eşleşme bulundu sesi
  Future<void> playMatchFound() async {
    if (!_soundEnabled) return;
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setSource(AssetSource('sounds/match_found.mp3'));
      await _effectPlayer.resume();
    } catch (e) {
      print('🔇 Error playing match found sound: $e');
    }
  }

  /// Doğru hamle sesi (kısa tık)
  Future<void> playCorrect() async {
    if (!_soundEnabled) return;
    try {
      await _buttonPlayer.stop();
      await _buttonPlayer.setSource(AssetSource('sounds/button_click.mp3'));
      await _buttonPlayer.resume();
    } catch (e) {
      print('🔇 Error playing correct sound: $e');
    }
  }

  /// Tüm sesleri durdur
  Future<void> stopAll() async {
    await _buttonPlayer.stop();
    await _effectPlayer.stop();
    await _musicPlayer.stop();
  }

  /// Kaynakları temizle
  void dispose() {
    _buttonPlayer.dispose();
    _effectPlayer.dispose();
    _musicPlayer.dispose();
  }
}

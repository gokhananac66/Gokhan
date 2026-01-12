import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple Sound Service with toggle support
/// Usage:
///   SoundService().playButtonClick();
///   SoundService().toggleSound(true/false);
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  /// Initialize sound service and load preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

  /// Check if sound is enabled
  bool get isSoundEnabled => _soundEnabled;

  /// Toggle sound on/off
  Future<void> toggleSound(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
  }

  /// Play button click sound
  Future<void> playButtonClick() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/button_click.mp3'));
    } catch (e) {
      print('Error playing button click sound: $e');
    }
  }

  /// Play win sound
  Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/win.mp3'));
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  /// Play lose sound
  Future<void> playLose() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/lose.mp3'));
    } catch (e) {
      print('Error playing lose sound: $e');
    }
  }

  /// Play move/place number sound
  Future<void> playMove() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/move.mp3'));
    } catch (e) {
      print('Error playing move sound: $e');
    }
  }

  /// Play error/wrong move sound
  Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  /// Play match found sound
  Future<void> playMatchFound() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/match_found.mp3'));
    } catch (e) {
      print('Error playing match found sound: $e');
    }
  }

  /// Dispose audio player
  void dispose() {
    _player.dispose();
  }
}

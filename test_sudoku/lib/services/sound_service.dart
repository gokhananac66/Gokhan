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
    // Sound files not added yet. To enable:
    // 1. Create assets/sounds/ folder
    // 2. Add button_click.mp3
    // 3. Update pubspec.yaml: assets: - assets/sounds/
    // 4. Uncomment: await _player.play(AssetSource('sounds/button_click.mp3'));
  }

  /// Play win sound
  Future<void> playWin() async {
    if (!_soundEnabled) return;
    // Add win.mp3 to assets/sounds/ and uncomment:
    // await _player.play(AssetSource('sounds/win.mp3'));
  }

  /// Play lose sound
  Future<void> playLose() async {
    if (!_soundEnabled) return;
    // Add lose.mp3 to assets/sounds/ and uncomment:
    // await _player.play(AssetSource('sounds/lose.mp3'));
  }

  /// Play move/place number sound
  Future<void> playMove() async {
    if (!_soundEnabled) return;
    // Add move.mp3 to assets/sounds/ and uncomment:
    // await _player.play(AssetSource('sounds/move.mp3'));
  }

  /// Play error/wrong move sound
  Future<void> playError() async {
    if (!_soundEnabled) return;
    // Add error.mp3 to assets/sounds/ and uncomment:
    // await _player.play(AssetSource('sounds/error.mp3'));
  }

  /// Play match found sound
  Future<void> playMatchFound() async {
    if (!_soundEnabled) return;
    // Add match_found.mp3 to assets/sounds/ and uncomment:
    // await _player.play(AssetSource('sounds/match_found.mp3'));
  }

  /// Dispose audio player
  void dispose() {
    _player.dispose();
  }
}

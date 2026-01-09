import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple Haptic Feedback Service with toggle support
/// Usage:
///   HapticService().lightImpact();
///   HapticService().mediumImpact();
///   HapticService().toggleHaptic(true/false);
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _hapticEnabled = true;

  /// Initialize haptic service and load preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticEnabled = prefs.getBool('vibrationEnabled') ?? true;
  }

  /// Check if haptic is enabled
  bool get isHapticEnabled => _hapticEnabled;

  /// Toggle haptic on/off
  Future<void> toggleHaptic(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', enabled);
  }

  /// Light impact - for button taps
  Future<void> lightImpact() async {
    if (!_hapticEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for selections, toggles
  Future<void> mediumImpact() async {
    if (!_hapticEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for game events, wins
  Future<void> heavyImpact() async {
    if (!_hapticEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for list item selections
  Future<void> selectionClick() async {
    if (!_hapticEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate pattern - for errors, warnings
  Future<void> vibrate() async {
    if (!_hapticEnabled) return;
    await HapticFeedback.vibrate();
  }
}

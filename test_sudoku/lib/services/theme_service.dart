import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';

/// Service for managing game board themes
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get currently selected theme
  Future<String> getSelectedTheme() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 'default';

    try {
      final snapshot = await _database.child('users/$userId/selectedTheme').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedTheme') ?? 'default';
    } catch (e) {
      print('Error getting theme: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedTheme') ?? 'default';
    }
  }

  /// Set selected theme
  Future<void> setSelectedTheme(String themeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Save to Firebase
      await _database.child('users/$userId/selectedTheme').set(themeId);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedTheme', themeId);
    } catch (e) {
      print('Error setting theme: $e');
    }
  }

  /// Check if theme is unlocked
  Future<bool> isThemeUnlocked(String themeId) async {
    if (themeId == 'default') return true; // Default theme is always unlocked

    final currencyService = CurrencyService();
    final purchased = await currencyService.getPurchasedItems();

    // Map theme IDs to shop item IDs
    final shopItemId = 'theme_${themeId}';
    return purchased.contains(shopItemId);
  }
}

/// Game board theme with color palettes
class GameTheme {
  final String id;
  final String name;
  final Color selectedCell;
  final Color highlightedCell;
  final Color wrongCell;
  final Color completedCell;
  final Color gridLineColor;
  final Color thickGridLineColor;
  final Color textColor;
  final Color hintTextColor;

  const GameTheme({
    required this.id,
    required this.name,
    required this.selectedCell,
    required this.highlightedCell,
    required this.wrongCell,
    required this.completedCell,
    required this.gridLineColor,
    required this.thickGridLineColor,
    required this.textColor,
    required this.hintTextColor,
  });

  /// Get theme by ID
  static GameTheme getTheme(String id, bool isDark) {
    switch (id) {
      case 'neon':
        return _neonTheme(isDark);
      case 'ocean':
        return _oceanTheme(isDark);
      case 'sunset':
        return _sunsetTheme(isDark);
      case 'forest':
        return _forestTheme(isDark);
      case 'galaxy':
        return _galaxyTheme(isDark);
      default:
        return _defaultTheme(isDark);
    }
  }

  // DEFAULT THEME (Ultra-soft palette)
  static GameTheme _defaultTheme(bool isDark) {
    return GameTheme(
      id: 'default',
      name: 'Default',
      selectedCell: isDark ? const Color(0xFF2D4A6F) : const Color(0xFFE3F2FD),
      highlightedCell: isDark
          ? const Color(0xFF2D4A6F).withOpacity(0.5)
          : const Color(0xFFE3F2FD).withOpacity(0.6),
      wrongCell: isDark
          ? Colors.red.shade900.withOpacity(0.3)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? Colors.green.shade900.withOpacity(0.2)
          : const Color(0xFFE8F5E9),
      gridLineColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      thickGridLineColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      textColor: isDark ? Colors.white : Colors.black87,
      hintTextColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
    );
  }

  // NEON THEME (Pink, Purple, Yellow tones)
  static GameTheme _neonTheme(bool isDark) {
    return GameTheme(
      id: 'neon',
      name: 'Neon',
      selectedCell: const Color(0xFFFF1493), // Deep pink
      highlightedCell: const Color(0xFFFF1493).withOpacity(0.3),
      wrongCell: const Color(0xFFFFFF00).withOpacity(0.3), // Neon yellow
      completedCell: const Color(0xFF9D00FF).withOpacity(0.3), // Neon purple
      gridLineColor: isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC),
      thickGridLineColor: const Color(0xFFFF00FF), // Neon magenta
      textColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      hintTextColor: const Color(0xFFFF1493),
    );
  }

  // OCEAN THEME (Blue, Turquoise tones)
  static GameTheme _oceanTheme(bool isDark) {
    return GameTheme(
      id: 'ocean',
      name: 'Ocean',
      selectedCell: const Color(0xFF00BCD4), // Cyan
      highlightedCell: const Color(0xFF00BCD4).withOpacity(0.3),
      wrongCell: const Color(0xFFFF6B6B).withOpacity(0.3),
      completedCell: const Color(0xFF26A69A).withOpacity(0.4), // Teal
      gridLineColor: isDark ? const Color(0xFF37474F) : const Color(0xFFB0BEC5),
      thickGridLineColor: const Color(0xFF006064), // Dark cyan
      textColor: isDark ? const Color(0xFFE0F7FA) : const Color(0xFF006064),
      hintTextColor: const Color(0xFF00BCD4),
    );
  }

  // SUNSET THEME (Orange, Red tones)
  static GameTheme _sunsetTheme(bool isDark) {
    return GameTheme(
      id: 'sunset',
      name: 'Sunset',
      selectedCell: const Color(0xFFFF6B35), // Orange
      highlightedCell: const Color(0xFFFF6B35).withOpacity(0.3),
      wrongCell: const Color(0xFFFFEB3B).withOpacity(0.4), // Yellow
      completedCell: const Color(0xFFE91E63).withOpacity(0.3), // Pink
      gridLineColor: isDark ? const Color(0xFF5D4037) : const Color(0xFFFFCCBC),
      thickGridLineColor: const Color(0xFFBF360C), // Deep orange
      textColor: isDark ? const Color(0xFFFFE0B2) : const Color(0xFFBF360C),
      hintTextColor: const Color(0xFFFF6B35),
    );
  }

  // FOREST THEME (Green tones)
  static GameTheme _forestTheme(bool isDark) {
    return GameTheme(
      id: 'forest',
      name: 'Forest',
      selectedCell: const Color(0xFF4CAF50), // Green
      highlightedCell: const Color(0xFF4CAF50).withOpacity(0.3),
      wrongCell: const Color(0xFFFF9800).withOpacity(0.3), // Orange
      completedCell: const Color(0xFF8BC34A).withOpacity(0.4), // Light green
      gridLineColor: isDark ? const Color(0xFF33691E) : const Color(0xFFC8E6C9),
      thickGridLineColor: const Color(0xFF1B5E20), // Dark green
      textColor: isDark ? const Color(0xFFDCEDC8) : const Color(0xFF1B5E20),
      hintTextColor: const Color(0xFF4CAF50),
    );
  }

  // GALAXY THEME (Purple, Dark Blue tones)
  static GameTheme _galaxyTheme(bool isDark) {
    return GameTheme(
      id: 'galaxy',
      name: 'Galaxy',
      selectedCell: const Color(0xFF673AB7), // Deep purple
      highlightedCell: const Color(0xFF673AB7).withOpacity(0.3),
      wrongCell: const Color(0xFFE91E63).withOpacity(0.3), // Pink
      completedCell: const Color(0xFF3F51B5).withOpacity(0.4), // Indigo
      gridLineColor: isDark ? const Color(0xFF1A237E) : const Color(0xFFD1C4E9),
      thickGridLineColor: const Color(0xFF311B92), // Deep purple
      textColor: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF311B92),
      hintTextColor: const Color(0xFF9C27B0),
    );
  }

  /// Get all available themes
  static List<String> getAllThemeIds() {
    return ['default', 'neon', 'ocean', 'sunset', 'forest', 'galaxy'];
  }
}

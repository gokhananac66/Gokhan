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
      case 'ocean':
        return _oceanTheme(isDark);
      case 'sunset':
        return _sunsetTheme(isDark);
      case 'forest':
        return _forestTheme(isDark);
      case 'galaxy':
        return _galaxyTheme(isDark);
      case 'midnight':
        return _midnightTheme(isDark);
      case 'rose':
        return _roseTheme(isDark);
      case 'lavender':
        return _lavenderTheme(isDark);
      case 'earth':
        return _earthTheme(isDark);
      case 'mint':
        return _mintTheme(isDark);
      default:
        return _defaultTheme(isDark);
    }
  }

  // 1. DEFAULT THEME - Clean Blue
  static GameTheme _defaultTheme(bool isDark) {
    return GameTheme(
      id: 'default',
      name: 'Klasik',
      selectedCell: isDark
          ? const Color(0xFF1E3A5F)
          : const Color(0xFFE3F2FD),
      highlightedCell: isDark
          ? const Color(0xFF1E3A5F).withOpacity(0.4)
          : const Color(0xFFE3F2FD).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A1A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF1B4332)
          : const Color(0xFFE8F5E9),
      gridLineColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
      thickGridLineColor: isDark ? const Color(0xFF606060) : const Color(0xFF757575),
      textColor: isDark ? Colors.white : const Color(0xFF212121),
      hintTextColor: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
    );
  }

  // 2. OCEAN THEME - Soft Teal
  static GameTheme _oceanTheme(bool isDark) {
    return GameTheme(
      id: 'ocean',
      name: 'Okyanus',
      selectedCell: isDark
          ? const Color(0xFF0D4F4F)
          : const Color(0xFFE0F2F1),
      highlightedCell: isDark
          ? const Color(0xFF0D4F4F).withOpacity(0.4)
          : const Color(0xFFE0F2F1).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C2A2A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF004D40)
          : const Color(0xFFB2DFDB),
      gridLineColor: isDark ? const Color(0xFF37474F) : const Color(0xFFB0BEC5),
      thickGridLineColor: isDark ? const Color(0xFF546E7A) : const Color(0xFF607D8B),
      textColor: isDark ? const Color(0xFFB2DFDB) : const Color(0xFF00695C),
      hintTextColor: isDark ? const Color(0xFF80CBC4) : const Color(0xFF4DB6AC),
    );
  }

  // 3. SUNSET THEME - Warm Coral
  static GameTheme _sunsetTheme(bool isDark) {
    return GameTheme(
      id: 'sunset',
      name: 'Gün Batımı',
      selectedCell: isDark
          ? const Color(0xFF5D2E0C)
          : const Color(0xFFFFF3E0),
      highlightedCell: isDark
          ? const Color(0xFF5D2E0C).withOpacity(0.4)
          : const Color(0xFFFFF3E0).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A1A)
          : const Color(0xFFFFCDD2),
      completedCell: isDark
          ? const Color(0xFF4E342E)
          : const Color(0xFFFFE0B2),
      gridLineColor: isDark ? const Color(0xFF5D4037) : const Color(0xFFD7CCC8),
      thickGridLineColor: isDark ? const Color(0xFF795548) : const Color(0xFF8D6E63),
      textColor: isDark ? const Color(0xFFFFE0B2) : const Color(0xFFBF360C),
      hintTextColor: isDark ? const Color(0xFFFFCC80) : const Color(0xFFFF8A65),
    );
  }

  // 4. FOREST THEME - Natural Green
  static GameTheme _forestTheme(bool isDark) {
    return GameTheme(
      id: 'forest',
      name: 'Orman',
      selectedCell: isDark
          ? const Color(0xFF1B3D1B)
          : const Color(0xFFE8F5E9),
      highlightedCell: isDark
          ? const Color(0xFF1B3D1B).withOpacity(0.4)
          : const Color(0xFFE8F5E9).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C2A1A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF2E7D32)
          : const Color(0xFFC8E6C9),
      gridLineColor: isDark ? const Color(0xFF33691E) : const Color(0xFFA5D6A7),
      thickGridLineColor: isDark ? const Color(0xFF558B2F) : const Color(0xFF66BB6A),
      textColor: isDark ? const Color(0xFFC8E6C9) : const Color(0xFF2E7D32),
      hintTextColor: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF66BB6A),
    );
  }

  // 5. GALAXY THEME - Deep Purple
  static GameTheme _galaxyTheme(bool isDark) {
    return GameTheme(
      id: 'galaxy',
      name: 'Galaksi',
      selectedCell: isDark
          ? const Color(0xFF311B5C)
          : const Color(0xFFEDE7F6),
      highlightedCell: isDark
          ? const Color(0xFF311B5C).withOpacity(0.4)
          : const Color(0xFFEDE7F6).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A3D)
          : const Color(0xFFFCE4EC),
      completedCell: isDark
          ? const Color(0xFF4527A0)
          : const Color(0xFFD1C4E9),
      gridLineColor: isDark ? const Color(0xFF4A148C) : const Color(0xFFCE93D8),
      thickGridLineColor: isDark ? const Color(0xFF7B1FA2) : const Color(0xFFAB47BC),
      textColor: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF6A1B9A),
      hintTextColor: isDark ? const Color(0xFFCE93D8) : const Color(0xFF9C27B0),
    );
  }

  // 6. MIDNIGHT THEME - Dark Blue
  static GameTheme _midnightTheme(bool isDark) {
    return GameTheme(
      id: 'midnight',
      name: 'Gece Yarısı',
      selectedCell: isDark
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFE8EAF6),
      highlightedCell: isDark
          ? const Color(0xFF1B263B).withOpacity(0.6)
          : const Color(0xFFE8EAF6).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF4A1A1A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF1A237E)
          : const Color(0xFFC5CAE9),
      gridLineColor: isDark ? const Color(0xFF1B263B) : const Color(0xFFC5CAE9),
      thickGridLineColor: isDark ? const Color(0xFF415A77) : const Color(0xFF7986CB),
      textColor: isDark ? const Color(0xFFC5CAE9) : const Color(0xFF1A237E),
      hintTextColor: isDark ? const Color(0xFF9FA8DA) : const Color(0xFF5C6BC0),
    );
  }

  // 7. ROSE THEME - Soft Pink
  static GameTheme _roseTheme(bool isDark) {
    return GameTheme(
      id: 'rose',
      name: 'Gül',
      selectedCell: isDark
          ? const Color(0xFF4A1B36)
          : const Color(0xFFFCE4EC),
      highlightedCell: isDark
          ? const Color(0xFF4A1B36).withOpacity(0.4)
          : const Color(0xFFFCE4EC).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A1A)
          : const Color(0xFFFFCDD2),
      completedCell: isDark
          ? const Color(0xFF880E4F)
          : const Color(0xFFF8BBD9),
      gridLineColor: isDark ? const Color(0xFF6D1B4D) : const Color(0xFFF48FB1),
      thickGridLineColor: isDark ? const Color(0xFFC2185B) : const Color(0xFFEC407A),
      textColor: isDark ? const Color(0xFFF8BBD9) : const Color(0xFFC2185B),
      hintTextColor: isDark ? const Color(0xFFF48FB1) : const Color(0xFFEC407A),
    );
  }

  // 8. LAVENDER THEME - Light Purple
  static GameTheme _lavenderTheme(bool isDark) {
    return GameTheme(
      id: 'lavender',
      name: 'Lavanta',
      selectedCell: isDark
          ? const Color(0xFF3D2C5E)
          : const Color(0xFFF3E5F5),
      highlightedCell: isDark
          ? const Color(0xFF3D2C5E).withOpacity(0.4)
          : const Color(0xFFF3E5F5).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A2A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF5E35B1)
          : const Color(0xFFE1BEE7),
      gridLineColor: isDark ? const Color(0xFF512DA8) : const Color(0xFFCE93D8),
      thickGridLineColor: isDark ? const Color(0xFF7E57C2) : const Color(0xFFBA68C8),
      textColor: isDark ? const Color(0xFFE1BEE7) : const Color(0xFF7B1FA2),
      hintTextColor: isDark ? const Color(0xFFCE93D8) : const Color(0xFFAB47BC),
    );
  }

  // 9. EARTH THEME - Brown/Taupe
  static GameTheme _earthTheme(bool isDark) {
    return GameTheme(
      id: 'earth',
      name: 'Toprak',
      selectedCell: isDark
          ? const Color(0xFF3E2723)
          : const Color(0xFFEFEBE9),
      highlightedCell: isDark
          ? const Color(0xFF3E2723).withOpacity(0.4)
          : const Color(0xFFEFEBE9).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A1A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF5D4037)
          : const Color(0xFFD7CCC8),
      gridLineColor: isDark ? const Color(0xFF4E342E) : const Color(0xFFBCAAA4),
      thickGridLineColor: isDark ? const Color(0xFF6D4C41) : const Color(0xFF8D6E63),
      textColor: isDark ? const Color(0xFFD7CCC8) : const Color(0xFF4E342E),
      hintTextColor: isDark ? const Color(0xFFBCAAA4) : const Color(0xFF795548),
    );
  }

  // 10. MINT THEME - Fresh Mint Green
  static GameTheme _mintTheme(bool isDark) {
    return GameTheme(
      id: 'mint',
      name: 'Nane',
      selectedCell: isDark
          ? const Color(0xFF0D3D3D)
          : const Color(0xFFE0F7FA),
      highlightedCell: isDark
          ? const Color(0xFF0D3D3D).withOpacity(0.4)
          : const Color(0xFFE0F7FA).withOpacity(0.7),
      wrongCell: isDark
          ? const Color(0xFF5C1A1A)
          : const Color(0xFFFFEBEE),
      completedCell: isDark
          ? const Color(0xFF00695C)
          : const Color(0xFFB2EBF2),
      gridLineColor: isDark ? const Color(0xFF00796B) : const Color(0xFF80DEEA),
      thickGridLineColor: isDark ? const Color(0xFF00897B) : const Color(0xFF26C6DA),
      textColor: isDark ? const Color(0xFFB2EBF2) : const Color(0xFF00796B),
      hintTextColor: isDark ? const Color(0xFF80DEEA) : const Color(0xFF00ACC1),
    );
  }

  /// Get all available themes
  static List<String> getAllThemeIds() {
    return ['default', 'ocean', 'sunset', 'forest', 'galaxy', 'midnight', 'rose', 'lavender', 'earth', 'mint'];
  }
}

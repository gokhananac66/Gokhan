import 'package:shared_preferences/shared_preferences.dart';

class ProgressionService {
  static const String _winsPrefix = 'difficulty_wins_';

  /// Zorluk seviyelerinin kilitleme gereksinimleri
  static const Map<String, Map<String, dynamic>> unlockRequirements = {
    'Kolay': {'required': 0, 'previousLevel': null}, // Hep açık
    'Orta': {'required': 0, 'previousLevel': null}, // Hep açık
    'Zor': {'required': 0, 'previousLevel': null}, // Hep açık
    'Uzman': {'required': 4, 'previousLevel': 'Zor'}, // 4 Zor kazanması gerekli
    'Usta': {'required': 10, 'previousLevel': 'Uzman'}, // 10 Uzman kazanması gerekli
    'Ekstrem': {'required': 14, 'previousLevel': 'Usta'}, // 14 Usta kazanması gerekli
  };

  /// Belirli bir zorluk seviyesinde kazanılan oyun sayısını getir
  static Future<int> getWins(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_winsPrefix$difficulty') ?? 0;
  }

  /// Belirli bir zorluk seviyesinde kazanma sayısını artır
  static Future<void> incrementWins(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final currentWins = await getWins(difficulty);
    await prefs.setInt('$_winsPrefix$difficulty', currentWins + 1);
  }

  /// Belirli bir zorluk seviyesinin kilitli olup olmadığını kontrol et
  static Future<bool> isLocked(String difficulty) async {
    final requirements = unlockRequirements[difficulty];
    if (requirements == null || requirements['required'] == 0) {
      return false; // Gereksinim yok, açık
    }

    final previousLevel = requirements['previousLevel'] as String?;
    if (previousLevel == null) return false;

    final requiredWins = requirements['required'] as int;
    final actualWins = await getWins(previousLevel);

    return actualWins < requiredWins;
  }

  /// Kilidi açmak için kalan kazanma sayısını getir
  static Future<int> getRemainingWinsToUnlock(String difficulty) async {
    final requirements = unlockRequirements[difficulty];
    if (requirements == null || requirements['required'] == 0) {
      return 0;
    }

    final previousLevel = requirements['previousLevel'] as String?;
    if (previousLevel == null) return 0;

    final requiredWins = requirements['required'] as int;
    final actualWins = await getWins(previousLevel);
    final remaining = requiredWins - actualWins;

    return remaining > 0 ? remaining : 0;
  }

  /// Kilidi açmak için hangi seviyede kaç kazanma gerektiğini getir
  static Map<String, dynamic>? getUnlockInfo(String difficulty) {
    final requirements = unlockRequirements[difficulty];
    if (requirements == null || requirements['required'] == 0) {
      return null;
    }

    return {
      'previousLevel': requirements['previousLevel'],
      'requiredWins': requirements['required'],
    };
  }

  /// Tüm kazanma istatistiklerini getir
  static Future<Map<String, int>> getAllWins() async {
    final Map<String, int> allWins = {};
    for (final difficulty in unlockRequirements.keys) {
      allWins[difficulty] = await getWins(difficulty);
    }
    return allWins;
  }

  /// Test amaçlı - tüm progression'ı sıfırla
  static Future<void> resetProgression() async {
    final prefs = await SharedPreferences.getInstance();
    for (final difficulty in unlockRequirements.keys) {
      await prefs.remove('$_winsPrefix$difficulty');
    }
  }
}

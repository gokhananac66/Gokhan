/// Otomatik zorluk hesaplama servisi
class DifficultyCalculator {
  /// İki oyuncunun level'ına göre otomatik zorluk hesapla
  /// Kural: Ortalama level + 1 seviye daha zor
  static String calculateDifficulty(int player1Level, int player2Level) {
    final avgLevel = (player1Level + player2Level) / 2;

    // Level aralıklarına göre zorluk belirle
    String baseDifficulty;
    if (avgLevel < 5) {
      baseDifficulty = 'Kolay';
    } else if (avgLevel < 10) {
      baseDifficulty = 'Orta';
    } else if (avgLevel < 20) {
      baseDifficulty = 'Zor';
    } else if (avgLevel < 35) {
      baseDifficulty = 'Uzman';
    } else if (avgLevel < 50) {
      baseDifficulty = 'Usta';
    } else {
      baseDifficulty = 'Ekstrem';
    }

    // 1 seviye daha zor yap
    return _getNextDifficulty(baseDifficulty);
  }

  /// Bir sonraki zorluk seviyesini döndür
  static String _getNextDifficulty(String current) {
    switch (current) {
      case 'Kolay':
        return 'Orta';
      case 'Orta':
        return 'Zor';
      case 'Zor':
        return 'Uzman';
      case 'Uzman':
        return 'Usta';
      case 'Usta':
        return 'Ekstrem';
      case 'Ekstrem':
        return 'Ekstrem'; // Max zorluk
      default:
        return 'Orta';
    }
  }

  /// Level farkını kontrol et
  /// Arkadaşlar için: ±20
  /// Rastgele için: ±15
  static bool isLevelDifferenceAcceptable(int level1, int level2, {bool isFriend = true}) {
    final diff = (level1 - level2).abs();
    final maxDiff = isFriend ? 20 : 15;
    return diff <= maxDiff;
  }

  /// Level farkını hesapla
  static int getLevelDifference(int level1, int level2) {
    return (level1 - level2).abs();
  }
}

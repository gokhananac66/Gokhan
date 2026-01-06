import 'dart:math';

enum League {
  bronze,   // Level 1-20
  silver,   // Level 21-40
  gold,     // Level 41-60
  platinum, // Level 61-80
  diamond,  // Level 81-100
}

class PlayerRank {
  final int level;
  final League league;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final double winRate;
  final int currentStreak;
  final int bestStreak;

  // 25 oyunluk periyot için
  final int periodGames;    // Bu periyottaki oyun sayısı (0-25)
  final int periodWins;     // Bu periyottaki galibiyet

  PlayerRank({
    required this.level,
    required this.league,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.periodGames,
    required this.periodWins,
  });

  factory PlayerRank.initial() {
    return PlayerRank(
      level: 1,
      league: League.bronze,
      gamesPlayed: 0,
      wins: 0,
      losses: 0,
      winRate: 0.0,
      currentStreak: 0,
      bestStreak: 0,
      periodGames: 0,
      periodWins: 0,
    );
  }

  factory PlayerRank.fromMap(Map<String, dynamic> map) {
    final level = map['level'] ?? 1;
    return PlayerRank(
      level: level,
      league: _getLeagueFromLevel(level),
      gamesPlayed: map['gamesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      winRate: (map['winRate'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      periodGames: map['periodGames'] ?? 0,
      periodWins: map['periodWins'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'league': league.name,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'winRate': winRate,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'periodGames': periodGames,
      'periodWins': periodWins,
    };
  }

  static League _getLeagueFromLevel(int level) {
    if (level <= 20) return League.bronze;
    if (level <= 40) return League.silver;
    if (level <= 60) return League.gold;
    if (level <= 80) return League.platinum;
    return League.diamond;
  }

  String get leagueName {
    switch (league) {
      case League.bronze:
        return 'Bronz';
      case League.silver:
        return 'Gümüş';
      case League.gold:
        return 'Altın';
      case League.platinum:
        return 'Platin';
      case League.diamond:
        return 'Elmas';
    }
  }

  String get leagueNameEn {
    switch (league) {
      case League.bronze:
        return 'Bronze';
      case League.silver:
        return 'Silver';
      case League.gold:
        return 'Gold';
      case League.platinum:
        return 'Platinum';
      case League.diamond:
        return 'Diamond';
    }
  }

  String get leagueEmoji {
    switch (league) {
      case League.bronze:
        return '🥉';
      case League.silver:
        return '🥈';
      case League.gold:
        return '🥇';
      case League.platinum:
        return '💎';
      case League.diamond:
        return '👑';
    }
  }

  int get leagueColor {
    switch (league) {
      case League.bronze:
        return 0xFFCD7F32;
      case League.silver:
        return 0xFFC0C0C0;
      case League.gold:
        return 0xFFFFD700;
      case League.platinum:
        return 0xFF00CED1;
      case League.diamond:
        return 0xFF9400D3;
    }
  }

  // Bir sonraki lige kaç level kaldı
  int get levelsToNextLeague {
    if (level >= 81) return 0;

    int nextLeagueStart;
    if (level <= 20) nextLeagueStart = 21;
    else if (level <= 40) nextLeagueStart = 41;
    else if (level <= 60) nextLeagueStart = 61;
    else nextLeagueStart = 81;

    return nextLeagueStart - level;
  }

  // Bu periyotta kaç oyun kaldı
  int get gamesRemainingInPeriod => 25 - periodGames;

  // Bu periyottaki win rate
  double get periodWinRate => periodGames > 0 ? periodWins / periodGames : 0.0;
}

class RankCalculator {
  static const int PERIOD_SIZE = 25; // Her 25 oyunda değerlendirme

  /// Oyun sonrası rank değişimini hesapla
  static RankChange calculateRankChange({
    required PlayerRank myRank,
    required bool won,
  }) {
    // Yeni değerleri hesapla
    final newGamesPlayed = myRank.gamesPlayed + 1;
    final newWins = won ? myRank.wins + 1 : myRank.wins;
    final newLosses = won ? myRank.losses : myRank.losses + 1;
    final newWinRate = newWins / newGamesPlayed;

    // Streak hesapla
    int newStreak;
    int newBestStreak;
    if (won) {
      newStreak = myRank.currentStreak > 0 ? myRank.currentStreak + 1 : 1;
      newBestStreak = newStreak > myRank.bestStreak ? newStreak : myRank.bestStreak;
    } else {
      newStreak = myRank.currentStreak < 0 ? myRank.currentStreak - 1 : -1;
      newBestStreak = myRank.bestStreak;
    }

    // Periyot güncelle
    int newPeriodGames = myRank.periodGames + 1;
    int newPeriodWins = won ? myRank.periodWins + 1 : myRank.periodWins;
    int newLevel = myRank.level;
    int levelChange = 0;

    // 25 oyun tamamlandı mı?
    if (newPeriodGames >= PERIOD_SIZE) {
      final periodWinRate = newPeriodWins / PERIOD_SIZE;

      // Win rate'e göre level değişimi
      if (periodWinRate >= 0.75) {
        levelChange = 2;  // %75+ → +2 level
      } else if (periodWinRate >= 0.60) {
        levelChange = 1;  // %60-74% → +1 level
      } else if (periodWinRate >= 0.40) {
        levelChange = 0;  // %40-59% → Sabit
      } else if (periodWinRate >= 0.25) {
        levelChange = -1; // %25-39% → -1 level
      } else {
        levelChange = -2; // %25 altı → -2 level
      }

      newLevel = (myRank.level + levelChange).clamp(1, 100);

      // Periyodu sıfırla
      newPeriodGames = 0;
      newPeriodWins = 0;
    }

    final newLeague = PlayerRank._getLeagueFromLevel(newLevel);

    return RankChange(
      oldRank: myRank,
      newRank: PlayerRank(
        level: newLevel,
        league: newLeague,
        gamesPlayed: newGamesPlayed,
        wins: newWins,
        losses: newLosses,
        winRate: newWinRate,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
        periodGames: newPeriodGames,
        periodWins: newPeriodWins,
      ),
      levelChange: levelChange,
      leagueChanged: newLeague != myRank.league,
      periodCompleted: myRank.periodGames + 1 >= PERIOD_SIZE,
    );
  }

  /// Lig bazlı matchmaking aralığı
  static League getLeagueFromLevel(int level) {
    return PlayerRank._getLeagueFromLevel(level);
  }

  /// Matchmaking için uygun ligleri döndür
  static List<League> getMatchmakingLeagues(League myLeague, int waitTimeSeconds) {
    List<League> leagues = [myLeague];

    // 30 saniyeden sonra komşu ligleri ekle
    if (waitTimeSeconds >= 30) {
      final myIndex = myLeague.index;
      if (myIndex > 0) {
        leagues.add(League.values[myIndex - 1]); // Alt lig
      }
      if (myIndex < League.values.length - 1) {
        leagues.add(League.values[myIndex + 1]); // Üst lig
      }
    }

    // 60 saniyeden sonra 2 komşu lig
    if (waitTimeSeconds >= 60) {
      final myIndex = myLeague.index;
      if (myIndex > 1) {
        leagues.add(League.values[myIndex - 2]);
      }
      if (myIndex < League.values.length - 2) {
        leagues.add(League.values[myIndex + 2]);
      }
    }

    return leagues.toSet().toList(); // Tekrarları kaldır
  }

  /// Lig ismini döndür (Firebase path için)
  static String getLeagueKey(League league) {
    return league.name; // bronze, silver, gold, platinum, diamond
  }
}

class RankChange {
  final PlayerRank oldRank;
  final PlayerRank newRank;
  final int levelChange;
  final bool leagueChanged;
  final bool periodCompleted;

  RankChange({
    required this.oldRank,
    required this.newRank,
    required this.levelChange,
    required this.leagueChanged,
    required this.periodCompleted,
  });

  bool get leveledUp => levelChange > 0;
  bool get leveledDown => levelChange < 0;
  bool get promoted => leagueChanged && newRank.league.index > oldRank.league.index;
  bool get demoted => leagueChanged && newRank.league.index < oldRank.league.index;
}
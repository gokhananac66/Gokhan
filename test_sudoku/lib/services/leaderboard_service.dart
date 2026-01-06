import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_rank.dart';

class LeaderboardService {
  static final _database = FirebaseDatabase.instance.ref();
  static final _auth = FirebaseAuth.instance;

  /// Multiplayer oyun sonucu kaydet ve rank güncelle
  static Future<RankChange?> submitGameResult({
    required bool won,
    required int scoreEarned,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('nickname') ?? user.displayName ?? 'Anonim';
    final avatar = prefs.getInt('avatarIndex') ?? 0;
    final country = prefs.getString('country') ?? '🇹🇷 Türkiye';
    final String odaId = user.uid;

    // Mevcut rank'ı al
    final rankSnapshot = await _database.child('users/$odaId/rank').get();
    PlayerRank currentRank;

    if (rankSnapshot.exists) {
      currentRank = PlayerRank.fromMap(Map<String, dynamic>.from(rankSnapshot.value as Map));
    } else {
      currentRank = PlayerRank.initial();
    }

    // Yeni rank hesapla
    final rankChange = RankCalculator.calculateRankChange(
      myRank: currentRank,
      won: won,
    );

    // Rank'ı kaydet
    await _database.child('users/$odaId/rank').set(rankChange.newRank.toMap());

    // Leaderboard güncelle
    await _updateLeaderboard(
      odaId: odaId,
      nickname: nickname,
      avatar: avatar,
      country: country,
      rank: rankChange.newRank,
      scoreEarned: won ? scoreEarned : 0,
      won: won,
    );

    return rankChange;
  }

  /// Leaderboard güncelle
  static Future<void> _updateLeaderboard({
    required String odaId,
    required String nickname,
    required int avatar,
    required String country,
    required PlayerRank rank,
    required int scoreEarned,
    required bool won,
  }) async {
    // Mevcut leaderboard verisi
    final snapshot = await _database.child('leaderboard/multiplayer/$odaId').get();

    int currentTotalScore = 0;
    int currentWins = 0;
    int currentLosses = 0;

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      currentTotalScore = data['totalScore'] ?? 0;
      currentWins = data['wins'] ?? 0;
      currentLosses = data['losses'] ?? 0;
    }

    // Tüm zamanlara kaydet
    await _database.child('leaderboard/multiplayer/$odaId').set({
      'odaId': odaId,
      'nickname': nickname,
      'totalScore': currentTotalScore + scoreEarned,
      'wins': won ? currentWins + 1 : currentWins,
      'losses': won ? currentLosses : currentLosses + 1,
      'winRate': rank.winRate,
      'level': rank.level,
      'league': rank.league.name,
      'avatar': avatar,
      'country': country,
      'lastUpdated': ServerValue.timestamp,
    });

    // Günlük leaderboard
    String todayKey = _getTodayKey();
    final todaySnapshot = await _database.child('leaderboard/daily/$todayKey/$odaId').get();

    int todayScore = 0;
    int todayWins = 0;
    int todayLosses = 0;

    if (todaySnapshot.exists) {
      final data = Map<String, dynamic>.from(todaySnapshot.value as Map);
      todayScore = data['totalScore'] ?? 0;
      todayWins = data['wins'] ?? 0;
      todayLosses = data['losses'] ?? 0;
    }

    await _database.child('leaderboard/daily/$todayKey/$odaId').set({
      'odaId': odaId,
      'nickname': nickname,
      'totalScore': todayScore + scoreEarned,
      'wins': won ? todayWins + 1 : todayWins,
      'losses': won ? todayLosses : todayLosses + 1,
      'level': rank.level,
      'league': rank.league.name,
      'avatar': avatar,
      'country': country,
      'lastUpdated': ServerValue.timestamp,
    });

    // Haftalık leaderboard
    String weekKey = _getWeekKey();
    final weekSnapshot = await _database.child('leaderboard/weekly/$weekKey/$odaId').get();

    int weekScore = 0;
    int weekWins = 0;
    int weekLosses = 0;

    if (weekSnapshot.exists) {
      final data = Map<String, dynamic>.from(weekSnapshot.value as Map);
      weekScore = data['totalScore'] ?? 0;
      weekWins = data['wins'] ?? 0;
      weekLosses = data['losses'] ?? 0;
    }

    await _database.child('leaderboard/weekly/$weekKey/$odaId').set({
      'odaId': odaId,
      'nickname': nickname,
      'totalScore': weekScore + scoreEarned,
      'wins': won ? weekWins + 1 : weekWins,
      'losses': won ? weekLosses : weekLosses + 1,
      'level': rank.level,
      'league': rank.league.name,
      'avatar': avatar,
      'country': country,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  /// Eski submitMultiplayerWin - geriye uyumluluk için
  static Future<void> submitMultiplayerWin({required int scoreEarned}) async {
    await submitGameResult(won: true, scoreEarned: scoreEarned);
  }

  /// Liderlik tablosunu getir (lig filtreli)
  static Future<List<Map<String, dynamic>>> getLeaderboard(
      String timeFilter, {
        String? leagueFilter, // null = tüm ligler, 'bronze', 'silver', etc.
      }) async {
    String path;

    switch (timeFilter) {
      case 'today':
        path = 'leaderboard/daily/${_getTodayKey()}';
        break;
      case 'week':
        path = 'leaderboard/weekly/${_getWeekKey()}';
        break;
      case 'all':
      default:
        path = 'leaderboard/multiplayer';
        break;
    }

    final snapshot = await _database
        .child(path)
        .orderByChild('level')
        .limitToLast(100)
        .get();

    if (!snapshot.exists) return [];

    List<Map<String, dynamic>> scores = [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((odaId, value) {
      if (value is Map) {
        final entry = {
          'odaId': odaId,
          ...Map<String, dynamic>.from(value),
        };

        // Lig filtresi uygula
        if (leagueFilter == null || entry['league'] == leagueFilter) {
          scores.add(entry);
        }
      }
    });

    // Sıralama: Level > WinRate > TotalScore
    scores.sort((a, b) {
      // Önce level'a göre
      int levelCompare = (b['level'] ?? 0).compareTo(a['level'] ?? 0);
      if (levelCompare != 0) return levelCompare;

      // Sonra winRate'e göre
      double aWinRate = (a['winRate'] ?? 0.0).toDouble();
      double bWinRate = (b['winRate'] ?? 0.0).toDouble();
      int winRateCompare = bWinRate.compareTo(aWinRate);
      if (winRateCompare != 0) return winRateCompare;

      // Son olarak toplam puana göre
      return (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0);
    });

    return scores;
  }

  /// Kullanıcının sıralamasını getir
  static Future<int?> getUserRank(String timeFilter, {String? leagueFilter}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final scores = await getLeaderboard(timeFilter, leagueFilter: leagueFilter);

    for (int i = 0; i < scores.length; i++) {
      if (scores[i]['odaId'] == user.uid) {
        return i + 1;
      }
    }

    return null;
  }

  /// Kullanıcının rank bilgisini getir
  static Future<PlayerRank?> getUserRankInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _database.child('users/${user.uid}/rank').get();

    if (!snapshot.exists) return PlayerRank.initial();

    return PlayerRank.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  /// Kullanıcının istatistiklerini getir
  static Future<Map<String, dynamic>?> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _database.child('leaderboard/multiplayer/${user.uid}').get();

    if (!snapshot.exists) return null;

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _getWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysDiff = now.difference(startOfYear).inDays;
    final weekNumber = (daysDiff / 7).ceil();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
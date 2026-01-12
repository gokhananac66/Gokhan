import 'dart:async';
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
    String gameMode = 'classic', // 'classic' or 'race'
    int? gameTimeSeconds, // For race mode - fastest win tracking
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final String odaId = user.uid;

    // Firebase'den kullanıcı profilini al (nickname, avatar, country)
    String nickname = 'Anonim';
    int avatar = 0;
    String country = '🇹🇷 Türkiye';

    try {
      final profileSnapshot = await _database.child('users/$odaId/profile').get();
      if (profileSnapshot.exists) {
        final profileData = Map<String, dynamic>.from(profileSnapshot.value as Map);
        nickname = profileData['nickname'] ?? nickname;
        avatar = profileData['selectedAvatar'] ?? avatar;
        country = profileData['country'] ?? country;
      } else {
        // Fallback: SharedPreferences (eski kullanıcılar için)
        final prefs = await SharedPreferences.getInstance();
        nickname = prefs.getString('nickname') ?? user.displayName ?? 'Anonim';
        avatar = prefs.getInt('avatarIndex') ?? 0;
        country = prefs.getString('country') ?? '🇹🇷 Türkiye';
      }
    } catch (e) {
      print('⚠️ Failed to fetch profile from Firebase: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      nickname = prefs.getString('nickname') ?? user.displayName ?? 'Anonim';
      avatar = prefs.getInt('avatarIndex') ?? 0;
      country = prefs.getString('country') ?? '🇹🇷 Türkiye';
    }

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

    // Mode-based stats güncelle
    await _updateModeBasedStats(
      odaId: odaId,
      nickname: nickname,
      avatar: avatar,
      country: country,
      gameMode: gameMode,
      won: won,
      scoreEarned: won ? scoreEarned : 0,
      gameTimeSeconds: gameTimeSeconds,
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
    int currentGamesPlayed = 0;

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      currentTotalScore = data['totalScore'] ?? 0;
      currentWins = data['wins'] ?? 0;
      currentLosses = data['losses'] ?? 0;
      currentGamesPlayed = data['gamesPlayed'] ?? 0;
    }

    // Tüm zamanlara kaydet
    await _database.child('leaderboard/multiplayer/$odaId').set({
      'odaId': odaId,
      'nickname': nickname,
      'totalScore': currentTotalScore + scoreEarned,
      'wins': won ? currentWins + 1 : currentWins,
      'losses': won ? currentLosses : currentLosses + 1,
      'gamesPlayed': currentGamesPlayed + 1,
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
    print('🔍 [LEADERBOARD_SERVICE] getLeaderboard called with timeFilter: $timeFilter, leagueFilter: $leagueFilter');

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

    print('🔍 [LEADERBOARD_SERVICE] Fetching from path: $path');

    try {
      final snapshot = await _database
          .child(path)
          .orderByChild('level')
          .limitToLast(100)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏱️ [LEADERBOARD_SERVICE] TIMEOUT after 15 seconds!');
              throw TimeoutException('Firebase leaderboard query timeout');
            },
          );

      print('🔍 [LEADERBOARD_SERVICE] Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        print('📭 [LEADERBOARD_SERVICE] No leaderboard data found');
        return [];
      }

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

      // Sıralama: TotalScore > WinRate > Wins
      scores.sort((a, b) {
        // 1. Önce PUAN'a bak (en önemli metrik)
        int scoreCompare = (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0);
        if (scoreCompare != 0) return scoreCompare;

        // 2. Eşitlik durumunda WinRate'e bak (kalite göstergesi)
        double aWinRate = (a['winRate'] ?? 0.0).toDouble();
        double bWinRate = (b['winRate'] ?? 0.0).toDouble();
        int winRateCompare = bWinRate.compareTo(aWinRate);
        if (winRateCompare != 0) return winRateCompare;

        // 3. Son olarak toplam kazanma sayısına bak
        return (b['wins'] ?? 0).compareTo(a['wins'] ?? 0);
      });

      print('✅ [LEADERBOARD_SERVICE] Returning ${scores.length} scores');
      return scores;
    } catch (e, stackTrace) {
      print('❌ [LEADERBOARD_SERVICE] Error in getLeaderboard: $e');
      print('❌ [LEADERBOARD_SERVICE] Stack trace: $stackTrace');
      return [];
    }
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
    print('🔍 [LEADERBOARD_SERVICE] getUserStats called');

    final user = _auth.currentUser;
    print('🔍 [LEADERBOARD_SERVICE] Current user: ${user?.uid}');

    if (user == null) {
      print('⚠️ [LEADERBOARD_SERVICE] No user logged in');
      return null;
    }

    try {
      print('🔍 [LEADERBOARD_SERVICE] Fetching from path: leaderboard/multiplayer/${user.uid}');

      final snapshot = await _database
          .child('leaderboard/multiplayer/${user.uid}')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [LEADERBOARD_SERVICE] TIMEOUT after 10 seconds!');
              throw TimeoutException('Firebase query timeout');
            },
          );

      print('🔍 [LEADERBOARD_SERVICE] Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        print('📭 [LEADERBOARD_SERVICE] No overall stats found');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      print('✅ [LEADERBOARD_SERVICE] Got overall stats: $data');
      return data;
    } catch (e, stackTrace) {
      print('❌ [LEADERBOARD_SERVICE] Error in getUserStats: $e');
      print('❌ [LEADERBOARD_SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mode-based istatistikleri güncelle
  static Future<void> _updateModeBasedStats({
    required String odaId,
    required String nickname,
    required int avatar,
    required String country,
    required String gameMode,
    required bool won,
    required int scoreEarned,
    int? gameTimeSeconds,
  }) async {
    final statsPath = 'users/$odaId/stats/$gameMode';
    final snapshot = await _database.child(statsPath).get();

    int gamesPlayed = 0;
    int wins = 0;
    int totalScore = 0;
    int? fastestWin;

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      gamesPlayed = data['gamesPlayed'] ?? 0;
      wins = data['wins'] ?? 0;
      totalScore = data['totalScore'] ?? 0;
      fastestWin = data['fastestWin'];
    }

    gamesPlayed++;
    if (won) wins++;
    totalScore += scoreEarned;

    // Race mode için en hızlı kazanmayı kaydet
    if (gameMode == 'race' && won && gameTimeSeconds != null) {
      if (fastestWin == null || gameTimeSeconds < fastestWin) {
        fastestWin = gameTimeSeconds;
      }
    }

    final winRate = gamesPlayed > 0 ? (wins / gamesPlayed * 100).toStringAsFixed(1) : '0.0';

    Map<String, dynamic> updates = {
      'odaId': odaId,
      'nickname': nickname,
      'avatar': avatar,
      'country': country,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'winRate': winRate,
      'totalScore': totalScore,
      'lastUpdated': ServerValue.timestamp,
    };

    if (gameMode == 'race' && fastestWin != null) {
      updates['fastestWin'] = fastestWin;
    }

    await _database.child(statsPath).set(updates);
  }

  /// Kullanıcının mode-based istatistiklerini getir
  static Future<Map<String, dynamic>?> getUserModeStats(String gameMode) async {
    print('🔍 [LEADERBOARD_SERVICE] getUserModeStats called for mode: $gameMode');

    final user = _auth.currentUser;
    print('🔍 [LEADERBOARD_SERVICE] Current user: ${user?.uid}');

    if (user == null) {
      print('⚠️ [LEADERBOARD_SERVICE] No user logged in');
      return null;
    }

    try {
      print('🔍 [LEADERBOARD_SERVICE] Fetching from path: users/${user.uid}/stats/$gameMode');

      final snapshot = await _database
          .child('users/${user.uid}/stats/$gameMode')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [LEADERBOARD_SERVICE] TIMEOUT after 10 seconds!');
              throw TimeoutException('Firebase query timeout');
            },
          );

      print('🔍 [LEADERBOARD_SERVICE] Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        print('📭 [LEADERBOARD_SERVICE] No data found for $gameMode');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      print('✅ [LEADERBOARD_SERVICE] Got data: $data');
      return data;
    } catch (e, stackTrace) {
      print('❌ [LEADERBOARD_SERVICE] Error in getUserModeStats: $e');
      print('❌ [LEADERBOARD_SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mod bazlı leaderboard getir
  static Future<List<Map<String, dynamic>>> getModeLeaderboard(String gameMode, String timeFilter) async {
    print('🔍 [LEADERBOARD_SERVICE] getModeLeaderboard called for mode: $gameMode, timeFilter: $timeFilter');

    try {
      // User stats'leri çek - artık nickname de stats içinde!
      print('🔍 [LEADERBOARD_SERVICE] Fetching ALL users from Firebase...');

      final usersSnapshot = await _database
          .child('users')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              print('⏱️ [LEADERBOARD_SERVICE] TIMEOUT fetching users after 20 seconds!');
              throw TimeoutException('Firebase users query timeout');
            },
          );

      print('🔍 [LEADERBOARD_SERVICE] Users snapshot exists: ${usersSnapshot.exists}');

      if (!usersSnapshot.exists) {
        print('📭 [LEADERBOARD_SERVICE] No users found');
        return [];
      }

      List<Map<String, dynamic>> scores = [];
      final usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
      print('🔍 [LEADERBOARD_SERVICE] Found ${usersData.length} users');

      // Leaderboard verisi (league bilgisi için)
      print('🔍 [LEADERBOARD_SERVICE] Fetching ALL leaderboard data...');

      final leaderboardSnapshot = await _database
          .child('leaderboard/multiplayer')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              print('⏱️ [LEADERBOARD_SERVICE] TIMEOUT fetching leaderboard after 20 seconds!');
              throw TimeoutException('Firebase leaderboard query timeout');
            },
          );

      Map<String, dynamic> allLeaderboardData = {};
      if (leaderboardSnapshot.exists) {
        allLeaderboardData = Map<String, dynamic>.from(leaderboardSnapshot.value as Map);
        print('🔍 [LEADERBOARD_SERVICE] Found ${allLeaderboardData.length} leaderboard entries');
      }

      // Her kullanıcı için stats'leri oku
      print('🔍 [LEADERBOARD_SERVICE] Processing user stats for mode: $gameMode');

      for (var entry in usersData.entries) {
        final uid = entry.key;
        final userData = Map<String, dynamic>.from(entry.value as Map);

        if (userData['stats'] != null) {
          final stats = Map<String, dynamic>.from(userData['stats'] as Map);

          if (stats[gameMode] != null) {
            final modeStats = Map<String, dynamic>.from(stats[gameMode] as Map);

            // Nickname artık modeStats içinde! (yeni kayıtlar için)
            String nickname = modeStats['nickname'] ?? 'Anonim';
            int avatar = modeStats['avatar'] ?? 0;
            String country = modeStats['country'] ?? '🇹🇷';

            // League bilgisi için leaderboard'a bak
            String league = 'bronze';
            if (allLeaderboardData.containsKey(uid)) {
              final userLeaderboard = Map<String, dynamic>.from(allLeaderboardData[uid] as Map);
              league = userLeaderboard['league'] ?? 'bronze';
            }

            scores.add({
              'odaId': uid,
              'nickname': nickname,
              'avatar': avatar,
              'country': country,
              'league': league,
              'gamesPlayed': modeStats['gamesPlayed'] ?? 0,
              'wins': modeStats['wins'] ?? 0,
              'winRate': modeStats['winRate'] ?? '0.0',
              'totalScore': modeStats['totalScore'] ?? 0,
              'fastestWin': modeStats['fastestWin'],
            });
          }
        }
      }

      print('🔍 [LEADERBOARD_SERVICE] Found ${scores.length} players for $gameMode mode');

      // Sıralama: TotalScore > WinRate > Wins
      scores.sort((a, b) {
        // 1. Önce PUAN'a bak (en önemli metrik)
        int scoreCompare = (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0);
        if (scoreCompare != 0) return scoreCompare;

        // 2. Eşitlik durumunda WinRate'e bak (kalite göstergesi)
        double aWinRate = double.tryParse(a['winRate']?.toString() ?? '0') ?? 0.0;
        double bWinRate = double.tryParse(b['winRate']?.toString() ?? '0') ?? 0.0;
        int winRateCompare = bWinRate.compareTo(aWinRate);
        if (winRateCompare != 0) return winRateCompare;

        // 3. Son olarak toplam kazanma sayısına bak
        return (b['wins'] ?? 0).compareTo(a['wins'] ?? 0);
      });

      final result = scores.take(100).toList();
      print('✅ [LEADERBOARD_SERVICE] Returning top ${result.length} scores for $gameMode');
      return result;
    } catch (e, stackTrace) {
      print('❌ [LEADERBOARD_SERVICE] Error in getModeLeaderboard: $e');
      print('❌ [LEADERBOARD_SERVICE] Stack trace: $stackTrace');
      return [];
    }
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Service for tracking and managing player achievements
/// Includes various achievement categories and automatic tracking
class AchievementService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Achievement categories and definitions
  static final Map<String, Achievement> achievements = {
    // 🎮 Game Completion Achievements
    'first_win': Achievement(
      id: 'first_win',
      name: {'tr': 'İlk Zafer', 'en': 'First Victory'},
      description: {'tr': 'İlk multiplayer oyununu kazan', 'en': 'Win your first multiplayer game'},
      category: AchievementCategory.games,
      icon: '🏆',
      points: 10,
      rarity: AchievementRarity.common,
    ),
    'speedster': Achievement(
      id: 'speedster',
      name: {'tr': 'Hız Canavarı', 'en': 'Speedster'},
      description: {'tr': '3 dakikadan kısa sürede bir oyun kazan', 'en': 'Win a game in under 3 minutes'},
      category: AchievementCategory.games,
      icon: '⚡',
      points: 25,
      rarity: AchievementRarity.rare,
    ),
    'perfectionist': Achievement(
      id: 'perfectionist',
      name: {'tr': 'Mükemmeliyetçi', 'en': 'Perfectionist'},
      description: {'tr': 'Hiç hata yapmadan bir oyun kazan', 'en': 'Win a game without any errors'},
      category: AchievementCategory.games,
      icon: '💯',
      points: 50,
      rarity: AchievementRarity.epic,
    ),

    // 🔥 Streak Achievements
    'hot_streak': Achievement(
      id: 'hot_streak',
      name: {'tr': 'Ateş Gibi', 'en': 'Hot Streak'},
      description: {'tr': '3 galibiyet serisi yap', 'en': 'Get a 3-win streak'},
      category: AchievementCategory.streaks,
      icon: '🔥',
      points: 20,
      rarity: AchievementRarity.uncommon,
    ),
    'unstoppable': Achievement(
      id: 'unstoppable',
      name: {'tr': 'Durdurulamaz', 'en': 'Unstoppable'},
      description: {'tr': '10 galibiyet serisi yap', 'en': 'Get a 10-win streak'},
      category: AchievementCategory.streaks,
      icon: '💎',
      points: 100,
      rarity: AchievementRarity.legendary,
    ),
    'daily_grind': Achievement(
      id: 'daily_grind',
      name: {'tr': 'Günlük Rutin', 'en': 'Daily Grind'},
      description: {'tr': '7 gün üst üste giriş yap', 'en': 'Login for 7 consecutive days'},
      category: AchievementCategory.streaks,
      icon: '📅',
      points: 30,
      rarity: AchievementRarity.rare,
    ),

    // 🎯 Challenge Achievements
    'challenge_master': Achievement(
      id: 'challenge_master',
      name: {'tr': 'Meydan Okuma Ustası', 'en': 'Challenge Master'},
      description: {'tr': '10 günlük meydan okuma tamamla', 'en': 'Complete 10 daily challenges'},
      category: AchievementCategory.challenges,
      icon: '🎯',
      points: 50,
      rarity: AchievementRarity.rare,
    ),
    'expert_challenger': Achievement(
      id: 'expert_challenger',
      name: {'tr': 'Uzman Meydan Okuyucu', 'en': 'Expert Challenger'},
      description: {'tr': 'Uzman zorlukta bir günlük meydan okuma kazan', 'en': 'Complete an expert daily challenge'},
      category: AchievementCategory.challenges,
      icon: '⭐',
      points: 75,
      rarity: AchievementRarity.epic,
    ),

    // 👥 Social Achievements
    'friendly': Achievement(
      id: 'friendly',
      name: {'tr': 'Sosyal Kelebek', 'en': 'Friendly'},
      description: {'tr': '5 arkadaş ekle', 'en': 'Add 5 friends'},
      category: AchievementCategory.social,
      icon: '👥',
      points: 15,
      rarity: AchievementRarity.common,
    ),
    'rematch_king': Achievement(
      id: 'rematch_king',
      name: {'tr': 'Revanche Kralı', 'en': 'Rematch King'},
      description: {'tr': '10 revanche daveti gönder', 'en': 'Send 10 rematch invites'},
      category: AchievementCategory.social,
      icon: '🔄',
      points: 25,
      rarity: AchievementRarity.uncommon,
    ),

    // 📊 Stats Achievements
    'century': Achievement(
      id: 'century',
      name: {'tr': 'Yüzüncü Oyun', 'en': 'Century'},
      description: {'tr': '100 multiplayer oyun oyna', 'en': 'Play 100 multiplayer games'},
      category: AchievementCategory.stats,
      icon: '💯',
      points: 50,
      rarity: AchievementRarity.rare,
    ),
    'veteran': Achievement(
      id: 'veteran',
      name: {'tr': 'Veteran', 'en': 'Veteran'},
      description: {'tr': '50 galibiyet kazan', 'en': 'Win 50 games'},
      category: AchievementCategory.stats,
      icon: '🎖️',
      points: 100,
      rarity: AchievementRarity.epic,
    ),
    'champion': Achievement(
      id: 'champion',
      name: {'tr': 'Şampiyon', 'en': 'Champion'},
      description: {'tr': '100 galibiyet kazan', 'en': 'Win 100 games'},
      category: AchievementCategory.stats,
      icon: '👑',
      points: 250,
      rarity: AchievementRarity.legendary,
    ),
  };

  /// Check and unlock achievements based on game results
  Future<List<Achievement>> checkGameAchievements({
    required bool isWin,
    required int gameTimeSeconds,
    required int errorCount,
    required int currentWinStreak,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Achievement> newlyUnlocked = [];

    try {
      // First win
      if (isWin && !await isUnlocked('first_win')) {
        await _unlockAchievement('first_win');
        newlyUnlocked.add(achievements['first_win']!);
      }

      // Speedster (under 3 minutes)
      if (isWin && gameTimeSeconds < 180 && !await isUnlocked('speedster')) {
        await _unlockAchievement('speedster');
        newlyUnlocked.add(achievements['speedster']!);
      }

      // Perfectionist (no errors)
      if (isWin && errorCount == 0 && !await isUnlocked('perfectionist')) {
        await _unlockAchievement('perfectionist');
        newlyUnlocked.add(achievements['perfectionist']!);
      }

      // Streak achievements
      if (currentWinStreak >= 3 && !await isUnlocked('hot_streak')) {
        await _unlockAchievement('hot_streak');
        newlyUnlocked.add(achievements['hot_streak']!);
      }

      if (currentWinStreak >= 10 && !await isUnlocked('unstoppable')) {
        await _unlockAchievement('unstoppable');
        newlyUnlocked.add(achievements['unstoppable']!);
      }

      return newlyUnlocked;
    } catch (e) {
      print('❌ [AchievementService] Error checking achievements: $e');
      return [];
    }
  }

  /// Check daily login streak achievements
  Future<List<Achievement>> checkLoginAchievements(int loginStreak) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Achievement> newlyUnlocked = [];

    try {
      if (loginStreak >= 7 && !await isUnlocked('daily_grind')) {
        await _unlockAchievement('daily_grind');
        newlyUnlocked.add(achievements['daily_grind']!);
      }

      return newlyUnlocked;
    } catch (e) {
      print('❌ [AchievementService] Error checking login achievements: $e');
      return [];
    }
  }

  /// Check daily challenge achievements
  Future<List<Achievement>> checkChallengeAchievements(int totalCompleted, String difficulty) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Achievement> newlyUnlocked = [];

    try {
      if (totalCompleted >= 10 && !await isUnlocked('challenge_master')) {
        await _unlockAchievement('challenge_master');
        newlyUnlocked.add(achievements['challenge_master']!);
      }

      if (difficulty == 'expert' && !await isUnlocked('expert_challenger')) {
        await _unlockAchievement('expert_challenger');
        newlyUnlocked.add(achievements['expert_challenger']!);
      }

      return newlyUnlocked;
    } catch (e) {
      print('❌ [AchievementService] Error checking challenge achievements: $e');
      return [];
    }
  }

  /// Check stats-based achievements
  Future<List<Achievement>> checkStatsAchievements(int totalGames, int totalWins) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Achievement> newlyUnlocked = [];

    try {
      if (totalGames >= 100 && !await isUnlocked('century')) {
        await _unlockAchievement('century');
        newlyUnlocked.add(achievements['century']!);
      }

      if (totalWins >= 50 && !await isUnlocked('veteran')) {
        await _unlockAchievement('veteran');
        newlyUnlocked.add(achievements['veteran']!);
      }

      if (totalWins >= 100 && !await isUnlocked('champion')) {
        await _unlockAchievement('champion');
        newlyUnlocked.add(achievements['champion']!);
      }

      return newlyUnlocked;
    } catch (e) {
      print('❌ [AchievementService] Error checking stats achievements: $e');
      return [];
    }
  }

  /// Unlock an achievement
  Future<void> _unlockAchievement(String achievementId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final achievement = achievements[achievementId];
    if (achievement == null) return;

    try {
      await _database
          .child('users/${currentUser.uid}/achievements/$achievementId')
          .set({
        'unlockedAt': DateTime.now().millisecondsSinceEpoch,
        'points': achievement.points,
      });

      // Add achievement points to total
      await _database
          .child('users/${currentUser.uid}/achievement_points')
          .set(ServerValue.increment(achievement.points));

      print('🏆 [AchievementService] Achievement unlocked: $achievementId (+${achievement.points} points)');
    } catch (e) {
      print('❌ [AchievementService] Error unlocking achievement: $e');
    }
  }

  /// Check if achievement is unlocked
  Future<bool> isUnlocked(String achievementId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/achievements/$achievementId')
          .get();

      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Manually unlock an achievement (for testing/debugging)
  Future<void> unlockAchievementById(String achievementId) async {
    await _unlockAchievement(achievementId);
  }

  /// Get all unlocked achievements
  Future<Map<String, UnlockedAchievement>> getUnlockedAchievements() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/achievements')
          .get();

      if (!snapshot.exists) return {};

      final Map<String, UnlockedAchievement> unlocked = {};
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((achievementId, value) {
        final entryData = Map<String, dynamic>.from(value);
        final achievement = achievements[achievementId];
        if (achievement != null) {
          unlocked[achievementId] = UnlockedAchievement(
            achievement: achievement,
            unlockedAt: DateTime.fromMillisecondsSinceEpoch(entryData['unlockedAt']),
          );
        }
      });

      return unlocked;
    } catch (e) {
      print('❌ [AchievementService] Error getting unlocked achievements: $e');
      return {};
    }
  }

  /// Get achievement points total
  Future<int> getTotalAchievementPoints() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/achievement_points')
          .get();

      if (!snapshot.exists) return 0;
      return snapshot.value as int;
    } catch (e) {
      return 0;
    }
  }

  /// Get progress for a category
  Future<CategoryProgress> getCategoryProgress(AchievementCategory category) async {
    final unlocked = await getUnlockedAchievements();
    final categoryAchievements = achievements.values
        .where((a) => a.category == category)
        .toList();

    final unlockedCount = categoryAchievements
        .where((a) => unlocked.containsKey(a.id))
        .length;

    return CategoryProgress(
      category: category,
      total: categoryAchievements.length,
      unlocked: unlockedCount,
    );
  }
}

/// Achievement model
class Achievement {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final AchievementCategory category;
  final String icon;
  final int points;
  final AchievementRarity rarity;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.points,
    required this.rarity,
  });

  String getName(String locale) => name[locale] ?? name['en']!;
  String getDescription(String locale) => description[locale] ?? description['en']!;

  Color getRarityColor() {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}

/// Unlocked achievement with timestamp
class UnlockedAchievement {
  final Achievement achievement;
  final DateTime unlockedAt;

  UnlockedAchievement({
    required this.achievement,
    required this.unlockedAt,
  });
}

/// Achievement categories
enum AchievementCategory {
  games,
  streaks,
  challenges,
  social,
  stats,
}

extension AchievementCategoryExtension on AchievementCategory {
  String getName(String locale) {
    if (locale == 'tr') {
      switch (this) {
        case AchievementCategory.games:
          return 'Oyunlar';
        case AchievementCategory.streaks:
          return 'Seriler';
        case AchievementCategory.challenges:
          return 'Meydan Okumalar';
        case AchievementCategory.social:
          return 'Sosyal';
        case AchievementCategory.stats:
          return 'İstatistikler';
      }
    } else {
      return name[0].toUpperCase() + name.substring(1);
    }
  }

  String getIcon() {
    switch (this) {
      case AchievementCategory.games:
        return '🎮';
      case AchievementCategory.streaks:
        return '🔥';
      case AchievementCategory.challenges:
        return '🎯';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.stats:
        return '📊';
    }
  }
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Category progress model
class CategoryProgress {
  final AchievementCategory category;
  final int total;
  final int unlocked;

  CategoryProgress({
    required this.category,
    required this.total,
    required this.unlocked,
  });

  double get progress => total > 0 ? unlocked / total : 0;
}

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for managing daily puzzle challenges
/// Provides one special puzzle per day with bonus rewards
class DailyChallengeService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int challengeReward = 50; // Bonus points for completing daily challenge

  /// Get today's challenge
  /// Returns a unique challenge based on the current date
  Future<DailyChallenge?> getTodaysChallenge() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final challengeId = _getChallengeIdForDate(today);

      // Check if already completed today
      final completionSnapshot = await _database
          .child('users/${currentUser.uid}/daily_challenges/$challengeId')
          .get();

      final isCompleted = completionSnapshot.exists;

      return DailyChallenge(
        id: challengeId,
        date: today,
        difficulty: _getDifficultyForDate(today),
        rewardPoints: challengeReward,
        isCompleted: isCompleted,
      );
    } catch (e) {
      print('❌ [DailyChallengeService] Error getting challenge: $e');
      return null;
    }
  }

  /// Generate a unique challenge ID based on date
  /// Format: YYYYMMDD (e.g., "20260109")
  String _getChallengeIdForDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Get difficulty for a specific date
  /// Cycles through difficulties based on day of week
  String _getDifficultyForDate(DateTime date) {
    final dayOfWeek = date.weekday;
    switch (dayOfWeek) {
      case DateTime.monday:
      case DateTime.tuesday:
        return 'easy';
      case DateTime.wednesday:
      case DateTime.thursday:
        return 'medium';
      case DateTime.friday:
      case DateTime.saturday:
        return 'hard';
      case DateTime.sunday:
        return 'expert'; // Sunday challenge!
      default:
        return 'medium';
    }
  }

  /// Get seed for puzzle generation based on date
  /// This ensures everyone gets the same puzzle for the same day
  int getSeedForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.millisecondsSinceEpoch ~/ 1000;
  }

  /// Complete today's challenge
  Future<ChallengeCompletionResult> completeChallenge({
    required int timeTaken,
    required int movesCount,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return ChallengeCompletionResult(
        success: false,
        message: 'Not logged in',
        rewardPoints: 0,
      );
    }

    try {
      final challenge = await getTodaysChallenge();
      if (challenge == null) {
        return ChallengeCompletionResult(
          success: false,
          message: 'No challenge available',
          rewardPoints: 0,
        );
      }

      if (challenge.isCompleted) {
        return ChallengeCompletionResult(
          success: false,
          message: 'Already completed today',
          rewardPoints: 0,
        );
      }

      // Calculate bonus based on performance
      int bonusPoints = 0;
      if (timeTaken < 300) bonusPoints += 20; // Under 5 minutes
      if (movesCount < 100) bonusPoints += 10; // Efficient solving

      final totalReward = challengeReward + bonusPoints;

      // Record completion
      await _database
          .child('users/${currentUser.uid}/daily_challenges/${challenge.id}')
          .set({
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'timeTaken': timeTaken,
        'movesCount': movesCount,
        'rewardPoints': totalReward,
        'difficulty': challenge.difficulty,
      });

      // Award points
      await _database
          .child('users/${currentUser.uid}/points')
          .set(ServerValue.increment(totalReward));

      // Update total challenges completed
      await _database
          .child('users/${currentUser.uid}/stats/daily_challenges_completed')
          .set(ServerValue.increment(1));

      print('✅ [DailyChallengeService] Challenge completed! Reward: $totalReward points');

      return ChallengeCompletionResult(
        success: true,
        message: 'Challenge completed!',
        rewardPoints: totalReward,
        bonusPoints: bonusPoints,
      );
    } catch (e) {
      print('❌ [DailyChallengeService] Error completing challenge: $e');
      return ChallengeCompletionResult(
        success: false,
        message: 'Error completing challenge',
        rewardPoints: 0,
      );
    }
  }

  /// Get challenge completion history (last 30 days)
  Future<List<ChallengeHistory>> getChallengeHistory({int limit = 30}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/daily_challenges')
          .limitToLast(limit)
          .get();

      if (!snapshot.exists) return [];

      final List<ChallengeHistory> history = [];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((challengeId, value) {
        final entryData = Map<String, dynamic>.from(value);
        history.add(ChallengeHistory.fromMap(challengeId, entryData));
      });

      // Sort by date descending
      history.sort((a, b) => b.date.compareTo(a.date));

      return history;
    } catch (e) {
      print('❌ [DailyChallengeService] Error getting history: $e');
      return [];
    }
  }

  /// Get total challenges completed
  Future<int> getTotalChallengesCompleted() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/stats/daily_challenges_completed')
          .get();

      if (!snapshot.exists) return 0;
      return snapshot.value as int;
    } catch (e) {
      return 0;
    }
  }

  /// Get current streak (consecutive days)
  Future<int> getChallengeStreak() async {
    final history = await getChallengeHistory(limit: 60);
    if (history.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    // Check if today is completed
    final todayCompleted = history.any((h) =>
        h.date.year == checkDate.year &&
        h.date.month == checkDate.month &&
        h.date.day == checkDate.day);

    if (!todayCompleted) {
      // If today not completed, check yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Count consecutive days backwards
    for (int i = 0; i < 60; i++) {
      final hasChallenge = history.any((h) =>
          h.date.year == checkDate.year &&
          h.date.month == checkDate.month &&
          h.date.day == checkDate.day);

      if (!hasChallenge) break;

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

/// Daily challenge model
class DailyChallenge {
  final String id;
  final DateTime date;
  final String difficulty;
  final int rewardPoints;
  final bool isCompleted;

  DailyChallenge({
    required this.id,
    required this.date,
    required this.difficulty,
    required this.rewardPoints,
    this.isCompleted = false,
  });

  /// Get difficulty emoji
  String getDifficultyEmoji() {
    switch (difficulty) {
      case 'easy':
        return '⭐';
      case 'medium':
        return '⭐⭐';
      case 'hard':
        return '⭐⭐⭐';
      case 'expert':
        return '⭐⭐⭐⭐';
      default:
        return '⭐⭐';
    }
  }

  /// Get difficulty name
  String getDifficultyName(String locale) {
    if (locale == 'tr') {
      switch (difficulty) {
        case 'easy':
          return 'Kolay';
        case 'medium':
          return 'Orta';
        case 'hard':
          return 'Zor';
        case 'expert':
          return 'Uzman';
        default:
          return 'Orta';
      }
    } else {
      return difficulty[0].toUpperCase() + difficulty.substring(1);
    }
  }
}

/// Challenge completion result
class ChallengeCompletionResult {
  final bool success;
  final String message;
  final int rewardPoints;
  final int bonusPoints;

  ChallengeCompletionResult({
    required this.success,
    required this.message,
    required this.rewardPoints,
    this.bonusPoints = 0,
  });
}

/// Challenge history entry
class ChallengeHistory {
  final String id;
  final DateTime date;
  final DateTime completedAt;
  final int timeTaken;
  final int movesCount;
  final int rewardPoints;
  final String difficulty;

  ChallengeHistory({
    required this.id,
    required this.date,
    required this.completedAt,
    required this.timeTaken,
    required this.movesCount,
    required this.rewardPoints,
    required this.difficulty,
  });

  factory ChallengeHistory.fromMap(String id, Map<String, dynamic> map) {
    // Parse date from ID (YYYYMMDD)
    final year = int.parse(id.substring(0, 4));
    final month = int.parse(id.substring(4, 6));
    final day = int.parse(id.substring(6, 8));
    final date = DateTime(year, month, day);

    return ChallengeHistory(
      id: id,
      date: date,
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completedAt'] ?? 0),
      timeTaken: map['timeTaken'] ?? 0,
      movesCount: map['movesCount'] ?? 0,
      rewardPoints: map['rewardPoints'] ?? 0,
      difficulty: map['difficulty'] ?? 'medium',
    );
  }
}

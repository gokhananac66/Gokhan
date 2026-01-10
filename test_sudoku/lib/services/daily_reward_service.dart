import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for managing daily login rewards
/// Awards points for consecutive daily logins and tracks streaks
class DailyRewardService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<int> dailyRewards = [
    10,  // Day 1
    15,  // Day 2
    20,  // Day 3
    25,  // Day 4
    30,  // Day 5
    40,  // Day 6
    50,  // Day 7 (bonus!)
  ];

  /// Check if user can claim daily reward
  /// Returns reward amount if available, 0 if already claimed today
  Future<DailyRewardStatus> checkDailyReward() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return DailyRewardStatus(
        canClaim: false,
        rewardAmount: 0,
        currentStreak: 0,
        nextReward: 0,
      );
    }

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/daily_reward')
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (!snapshot.exists) {
        // First time login reward
        return DailyRewardStatus(
          canClaim: true,
          rewardAmount: dailyRewards[0],
          currentStreak: 0,
          nextReward: dailyRewards[1],
        );
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final lastClaimTimestamp = data['lastClaimDate'] ?? 0;
      final lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastClaimTimestamp);
      final lastClaimDay = DateTime(
        lastClaimDate.year,
        lastClaimDate.month,
        lastClaimDate.day,
      );

      final currentStreak = data['streak'] ?? 0;
      final daysSinceLastClaim = today.difference(lastClaimDay).inDays;

      // Already claimed today
      if (daysSinceLastClaim == 0) {
        final nextRewardIndex = currentStreak % dailyRewards.length;
        return DailyRewardStatus(
          canClaim: false,
          rewardAmount: 0,
          currentStreak: currentStreak,
          nextReward: dailyRewards[nextRewardIndex],
        );
      }

      // Missed a day - streak broken
      if (daysSinceLastClaim > 1) {
        return DailyRewardStatus(
          canClaim: true,
          rewardAmount: dailyRewards[0],
          currentStreak: 0,
          nextReward: dailyRewards[1],
          streakBroken: true,
        );
      }

      // Can claim for consecutive day
      final rewardIndex = currentStreak % dailyRewards.length;
      final nextRewardIndex = (currentStreak + 1) % dailyRewards.length;

      return DailyRewardStatus(
        canClaim: true,
        rewardAmount: dailyRewards[rewardIndex],
        currentStreak: currentStreak,
        nextReward: dailyRewards[nextRewardIndex],
      );
    } catch (e) {
      print('❌ [DailyRewardService] Error checking daily reward: $e');
      return DailyRewardStatus(
        canClaim: false,
        rewardAmount: 0,
        currentStreak: 0,
        nextReward: 0,
      );
    }
  }

  /// Claim daily reward
  /// Returns true if successful, false if already claimed or error
  Future<ClaimResult> claimDailyReward() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return ClaimResult(
        success: false,
        message: 'Not logged in',
        rewardAmount: 0,
        newStreak: 0,
      );
    }

    try {
      final status = await checkDailyReward();

      if (!status.canClaim) {
        return ClaimResult(
          success: false,
          message: 'Already claimed today',
          rewardAmount: 0,
          newStreak: status.currentStreak,
        );
      }

      final now = DateTime.now();
      final newStreak = status.streakBroken ? 1 : status.currentStreak + 1;

      // Update daily reward data
      await _database
          .child('users/${currentUser.uid}/daily_reward')
          .update({
        'lastClaimDate': now.millisecondsSinceEpoch,
        'streak': newStreak,
        'totalClaimed': ServerValue.increment(1),
      });

      // Add points to user's total
      await _database
          .child('users/${currentUser.uid}/points')
          .set(ServerValue.increment(status.rewardAmount));

      // Log the reward claim
      await _database
          .child('users/${currentUser.uid}/reward_history')
          .push()
          .set({
        'type': 'daily_login',
        'amount': status.rewardAmount,
        'streak': newStreak,
        'timestamp': now.millisecondsSinceEpoch,
      });

      print('✅ [DailyRewardService] Claimed ${status.rewardAmount} points! Streak: $newStreak');

      return ClaimResult(
        success: true,
        message: status.streakBroken ? 'Streak restarted!' : 'Reward claimed!',
        rewardAmount: status.rewardAmount,
        newStreak: newStreak,
        streakBroken: status.streakBroken,
      );
    } catch (e) {
      print('❌ [DailyRewardService] Error claiming reward: $e');
      return ClaimResult(
        success: false,
        message: 'Error claiming reward',
        rewardAmount: 0,
        newStreak: 0,
      );
    }
  }

  /// Get current streak
  Future<int> getCurrentStreak() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/daily_reward/streak')
          .get();

      if (!snapshot.exists) return 0;
      return snapshot.value as int;
    } catch (e) {
      return 0;
    }
  }

  /// Get total rewards claimed
  Future<int> getTotalRewardsClaimed() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/daily_reward/totalClaimed')
          .get();

      if (!snapshot.exists) return 0;
      return snapshot.value as int;
    } catch (e) {
      return 0;
    }
  }

  /// Get reward calendar data (last 30 days)
  Future<Map<DateTime, bool>> getRewardCalendar() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/reward_history')
          .orderByChild('timestamp')
          .limitToLast(30)
          .get();

      if (!snapshot.exists) return {};

      final Map<DateTime, bool> calendar = {};
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        final entryData = Map<String, dynamic>.from(value);
        final timestamp = entryData['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final day = DateTime(date.year, date.month, date.day);
        calendar[day] = true;
      });

      return calendar;
    } catch (e) {
      print('❌ [DailyRewardService] Error getting calendar: $e');
      return {};
    }
  }
}

/// Status of daily reward availability
class DailyRewardStatus {
  final bool canClaim;
  final int rewardAmount;
  final int currentStreak;
  final int nextReward;
  final bool streakBroken;

  DailyRewardStatus({
    required this.canClaim,
    required this.rewardAmount,
    required this.currentStreak,
    required this.nextReward,
    this.streakBroken = false,
  });
}

/// Result of claiming a reward
class ClaimResult {
  final bool success;
  final String message;
  final int rewardAmount;
  final int newStreak;
  final bool streakBroken;

  ClaimResult({
    required this.success,
    required this.message,
    required this.rewardAmount,
    required this.newStreak,
    this.streakBroken = false,
  });
}

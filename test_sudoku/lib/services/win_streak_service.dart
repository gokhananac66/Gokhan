import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for tracking consecutive win streaks in multiplayer
/// Tracks current streak, best streak, and rewards milestones
class WinStreakService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Milestone rewards
  static const Map<int, int> streakRewards = {
    3: 20,   // 3 wins in a row
    5: 50,   // 5 wins in a row
    10: 100, // 10 wins in a row
    15: 200, // 15 wins in a row
    20: 500, // 20 wins in a row!
  };

  /// Record a game result (win or loss)
  Future<WinStreakResult> recordGameResult(bool isWin) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return WinStreakResult(
        currentStreak: 0,
        bestStreak: 0,
        isNewBest: false,
        milestoneReached: false,
      );
    }

    try {
      final streakRef = _database.child('users/${currentUser.uid}/win_streak');
      final snapshot = await streakRef.get();

      int currentStreak = 0;
      int bestStreak = 0;
      Map<String, bool> claimedMilestones = {};

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        currentStreak = data['current'] ?? 0;
        bestStreak = data['best'] ?? 0;

        // Load claimed milestones
        if (data.containsKey('claimed_milestones')) {
          final milestonesData = data['claimed_milestones'] as Map;
          claimedMilestones = milestonesData.map(
            (key, value) => MapEntry(key.toString(), value as bool),
          );
        }
      }

      if (isWin) {
        currentStreak++;

        // Update best streak if needed
        bool isNewBest = false;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
          isNewBest = true;
        }

        // Check for milestone rewards
        int? milestoneReward;
        int? milestoneStreak;
        bool milestoneReached = false;

        for (var entry in streakRewards.entries) {
          final milestone = entry.key;
          final reward = entry.value;
          final milestoneKey = milestone.toString();

          // Check if we just hit this milestone and haven't claimed it
          if (currentStreak == milestone &&
              !(claimedMilestones[milestoneKey] ?? false)) {
            milestoneReward = reward;
            milestoneStreak = milestone;
            milestoneReached = true;
            claimedMilestones[milestoneKey] = true;

            // Award the milestone reward
            await _database
                .child('users/${currentUser.uid}/points')
                .set(ServerValue.increment(reward));

            print('🎉 [WinStreakService] Milestone reached! $milestone wins = $reward points');
            break;
          }
        }

        // Update streak data
        await streakRef.update({
          'current': currentStreak,
          'best': bestStreak,
          'claimed_milestones': claimedMilestones,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });

        print('🔥 [WinStreakService] Win recorded! Streak: $currentStreak (Best: $bestStreak)');

        return WinStreakResult(
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          isNewBest: isNewBest,
          milestoneReached: milestoneReached,
          milestoneReward: milestoneReward,
          milestoneStreak: milestoneStreak,
        );
      } else {
        // Loss - reset current streak
        final previousStreak = currentStreak;
        currentStreak = 0;

        await streakRef.update({
          'current': 0,
          'best': bestStreak,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });

        print('💔 [WinStreakService] Loss recorded. Streak broken at $previousStreak');

        return WinStreakResult(
          currentStreak: 0,
          bestStreak: bestStreak,
          isNewBest: false,
          milestoneReached: false,
          streakBroken: true,
          previousStreak: previousStreak,
        );
      }
    } catch (e) {
      print('❌ [WinStreakService] Error recording game result: $e');
      return WinStreakResult(
        currentStreak: 0,
        bestStreak: 0,
        isNewBest: false,
        milestoneReached: false,
      );
    }
  }

  /// Get current win streak
  Future<WinStreakData> getCurrentStreak() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return WinStreakData(current: 0, best: 0);
    }

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/win_streak')
          .get();

      if (!snapshot.exists) {
        return WinStreakData(current: 0, best: 0);
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return WinStreakData(
        current: data['current'] ?? 0,
        best: data['best'] ?? 0,
        lastUpdated: data['lastUpdated'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'])
            : null,
      );
    } catch (e) {
      print('❌ [WinStreakService] Error getting streak: $e');
      return WinStreakData(current: 0, best: 0);
    }
  }

  /// Get next milestone info
  Future<NextMilestone?> getNextMilestone() async {
    final streakData = await getCurrentStreak();
    final currentStreak = streakData.current;

    // Find next unclaimed milestone
    for (var entry in streakRewards.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.key > currentStreak) {
        return NextMilestone(
          streakRequired: entry.key,
          rewardPoints: entry.value,
          winsRemaining: entry.key - currentStreak,
        );
      }
    }

    return null; // All milestones reached!
  }

  /// Get streak tier (for visual badges)
  String getStreakTier(int streak) {
    if (streak >= 20) return 'legendary';
    if (streak >= 15) return 'master';
    if (streak >= 10) return 'expert';
    if (streak >= 5) return 'advanced';
    if (streak >= 3) return 'intermediate';
    return 'beginner';
  }

  /// Get streak emoji
  String getStreakEmoji(int streak) {
    if (streak >= 20) return '👑';
    if (streak >= 15) return '💎';
    if (streak >= 10) return '🏆';
    if (streak >= 5) return '🔥';
    if (streak >= 3) return '⭐';
    return '🎯';
  }
}

/// Win streak result after recording a game
class WinStreakResult {
  final int currentStreak;
  final int bestStreak;
  final bool isNewBest;
  final bool milestoneReached;
  final int? milestoneReward;
  final int? milestoneStreak;
  final bool streakBroken;
  final int? previousStreak;

  WinStreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.isNewBest,
    required this.milestoneReached,
    this.milestoneReward,
    this.milestoneStreak,
    this.streakBroken = false,
    this.previousStreak,
  });
}

/// Current win streak data
class WinStreakData {
  final int current;
  final int best;
  final DateTime? lastUpdated;

  WinStreakData({
    required this.current,
    required this.best,
    this.lastUpdated,
  });
}

/// Next milestone information
class NextMilestone {
  final int streakRequired;
  final int rewardPoints;
  final int winsRemaining;

  NextMilestone({
    required this.streakRequired,
    required this.rewardPoints,
    required this.winsRemaining,
  });
}

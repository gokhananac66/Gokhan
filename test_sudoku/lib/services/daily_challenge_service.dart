import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class DailyChallengeService {
  static const String _completedDaysKey = 'daily_challenge_completed_days';
  static const String _currentStreakKey = 'daily_challenge_streak';
  static const String _lastPlayedKey = 'daily_challenge_last_played';

  /// Get today's date string (YYYY-MM-DD)
  static String getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if today's challenge is completed
  static Future<bool> isTodayCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completedDays = prefs.getStringList(_completedDaysKey) ?? [];
    return completedDays.contains(getTodayString());
  }

  /// Mark today's challenge as completed
  static Future<void> markTodayCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completedDays = prefs.getStringList(_completedDaysKey) ?? [];
    final today = getTodayString();

    if (!completedDays.contains(today)) {
      completedDays.add(today);
      await prefs.setStringList(_completedDaysKey, completedDays);

      // Update streak
      await _updateStreak();
    }
  }

  /// Update streak count
  static Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString(_lastPlayedKey);
    final today = getTodayString();
    final yesterday = _getYesterdayString();

    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    if (lastPlayed == yesterday) {
      // Consecutive day
      currentStreak++;
    } else if (lastPlayed != today) {
      // Streak broken
      currentStreak = 1;
    }

    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setString(_lastPlayedKey, today);
  }

  static String _getYesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  /// Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  /// Get completed days for current month
  static Future<List<int>> getCompletedDaysThisMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final completedDays = prefs.getStringList(_completedDaysKey) ?? [];
    final now = DateTime.now();
    final currentMonthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return completedDays
        .where((day) => day.startsWith(currentMonthPrefix))
        .map((day) => int.parse(day.split('-').last))
        .toList();
  }

  /// Get total completed days this month
  static Future<int> getCompletedCountThisMonth() async {
    final days = await getCompletedDaysThisMonth();
    return days.length;
  }

  /// Get days in current month
  static int getDaysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Generate a deterministic puzzle seed for today
  /// This ensures everyone gets the same puzzle each day
  static int getTodaySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Get today's difficulty (cycles through difficulties)
  static String getTodayDifficulty() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final difficulties = ['Kolay', 'Orta', 'Zor', 'Uzman'];
    return difficulties[dayOfYear % difficulties.length];
  }

  /// Get localized difficulty name
  static String getLocalizedDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Kolay': return 'KOLAY';
      case 'Orta': return 'ORTA';
      case 'Zor': return 'ZOR';
      case 'Uzman': return 'UZMAN';
      default: return difficulty.toUpperCase();
    }
  }

  /// Get reward for completing daily challenge
  static int getDailyReward() => 50;

  /// Get bonus tokens
  static int getDailyTokens() => 10;

  /// Get month name in Turkish
  static String getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  /// Get month name in English
  static String getMonthNameEn(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

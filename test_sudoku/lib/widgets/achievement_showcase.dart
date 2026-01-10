import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../screens/achievements_screen.dart';

/// Compact achievement showcase widget for profile/stats screens
/// Shows total progress and recent unlocks
class AchievementShowcase extends StatelessWidget {
  final Map<String, UnlockedAchievement> unlockedAchievements;
  final int totalPoints;

  const AchievementShowcase({
    super.key,
    required this.unlockedAchievements,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAchievements = AchievementService.achievements.length;
    final progress = unlockedAchievements.length / totalAchievements;

    // Get recent unlocks (last 3)
    final recentUnlocks = unlockedAchievements.values.toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final displayUnlocks = recentUnlocks.take(3).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AchievementsScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'tr' ? 'Başarımlar' : 'Achievements',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unlockedAchievements.length}/$totalAchievements ${locale == 'tr' ? 'açıldı' : 'unlocked'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '⭐',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalPoints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 10,
              ),
            ),

            if (displayUnlocks.isNotEmpty) ...[
              const SizedBox(height: 16),

              // Recent unlocks label
              Text(
                locale == 'tr' ? 'Son Açılanlar' : 'Recently Unlocked',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Recent achievement badges
              Row(
                children: displayUnlocks.map((unlock) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMiniAchievementBadge(unlock.achievement),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // View all button
            Center(
              child: Text(
                '${locale == 'tr' ? 'Tümünü Gör' : 'View All'} →',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAchievementBadge(Achievement achievement) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: achievement.getRarityColor(),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          achievement.icon,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

/// Simplified version for smaller spaces
class CompactAchievementBadge extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;
  final VoidCallback? onTap;

  const CompactAchievementBadge({
    super.key,
    required this.unlockedCount,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏆',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              '$unlockedCount/$totalCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              locale == 'tr' ? 'başarım' : 'achievements',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

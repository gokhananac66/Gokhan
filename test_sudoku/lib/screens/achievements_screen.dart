import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../app_localizations.dart';

/// Full-screen achievements display with categories and progress
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _service = AchievementService();
  Map<String, UnlockedAchievement> _unlocked = {};
  int _totalPoints = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _loading = true);

    final unlocked = await _service.getUnlockedAchievements();
    final points = await _service.getTotalAchievementPoints();

    setState(() {
      _unlocked = unlocked;
      _totalPoints = points;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.currentLanguage; // Use app setting instead of system locale
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          locale == 'tr' ? 'Başarımlar' : 'Achievements',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 3,
                color: Colors.black26,
              ),
              Shadow(
                offset: Offset(-1, -1),
                blurRadius: 2,
                color: Colors.white70,
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header stats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🏆',
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          locale == 'tr'
                              ? '${_unlocked.length}/${AchievementService.achievements.length} Başarım'
                              : '${_unlocked.length}/${AchievementService.achievements.length} Achievements',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_totalPoints ${locale == 'tr' ? 'Başarım Puanı' : 'Achievement Points'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _unlocked.length / AchievementService.achievements.length,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category sections
                  ...AchievementCategory.values.map((category) {
                    final categoryAchievements = AchievementService.achievements.values
                        .where((a) => a.category == category)
                        .toList();

                    final categoryUnlocked = categoryAchievements
                        .where((a) => _unlocked.containsKey(a.id))
                        .length;

                    return _buildCategorySection(
                      category: category,
                      achievements: categoryAchievements,
                      unlockedCount: categoryUnlocked,
                      locale: locale,
                      isDark: isDark,
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySection({
    required AchievementCategory category,
    required List<Achievement> achievements,
    required int unlockedCount,
    required String locale,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                category.getIcon(),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                category.getName(locale),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount/${achievements.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Achievement cards
        ...achievements.map((achievement) {
          final isUnlocked = _unlocked.containsKey(achievement.id);
          return _buildAchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            unlockedAt: isUnlocked ? _unlocked[achievement.id]!.unlockedAt : null,
            locale: locale,
            isDark: isDark,
          );
        }).toList(),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAchievementCard({
    required Achievement achievement,
    required bool isUnlocked,
    DateTime? unlockedAt,
    required String locale,
    required bool isDark,
  }) {
    final rarityColor = achievement.getRarityColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? rarityColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: rarityColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? rarityColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isUnlocked
                    ? Border.all(color: rarityColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    achievement.getName(locale), // Always show name
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    achievement.getDescription(locale), // Always show description
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                  if (isUnlocked && unlockedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatUnlockDate(unlockedAt, locale),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? rarityColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isUnlocked ? '⭐' : '🔒',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.points}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? rarityColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUnlockDate(DateTime date, String locale) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (locale == 'tr') {
      if (diff.inDays == 0) return 'Bugün açıldı';
      if (diff.inDays == 1) return 'Dün açıldı';
      if (diff.inDays < 7) return '${diff.inDays} gün önce açıldı';
      if (diff.inDays < 30) return '${diff.inDays ~/ 7} hafta önce açıldı';
      return '${diff.inDays ~/ 30} ay önce açıldı';
    } else {
      if (diff.inDays == 0) return 'Unlocked today';
      if (diff.inDays == 1) return 'Unlocked yesterday';
      if (diff.inDays < 7) return 'Unlocked ${diff.inDays} days ago';
      if (diff.inDays < 30) return 'Unlocked ${diff.inDays ~/ 7} weeks ago';
      return 'Unlocked ${diff.inDays ~/ 30} months ago';
    }
  }
}

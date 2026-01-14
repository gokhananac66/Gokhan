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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [const Color(0xFF1A237E), const Color(0xFF121212), const Color(0xFF121212)]
            : [const Color(0xFF90CAF9), const Color(0xFFE3F2FD), const Color(0xFFF5F5F5)],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 12),

                    // Custom Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Geri Butonu
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Başlık
                          Text(
                            '🏆 ${locale == 'tr' ? 'Başarımlar' : 'Achievements'}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Placeholder for symmetry
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // İçerik
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header stats - Premium Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Trophy icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Text('🏆', style: TextStyle(fontSize: 48)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    locale == 'tr'
                                        ? '${_unlocked.length}/${AchievementService.achievements.length} Başarım'
                                        : '${_unlocked.length}/${AchievementService.achievements.length} Achievements',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '$_totalPoints ${locale == 'tr' ? 'Başarım Puanı' : 'Achievement Points'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress bar
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: LinearProgressIndicator(
                                        value: _unlocked.length / AchievementService.achievements.length,
                                        backgroundColor: Colors.transparent,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

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
                            }),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.games:
        return const Color(0xFF2196F3);
      case AchievementCategory.streaks:
        return const Color(0xFFFF6B6B);
      case AchievementCategory.challenges:
        return const Color(0xFF9C27B0);
      case AchievementCategory.social:
        return const Color(0xFF4facfe);
      case AchievementCategory.stats:
        return const Color(0xFF56ab2f);
    }
  }

  Widget _buildCategorySection({
    required AchievementCategory category,
    required List<Achievement> achievements,
    required int unlockedCount,
    required String locale,
    required bool isDark,
  }) {
    final categoryColor = _getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header - Premium Style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [categoryColor, categoryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category.getIcon(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.getName(locale),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount/${achievements.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

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
        }),

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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: [rarityColor, rarityColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                    : [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? Colors.white.withOpacity(0.3)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: rarityColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.white.withOpacity(0.25)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(14),
                border: isUnlocked
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 28,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    achievement.getName(locale),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      shadows: isUnlocked
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    achievement.getDescription(locale),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked
                          ? Colors.white.withOpacity(0.85)
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (isUnlocked && unlockedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatUnlockDate(unlockedAt, locale),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.white.withOpacity(0.25)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isUnlocked ? '⭐' : '🔒',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.points}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.white
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                      shadows: isUnlocked
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
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

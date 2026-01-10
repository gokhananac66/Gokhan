import 'package:flutter/material.dart';
import '../services/win_streak_service.dart';

/// Win streak badge widget
/// Shows current win streak with animated fire effects
class WinStreakBadge extends StatefulWidget {
  final WinStreakData streakData;
  final bool showDetails;

  const WinStreakBadge({
    super.key,
    required this.streakData,
    this.showDetails = true,
  });

  @override
  State<WinStreakBadge> createState() => _WinStreakBadgeState();
}

class _WinStreakBadgeState extends State<WinStreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final WinStreakService _streakService = WinStreakService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStreakColor() {
    final tier = _streakService.getStreakTier(widget.streakData.current);
    switch (tier) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'master':
        return const Color(0xFFB19CD9); // Purple
      case 'expert':
        return const Color(0xFF4FC3F7); // Blue
      case 'advanced':
        return const Color(0xFFFF6B6B); // Red
      case 'intermediate':
        return const Color(0xFFFFB74D); // Orange
      default:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final hasStreak = widget.streakData.current > 0;

    if (!widget.showDetails) {
      // Compact version
      return _buildCompactBadge(locale, hasStreak);
    }

    // Full version with details
    return _buildFullBadge(locale, hasStreak);
  }

  Widget _buildCompactBadge(String locale, bool hasStreak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasStreak
              ? [_getStreakColor().withOpacity(0.3), _getStreakColor()]
              : [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _streakService.getStreakEmoji(widget.streakData.current),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.streakData.current}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(String locale, bool hasStreak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasStreak
              ? [_getStreakColor().withOpacity(0.2), _getStreakColor().withOpacity(0.4)]
              : [Colors.grey[200]!, Colors.grey[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStreak ? _getStreakColor() : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ScaleTransition(
                scale: hasStreak ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Text(
                  _streakService.getStreakEmoji(widget.streakData.current),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale == 'tr' ? 'Galibiyet Serisi' : 'Win Streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.streakData.current}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: hasStreak ? _getStreakColor() : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Best streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      locale == 'tr' ? 'En İyi' : 'Best',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${widget.streakData.best}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hasStreak ? _getStreakColor().withOpacity(0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getTierName(locale),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasStreak ? _getStreakColor().withOpacity(0.9) : Colors.grey[700],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar to next milestone
          _buildMilestoneProgress(locale),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(String locale) {
    final current = widget.streakData.current;
    final milestones = WinStreakService.streakRewards.keys.toList()..sort();

    // Find next milestone
    int? nextMilestone;
    for (final milestone in milestones) {
      if (milestone > current) {
        nextMilestone = milestone;
        break;
      }
    }

    if (nextMilestone == null) {
      return Text(
        locale == 'tr'
            ? '🎉 Tüm hedefler tamamlandı!'
            : '🎉 All milestones reached!',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final progress = current / nextMilestone;
    final remaining = nextMilestone - current;
    final reward = WinStreakService.streakRewards[nextMilestone]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale == 'tr'
                  ? '$remaining galibiyet daha: +$reward 💎'
                  : '$remaining more wins: +$reward 💎',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current/$nextMilestone',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getStreakColor()),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _getTierName(String locale) {
    final tier = _streakService.getStreakTier(widget.streakData.current);

    if (locale == 'tr') {
      switch (tier) {
        case 'legendary':
          return 'Efsanevi';
        case 'master':
          return 'Usta';
        case 'expert':
          return 'Uzman';
        case 'advanced':
          return 'İleri Seviye';
        case 'intermediate':
          return 'Orta Seviye';
        default:
          return 'Başlangıç';
      }
    } else {
      return tier[0].toUpperCase() + tier.substring(1);
    }
  }
}

/// Milestone reached dialog
class MilestoneReachedDialog extends StatelessWidget {
  final int milestoneStreak;
  final int rewardPoints;

  const MilestoneReachedDialog({
    super.key,
    required this.milestoneStreak,
    required this.rewardPoints,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final service = WinStreakService();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service.getStreakEmoji(milestoneStreak),
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              locale == 'tr' ? 'Hedef Başarıldı!' : 'Milestone Reached!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locale == 'tr'
                  ? '$milestoneStreak Ardışık Galibiyet!'
                  : '$milestoneStreak Wins in a Row!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '💎',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$rewardPoints',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  Text(
                    locale == 'tr' ? 'Bonus Puan!' : 'Bonus Points!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  locale == 'tr' ? 'Harika! 🎉' : 'Awesome! 🎉',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

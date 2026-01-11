import 'package:flutter/material.dart';
import '../services/daily_challenge_service.dart';
import '../widgets/activity_calendar.dart';
import '../app_localizations.dart';
import 'game_screen.dart';

/// Daily Challenge Screen with calendar view
/// Shows challenge history, current challenge, and start button
class DailyChallengeScreen extends StatefulWidget {
  final DailyChallenge challenge;

  const DailyChallengeScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Map<DateTime, bool> _completedDays = {};
  int _completedCount = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _loadChallengeHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChallengeHistory() async {
    try {
      final history = await DailyChallengeService().getChallengeHistory();
      final streak = await DailyChallengeService().getCurrentStreak();

      setState(() {
        _completedDays = history;
        _completedCount = history.values.where((completed) => completed).length;
        _currentStreak = streak;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading challenge history: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getDifficultyEmoji(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '😊';
      case 'medium':
        return '😐';
      case 'hard':
        return '😣';
      case 'expert':
        return '🤯';
      default:
        return '🎯';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getDifficultyText(String difficulty) {
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
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📅 Günlük Meydan Okuma'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge Info Card
                      _buildChallengeInfoCard(isDark),

                      const SizedBox(height: 24),

                      // Streak Display
                      if (_currentStreak > 0) ...[
                        ActivityStreakDisplay(
                          currentStreak: _currentStreak,
                          totalDays: _completedCount,
                          title: 'Günlük Meydan Okuma Serisi',
                          emoji: '🔥',
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Calendar
                      ActivityCalendar(
                        activityData: _completedDays,
                        title: '📆 Tamamlanan Günler',
                        activeColor: _getDifficultyColor(widget.challenge.difficulty),
                      ),

                      const SizedBox(height: 24),

                      // Start Challenge Button
                      _buildStartButton(isDark),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildChallengeInfoCard(bool isDark) {
    final difficultyColor = _getDifficultyColor(widget.challenge.difficulty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            difficultyColor.withOpacity(0.15),
            difficultyColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: difficultyColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: difficultyColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji & Title
          Row(
            children: [
              Text(
                _getDifficultyEmoji(widget.challenge.difficulty),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugünkü Meydan Okuma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: difficultyColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDifficultyText(widget.challenge.difficulty).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  difficultyColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Reward Info
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: '🎯',
                  label: 'Ödül',
                  value: '+${widget.challenge.rewardPoints}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  icon: '💎',
                  label: 'Jeton',
                  value: '+${_getCoinReward(widget.challenge.difficulty)}',
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status
          if (widget.challenge.isCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '✅ Bugünkü meydan okumayı tamamladın!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: difficultyColor.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: difficultyColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Herkes aynı bulmacayı çözüyor!',
                    style: TextStyle(
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(bool isDark) {
    final isCompleted = widget.challenge.isCompleted;
    final difficultyColor = _getDifficultyColor(widget.challenge.difficulty);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isCompleted ? null : _startChallenge,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey : difficultyColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isCompleted ? 0 : 8,
          shadowColor: difficultyColor.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.play_arrow_rounded,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              isCompleted ? 'Tamamlandı' : 'Mücadeleye Başla',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCoinReward(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 10;
      case 'medium':
        return 20;
      case 'hard':
        return 35;
      case 'expert':
        return 40;
      default:
        return 10;
    }
  }

  void _startChallenge() async {
    // Close animation
    await _animationController.reverse();

    if (!mounted) return;

    // Map challenge difficulty to Turkish difficulty names
    String difficulty;
    switch (widget.challenge.difficulty) {
      case 'easy':
        difficulty = 'Kolay';
        break;
      case 'medium':
        difficulty = 'Orta';
        break;
      case 'hard':
        difficulty = 'Zor';
        break;
      case 'expert':
        difficulty = 'Uzman';
        break;
      default:
        difficulty = 'Orta';
    }

    // Navigate to game screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          gameMode: GameMode.single,
          difficulty: difficulty,
        ),
      ),
    );

    // If game was completed, mark challenge as complete
    if (result == true && mounted) {
      final completionResult = await DailyChallengeService().completeChallenge(
        timeTaken: 0,
        movesCount: 0,
      );

      if (completionResult.success && mounted) {
        // Reload challenge data
        final updatedChallenge = await DailyChallengeService().getTodaysChallenge();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Tebrikler! +${completionResult.rewardPoints} puan kazandın!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to home with success
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      // Replay entrance animation
      _animationController.forward();
    }
  }
}

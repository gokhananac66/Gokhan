import 'package:flutter/material.dart';
import '../services/daily_challenge_service.dart';
import '../app_localizations.dart';
import 'game_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  List<int> _completedDays = [];
  bool _isTodayCompleted = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final completedDays = await DailyChallengeService.getCompletedDaysThisMonth();
    final isTodayCompleted = await DailyChallengeService.isTodayCompleted();
    final streak = await DailyChallengeService.getCurrentStreak();

    setState(() {
      _completedDays = completedDays;
      _isTodayCompleted = isTodayCompleted;
      _streak = streak;
    });
  }

  void _playDailyChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          gameMode: GameMode.single,
          difficulty: DailyChallengeService.getTodayDifficulty(),
          continueGame: false,
          isDailyChallenge: true,
          dailySeed: DailyChallengeService.getTodaySeed(),
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DailyChallengeService.getDaysInCurrentMonth();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final difficulty = DailyChallengeService.getTodayDifficulty();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'GÜNLÜK MEYDAN OKUMA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Üst Kısım - Büyük Takvim Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Üst Satır - Ay ve Seri
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getMonthName(now.month).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    '${now.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_streak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🔥', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_streak gün',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Takvim Grid - Hafta Günleri
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['P', 'S', 'Ç', 'P', 'C', 'C', 'P']
                                .map((day) => SizedBox(
                                      width: 36,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 12),

                          // Takvim Grid - Günler
                          _buildCalendarGrid(now, daysInMonth, firstWeekday),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bugünün Görevi Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isTodayCompleted
                                        ? [Colors.green.shade400, Colors.green.shade600]
                                        : [Colors.amber.shade400, Colors.orange.shade500],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    _isTodayCompleted ? '✓' : '${now.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isTodayCompleted ? 'Tamamlandı!' : 'Bugünün Bulmacası',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildSmallBadge(
                                          DailyChallengeService.getLocalizedDifficulty(difficulty),
                                          Colors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildSmallBadge(
                                          '+${DailyChallengeService.getDailyReward()} puan',
                                          Colors.green,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Ödüller Satırı
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildRewardItem('🎯', 'Puan', '+${DailyChallengeService.getDailyReward()}'),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                ),
                                _buildRewardItem('💎', 'Jeton', '+${DailyChallengeService.getDailyTokens()}'),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                ),
                                _buildRewardItem('⭐', 'XP', '+50'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Oyna Butonu
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isTodayCompleted ? null : _playDailyChallenge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTodayCompleted
                                    ? Colors.grey.shade400
                                    : const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: _isTodayCompleted ? 0 : 4,
                                shadowColor: const Color(0xFF667eea).withOpacity(0.4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isTodayCompleted ? Icons.check_circle : Icons.play_arrow_rounded,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isTodayCompleted ? 'BUGÜN TAMAMLANDI' : 'OYNA',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // İstatistik Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bu Ay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '${_completedDays.length}',
                                  'Tamamlanan',
                                  const Color(0xFF667eea),
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  '${daysInMonth - _completedDays.length}',
                                  'Kalan',
                                  Colors.orange,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  '${((_completedDays.length / now.day) * 100).round()}%',
                                  'Başarı',
                                  Colors.green,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRewardItem(String emoji, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime now, int daysInMonth, int firstWeekday) {
    List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Boş günler
    for (int i = 1; i < firstWeekday; i++) {
      currentRow.add(const SizedBox(width: 36, height: 36));
    }

    // Günler
    for (int day = 1; day <= daysInMonth; day++) {
      final isCompleted = _completedDays.contains(day);
      final isToday = day == now.day;
      final isPast = day < now.day;

      currentRow.add(
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.white
                : isToday
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Color(0xFF667eea), size: 18)
                : Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : isPast
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.8),
                    ),
                  ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentRow,
            ),
          ),
        );
        currentRow = [];
      }
    }

    // Son satır
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 36, height: 36));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
}

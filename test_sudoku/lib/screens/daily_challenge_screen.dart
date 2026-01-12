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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Günlük Meydan Okuma',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            shadows: [
              Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black26),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Kart - Altın Kupa
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFD54F),
                    const Color(0xFFFFC107),
                    const Color(0xFFFFB300),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Kupa Emoji
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Başlık
                  const Text(
                    'Günlük Bulmaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tarih
                  Text(
                    '${now.day} ${_getMonthName(now.month)} ${now.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Zorluk Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DailyChallengeService.getLocalizedDifficulty(difficulty),
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Streak Badge
                  if (_streak > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '$_streak Günlük Seri!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Ödüller
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRewardCard(
                      '🎯',
                      'Ödül',
                      '+${DailyChallengeService.getDailyReward()}',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRewardCard(
                      '💎',
                      'Jeton',
                      '+${DailyChallengeService.getDailyTokens()}',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Takvim Kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ay Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_getMonthName(now.month)} ${now.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Hafta Günleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                        .map((day) => SizedBox(
                              width: 40,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Takvim Grid
                  _buildCalendarGrid(now, daysInMonth, firstWeekday),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Oyna Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isTodayCompleted ? null : _playDailyChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTodayCompleted
                        ? Colors.grey.shade400
                        : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isTodayCompleted ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTodayCompleted ? Icons.check_circle : Icons.play_arrow_rounded,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isTodayCompleted ? 'Bugün Tamamlandı!' : 'OYNA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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
      currentRow.add(const SizedBox(width: 40, height: 40));
    }

    // Günler
    for (int day = 1; day <= daysInMonth; day++) {
      final isCompleted = _completedDays.contains(day);
      final isToday = day == now.day;
      final isPast = day < now.day;

      currentRow.add(
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF4CAF50)
                : isToday
                    ? const Color(0xFFE8F5E9)
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isCompleted
                ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? const Color(0xFF4CAF50)
                          : isPast
                              ? Colors.grey.shade400
                              : Colors.black87,
                    ),
                  ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
        currentRow.add(const SizedBox(width: 40, height: 40));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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

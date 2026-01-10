import 'package:flutter/material.dart';
import '../services/daily_challenge_service.dart';

/// Modern calendar-style daily challenge card
/// Shows mini calendar with completion status
class CalendarChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onTap;

  const CalendarChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    // Calculate days to show (last 7 days)
    final today = DateTime(now.year, now.month, now.day);
    final daysToShow = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    return GestureDetector(
      onTap: challenge.isCompleted ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[400]!,
              Colors.blue[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Trophy + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'tr' ? 'Günlük Mücadeleler' : 'Daily Challenges',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${challenge.getDifficultyName(locale)} • +${challenge.rewardPoints} 💎',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Mini Calendar (Last 7 days)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysToShow.map((date) {
                final isToday = date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;

                // Check if this day's challenge was completed (simplified)
                final isCompleted = isToday && challenge.isCompleted;

                return Column(
                  children: [
                    // Day name
                    Text(
                      _getDayName(date, locale),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Day circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Text(
                                '⭐',
                                style: TextStyle(fontSize: 16),
                              )
                            : Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? Colors.blue[600]
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Play Button
            if (!challenge.isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        locale == 'tr' ? 'Oyna' : 'Play',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              )
            else
              // Completed message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '✅',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'tr' ? 'Tamamlandı!' : 'Completed!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  String _getDayName(DateTime date, String locale) {
    final dayNames = locale == 'tr'
        ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[date.weekday - 1];
  }
}

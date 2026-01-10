import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Activity calendar widget
/// Shows a month view with activity indicators
class ActivityCalendar extends StatelessWidget {
  final Map<DateTime, bool> activityData; // Date -> hasActivity
  final String title;
  final Color activeColor;

  const ActivityCalendar({
    super.key,
    required this.activityData,
    required this.title,
    this.activeColor = const Color(0xFF6A1B9A),
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Calendar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // Month header
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  DateFormat.yMMMM(locale).format(currentMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Day headers
              _buildDayHeaders(locale),

              const SizedBox(height: 8),

              // Calendar grid
              _buildCalendarGrid(currentMonth),

              const SizedBox(height: 16),

              // Legend
              _buildLegend(locale),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(String locale) {
    final dayNames = locale == 'tr'
        ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dayNames.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;

    // Build the grid
    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(_buildEmptyDay());
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final hasActivity = activityData[DateTime(date.year, date.month, date.day)] ?? false;
      final isToday = _isToday(date);

      dayWidgets.add(_buildDay(day, hasActivity, isToday));
    }

    // Build rows of 7 days each
    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final endIndex = i + 7 > dayWidgets.length ? dayWidgets.length : i + 7;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayWidgets.sublist(i, endIndex),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildEmptyDay() {
    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(2),
      ),
    );
  }

  Widget _buildDay(int day, bool hasActivity, bool isToday) {
    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: hasActivity
              ? activeColor
              : isToday
                  ? activeColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: activeColor, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: hasActivity
                  ? Colors.white
                  : isToday
                      ? activeColor
                      : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String locale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: activeColor,
          label: locale == 'tr' ? 'Aktif' : 'Active',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          color: Colors.transparent,
          label: locale == 'tr' ? 'Pasif' : 'Inactive',
          hasBorder: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool hasBorder = false,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey[400]!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Compact activity streak display
class ActivityStreakDisplay extends StatelessWidget {
  final int currentStreak;
  final int totalDays;
  final String title;
  final String emoji;

  const ActivityStreakDisplay({
    super.key,
    required this.currentStreak,
    required this.totalDays,
    required this.title,
    this.emoji = '🔥',
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withOpacity(0.1),
            const Color(0xFFAB47BC).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Emoji
          Text(
            emoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$currentStreak',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'tr' ? 'gün serisi' : 'day streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total days badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$totalDays',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                Text(
                  locale == 'tr' ? 'toplam' : 'total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

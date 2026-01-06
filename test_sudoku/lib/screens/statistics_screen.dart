import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedDifficulty = 'Kolay';

  final List<String> _difficulties = ['Kolay', 'Orta', 'Zor', 'Uzman'];

  Map<String, Map<String, dynamic>> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  String _getLocalizedDifficulty(String key) {
    switch (key) {
      case 'Kolay': return tr('easy');
      case 'Orta': return tr('medium');
      case 'Zor': return tr('hard');
      case 'Uzman': return tr('expert');
      default: return key;
    }
  }

  Future<void> _loadAllStats() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, Map<String, dynamic>> stats = {};

    for (String diff in _difficulties) {
      stats[diff] = {
        'gamesStarted': prefs.getInt('gamesStarted$diff') ?? 0,
        'gamesWon': prefs.getInt('gamesWon$diff') ?? 0,
        'gamesLost': prefs.getInt('gamesLost$diff') ?? 0,
        'perfectWins': prefs.getInt('perfectWins$diff') ?? 0,
        'bestScore': prefs.getInt('bestScore$diff') ?? 0,
        'bestScoreToday': prefs.getInt('bestScoreToday$diff') ?? 0,
        'bestScoreWeek': prefs.getInt('bestScoreWeek$diff') ?? 0,
        'bestScoreMonth': prefs.getInt('bestScoreMonth$diff') ?? 0,
        'currentWinStreak': prefs.getInt('currentWinStreak$diff') ?? 0,
        'bestWinStreak': prefs.getInt('bestWinStreak$diff') ?? 0,
      };
    }

    int totalGamesWon = prefs.getInt('gamesWon') ?? 0;
    int totalGamesLost = prefs.getInt('gamesLost') ?? 0;
    int totalGames = prefs.getInt('totalGames') ?? 0;
    int perfectWins = prefs.getInt('perfectWins') ?? 0;
    int currentStreak = prefs.getInt('currentWinStreak') ?? 0;
    int bestStreak = prefs.getInt('bestWinStreak') ?? 0;

    stats['Genel'] = {
      'gamesStarted': totalGames,
      'gamesWon': totalGamesWon,
      'gamesLost': totalGamesLost,
      'perfectWins': perfectWins,
      'currentWinStreak': currentStreak,
      'bestWinStreak': bestStreak,
    };

    setState(() => _stats = stats);
  }

  double _getWinRate(String difficulty) {
    final stats = _stats[difficulty];
    if (stats == null) return 0;

    int won = stats['gamesWon'] ?? 0;
    int lost = stats['gamesLost'] ?? 0;
    int total = won + lost;

    if (total == 0) return 0;
    return (won / total * 100);
  }

  Future<void> _resetStatistics() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('resetStats')),
        content: Text(tr('resetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final prefs = await SharedPreferences.getInstance();

              await prefs.remove('totalGames');
              await prefs.remove('gamesWon');
              await prefs.remove('gamesLost');
              await prefs.remove('perfectWins');
              await prefs.remove('currentWinStreak');
              await prefs.remove('bestWinStreak');

              for (String diff in _difficulties) {
                await prefs.remove('gamesStarted$diff');
                await prefs.remove('gamesWon$diff');
                await prefs.remove('gamesLost$diff');
                await prefs.remove('perfectWins$diff');
                await prefs.remove('bestScore$diff');
                await prefs.remove('bestScoreToday$diff');
                await prefs.remove('bestScoreWeek$diff');
                await prefs.remove('bestScoreMonth$diff');
                await prefs.remove('currentWinStreak$diff');
                await prefs.remove('bestWinStreak$diff');
                await prefs.remove('bestTime$diff');
              }

              await _loadAllStats();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('statsReset')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(tr('reset'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStats = _stats[_selectedDifficulty] ?? {};
    final generalStats = _stats['Genel'] ?? {};

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(tr('statistics')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _resetStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          // Zorluk secici
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _difficulties.map((diff) {
                bool isSelected = _selectedDifficulty == diff;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = diff),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _getLocalizedDifficulty(diff),
                      style: TextStyle(
                        color: isSelected ? Colors.blue : (isDark ? Colors.grey : Colors.grey.shade600),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Istatistik listesi
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OYUNLAR BOLUMU
                  _buildSectionTitle(tr('games'), isDark),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.grid_on,
                    iconColor: Colors.blue,
                    title: tr('gamesStarted'),
                    value: '${generalStats['gamesStarted'] ?? currentStats['gamesStarted'] ?? 0}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.green,
                    title: tr('gamesWon'),
                    value: '${generalStats['gamesWon'] ?? currentStats['gamesWon'] ?? 0}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.flag_outlined,
                    iconColor: Colors.orange,
                    title: tr('winRate'),
                    value: '${_getWinRate('Genel').toStringAsFixed(1)}%',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: Colors.purple,
                    title: tr('perfectWins'),
                    value: '${generalStats['perfectWins'] ?? currentStats['perfectWins'] ?? 0}',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // EN IYI PUAN BOLUMU
                  _buildSectionTitle(tr('bestScore'), isDark),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.star_outline,
                    iconColor: Colors.amber,
                    title: tr('today'),
                    value: '${currentStats['bestScoreToday'] ?? '-'}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.star_outline,
                    iconColor: Colors.amber,
                    title: tr('thisWeek'),
                    value: '${currentStats['bestScoreWeek'] ?? '-'}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.star_outline,
                    iconColor: Colors.amber,
                    title: tr('thisMonth'),
                    value: '${currentStats['bestScoreMonth'] ?? '-'}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: tr('allTime'),
                    value: '${currentStats['bestScore'] ?? '-'}',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // SERILER BOLUMU
                  _buildSectionTitle(tr('streaks'), isDark),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.arrow_forward,
                    iconColor: Colors.teal,
                    title: tr('currentStreak'),
                    value: '${generalStats['currentWinStreak'] ?? 0}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.double_arrow,
                    iconColor: Colors.teal,
                    title: tr('bestStreak'),
                    value: '${generalStats['bestWinStreak'] ?? 0}',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // Sifirla butonu
                  Center(
                    child: TextButton(
                      onPressed: _resetStatistics,
                      child: Text(
                        tr('resetStats'),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Text(
            value == '0' || value == '-' ? '-' : value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
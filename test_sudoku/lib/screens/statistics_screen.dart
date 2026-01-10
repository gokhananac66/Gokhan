import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_localizations.dart';
import '../services/leaderboard_service.dart';
import '../widgets/stats_bar_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedMode = 'Klasik';

  final List<String> _modes = ['Klasik', 'Race', 'Genel'];

  Map<String, Map<String, dynamic>> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAllStats() async {
    setState(() => _isLoading = true);
    print('📊 [STATISTICS] Loading stats...');

    try {
      // Multiplayer stats from LeaderboardService
      print('📊 [STATISTICS] Fetching classic stats...');
      final classicStats = await LeaderboardService.getUserModeStats('classic');
      print('📊 [STATISTICS] Classic stats: $classicStats');

      print('📊 [STATISTICS] Fetching race stats...');
      final raceStats = await LeaderboardService.getUserModeStats('race');
      print('📊 [STATISTICS] Race stats: $raceStats');

      print('📊 [STATISTICS] Fetching overall stats...');
      final overallStats = await LeaderboardService.getUserStats();
      print('📊 [STATISTICS] Overall stats: $overallStats');

      Map<String, Map<String, dynamic>> stats = {};

      stats['Klasik'] = classicStats ?? {
        'gamesPlayed': 0,
        'wins': 0,
        'winRate': '0.0',
        'totalScore': 0,
      };

      stats['Race'] = raceStats ?? {
        'gamesPlayed': 0,
        'wins': 0,
        'winRate': '0.0',
        'totalScore': 0,
        'fastestWin': null,
      };

      stats['Genel'] = overallStats ?? {
        'totalScore': 0,
        'wins': 0,
        'losses': 0,
        'winRate': 0.0,
      };

      print('✅ [STATISTICS] Stats loaded successfully');
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ [STATISTICS] Error loading stats: $e');
      print('❌ [STATISTICS] Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  double _getWinRate(String mode) {
    final stats = _stats[mode];
    if (stats == null) return 0;

    // Try to parse winRate as string or double
    final winRateValue = stats['winRate'];
    if (winRateValue == null) return 0;

    if (winRateValue is String) {
      return double.tryParse(winRateValue) ?? 0;
    } else if (winRateValue is double) {
      return winRateValue;
    } else if (winRateValue is int) {
      return winRateValue.toDouble();
    }

    return 0;
  }

  int _calculateDraws(Map<String, dynamic> stats) {
    final gamesPlayed = stats['gamesPlayed'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final losses = stats['losses'] ?? 0;
    return gamesPlayed - wins - losses;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStats = _stats[_selectedMode] ?? {};

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(tr('statistics')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mode selector
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                        ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
                        : [Colors.white, Colors.grey.shade50],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF9C27B0).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF9C27B0).withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: _modes.map((mode) {
                      bool isSelected = _selectedMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                ? LinearGradient(
                                    colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                                  )
                                : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Color(0xFF9C27B0).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ] : [],
                            ),
                            child: Text(
                              mode,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 15,
                              ),
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
                  // BAR CHART
                  StatsBarChart(
                    wins: currentStats['wins'] ?? 0,
                    losses: currentStats['losses'] ?? 0,
                    draws: _calculateDraws(currentStats),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // OYUNLAR BOLUMU
                  _buildSectionTitle('Oyunlar', isDark),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.grid_on,
                    iconColor: Colors.blue,
                    title: 'Başlatılan Oyunlar',
                    value: '${currentStats['gamesPlayed'] ?? 0}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.green,
                    title: 'Kazanılan Oyunlar',
                    value: '${currentStats['wins'] ?? 0}',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.flag_outlined,
                    iconColor: Colors.orange,
                    title: 'Kazanma Oranı',
                    value: '${_getWinRate(_selectedMode).toStringAsFixed(1)}%',
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: Icons.star_outlined,
                    iconColor: Colors.purple,
                    title: 'Toplam Skor',
                    value: '${currentStats['totalScore'] ?? 0}',
                    isDark: isDark,
                  ),
                  if (_selectedMode == 'Race' && currentStats['fastestWin'] != null)
                    _buildStatCard(
                      icon: Icons.speed,
                      iconColor: Colors.red,
                      title: 'En Hızlı Kazanma',
                      value: _formatTime(currentStats['fastestWin']),
                      isDark: isDark,
                    ),

                  const SizedBox(height: 32),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
            : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withOpacity(0.8), iconColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withOpacity(0.2), iconColor.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value == '0' || value == '-' ? '-' : value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
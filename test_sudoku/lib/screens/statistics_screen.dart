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
          child: _isLoading
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
                            '📊 ${tr('statistics')}',
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

                    // Mode selector - Premium Style
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: _modes.map((mode) {
                          bool isSelected = _selectedMode == mode;
                          String emoji = mode == 'Klasik' ? '⚔️' : (mode == 'Race' ? '🏁' : '🌍');

                          List<Color> getGradient() {
                            if (mode == 'Klasik') return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
                            if (mode == 'Race') return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
                            return [const Color(0xFF1A237E), const Color(0xFF0D1642)];
                          }

                          Color getGlowColor() {
                            if (mode == 'Klasik') return const Color(0xFF2196F3);
                            if (mode == 'Race') return const Color(0xFF9C27B0);
                            return const Color(0xFF1A237E);
                          }

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMode = mode),
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: mode == 'Klasik' ? 0 : 6,
                                  right: mode == 'Genel' ? 0 : 6,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(colors: getGradient())
                                      : LinearGradient(
                                          colors: isDark
                                            ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                                            : [Colors.white, Colors.grey.shade50],
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? getGlowColor().withOpacity(0.5)
                                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: getGlowColor().withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                                      : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 0.5)],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text(
                                      mode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // İstatistik listesi
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BAR CHART - Premium Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                    ? [const Color(0xFF2D2D2D), const Color(0xFF1E1E1E)]
                                    : [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: StatsBarChart(
                                wins: currentStats['wins'] ?? 0,
                                losses: currentStats['losses'] ?? 0,
                                draws: _calculateDraws(currentStats),
                                isDark: isDark,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OYUNLAR BOLUMU - Section Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFf7971e).withOpacity(0.9), const Color(0xFFffd200).withOpacity(0.9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFf7971e).withOpacity(0.4),
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
                                    child: const Text('🎮', style: TextStyle(fontSize: 20)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Oyun İstatistikleri',
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
                                ],
                              ),
                            ),

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
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [iconColor, iconColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              value == '0' || value == '-' ? '-' : value,
              style: TextStyle(
                fontSize: 20,
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
          ),
        ],
      ),
    );
  }
}
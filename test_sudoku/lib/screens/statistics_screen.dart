import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_localizations.dart';
import '../services/leaderboard_service.dart';

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

    try {
      // Multiplayer stats from LeaderboardService
      final classicStats = await LeaderboardService.getUserModeStats('classic');
      final raceStats = await LeaderboardService.getUserModeStats('race');
      final overallStats = await LeaderboardService.getUserStats();

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

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
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
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _modes.map((mode) {
                      bool isSelected = _selectedMode == mode;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMode = mode),
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
                            mode,
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
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'system_settings_screen.dart';
import '../app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 10),
            Text('Sudoku Clash'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tr('version')}: 1.0.0'),
            const SizedBox(height: 10),
            Text(tr('aboutDesc')),
            const SizedBox(height: 10),
            Text('${tr('features')}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('• ${tr('singlePlayer')}'),
            Text('• ${tr('onlineMultiplayer')}'),
            Text('• ${tr('fourDifficulties')}'),
            Text('• ${tr('notesSystem')}'),
            Text('• ${tr('hintSystem')}'),
            Text('• ${tr('comboScoring')}'),
            const SizedBox(height: 10),
            const Text('© 2024 Sudoku Clash'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 10),
            Text(tr('resetData')),
          ],
        ),
        content: Text(tr('resetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              themeNotifier.toggleTheme(false);
              await AppLocalizations.setLanguage('tr');

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('dataReset')),
                  backgroundColor: Colors.green,
                ),
              );

              setState(() {});
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFİL
          _buildBigColorfulButton(
            icon: Icons.person_rounded,
            title: tr('profile'),
            subtitle: tr('editAccountInfo'),
            colors: [Colors.indigo.shade500, Colors.indigo.shade700],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // İSTATİSTİKLER
          _buildBigColorfulButton(
            icon: Icons.bar_chart_rounded,
            title: tr('statistics'),
            subtitle: tr('viewPerformance'),
            colors: [Colors.red.shade500, Colors.red.shade700],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // LİDERLİK TABLOSU
          _buildBigColorfulButton(
            icon: Icons.emoji_events_rounded,
            title: tr('leaderboard'),
            subtitle: tr('globalRankings'),
            colors: [Colors.amber.shade600, Colors.amber.shade800],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),

          const SizedBox(height: 10),

          // SİSTEM AYARLARI
          _buildBigColorfulButton(
            icon: Icons.settings_rounded,
            title: tr('systemSettings'),
            subtitle: tr('systemSettingsDesc'),
            colors: [Colors.blue.shade500, Colors.blue.shade700],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
              ).then((_) => setState(() {}));
            },
          ),

          const SizedBox(height: 10),

          // OYUN HAKKINDA
          _buildBigColorfulButton(
            icon: Icons.info_rounded,
            title: tr('aboutGame'),
            subtitle: tr('versionAndFeatures'),
            colors: [Colors.green.shade500, Colors.green.shade700],
            onTap: _showAboutDialog,
          ),

          const SizedBox(height: 10),

          // VERİLERİ SIFIRLA
          _buildBigColorfulButton(
            icon: Icons.refresh_rounded,
            title: tr('resetData'),
            subtitle: tr('clearAllStats'),
            colors: [Colors.grey.shade600, Colors.grey.shade800],
            onTap: _showResetDialog,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBigColorfulButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
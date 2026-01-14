import 'package:flutter/material.dart';
import '../main.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import 'system_settings_screen.dart';
import 'achievements_screen.dart';
import 'theme_selector_screen.dart';
import 'badge_selector_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTr = AppLocalizations.currentLanguage == 'tr';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
                : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.indigo.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Gradient with Logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text('🎯', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sudoku Clash',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTr ? 'Dünyanın İlk Online Sudoku Oyunu' : "World's First Online Sudoku Game",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tr('version')}: 1.0.0',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Oyun Modları Section
                      _buildSectionTitle(isTr ? 'Oyun Modları' : 'Game Modes', '🎮', isDark),
                      const SizedBox(height: 10),
                      _buildFeatureItem('👤', isTr ? 'Tek Oyunculu (6 Zorluk Seviyesi)' : 'Single Player (6 Difficulty Levels)', isDark),
                      _buildFeatureItem('⚔️', isTr ? 'Online Klasik (Sıra Tabanlı)' : 'Online Classic (Turn-Based)', isDark),
                      _buildFeatureItem('🏁', isTr ? 'Online Race (Hız Yarışı)' : 'Online Race (Speed Battle)', isDark),
                      _buildFeatureItem('📅', isTr ? 'Günlük Meydan Okuma' : 'Daily Challenge', isDark),

                      const SizedBox(height: 16),

                      // Özellikler Section
                      _buildSectionTitle(isTr ? 'Özellikler' : 'Features', '✨', isDark),
                      const SizedBox(height: 10),
                      _buildFeatureItem('🏆', isTr ? 'Liderlik Tablosu ve Sıralamalar' : 'Leaderboard & Rankings', isDark),
                      _buildFeatureItem('🎖️', isTr ? 'Lig Sistemi (Bronze → Diamond)' : 'League System (Bronze → Diamond)', isDark),
                      _buildFeatureItem('🏅', isTr ? 'Başarımlar ve Rozetler' : 'Achievements & Badges', isDark),
                      _buildFeatureItem('👥', isTr ? 'Arkadaş Sistemi ve Davetler' : 'Friends System & Invites', isDark),
                      _buildFeatureItem('🎨', isTr ? '10 Farklı Oyun Teması' : '10 Different Game Themes', isDark),
                      _buildFeatureItem('📝', isTr ? 'Not Alma Sistemi' : 'Notes System', isDark),
                      _buildFeatureItem('💡', isTr ? 'İpucu Sistemi' : 'Hint System', isDark),
                      _buildFeatureItem('🔥', isTr ? 'Combo Puanlama' : 'Combo Scoring', isDark),

                      const SizedBox(height: 16),

                      // İletişim Section
                      _buildSectionTitle(isTr ? 'İletişim' : 'Contact', '📧', isDark),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 18, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'support@sudokuclash.com',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.language, size: 18, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'www.sudokuclash.com',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Copyright
                      Center(
                        child: Column(
                          children: [
                            Text(
                              isTr ? 'Flutter & Firebase ile geliştirildi' : 'Built with Flutter & Firebase',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2026 Sudoku Clash. All rights reserved.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        tr('ok'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String emoji, bool isDark) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String emoji, String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [Color(0xFF2D2D2D).withOpacity(0.5), Color(0xFF1E1E1E).withOpacity(0.5)]
            : [Colors.blue.shade50, Colors.blue.shade50.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Custom Header
                  Row(
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
                        '⚙️ ${tr('settings')}',
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

                  const SizedBox(height: 24),

                  // 1. PROFİL
                  _buildPremiumSettingsCard(
                    emoji: '👤',
                    title: tr('profile'),
                    subtitle: tr('editAccountInfo'),
                    gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFee5a24)],
                    glowColor: const Color(0xFFFF6B6B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. İSTATİSTİKLER
                  _buildPremiumSettingsCard(
                    emoji: '📊',
                    title: tr('statistics'),
                    subtitle: tr('viewPerformance'),
                    gradientColors: [const Color(0xFFf7971e), const Color(0xFFffd200)],
                    glowColor: const Color(0xFFf7971e),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 3. BAŞARIMLAR
                  _buildPremiumSettingsCard(
                    emoji: '🏆',
                    title: tr('achievements'),
                    subtitle: tr('achievementsDesc'),
                    gradientColors: [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
                    glowColor: const Color(0xFFFFD700),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 4. ROZETLER
                  _buildPremiumSettingsCard(
                    emoji: '🎖️',
                    title: AppLocalizations.currentLanguage == 'tr' ? 'Rozetler' : 'Badges',
                    subtitle: AppLocalizations.currentLanguage == 'tr' ? 'Rozet seç ve göster' : 'Select and display badges',
                    gradientColors: [const Color(0xFF56ab2f), const Color(0xFFa8e063)],
                    glowColor: const Color(0xFF56ab2f),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BadgeSelectorScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 5. OYUN TEMALARI
                  _buildPremiumSettingsCard(
                    emoji: '🎨',
                    title: AppLocalizations.currentLanguage == 'tr' ? 'Oyun Temaları' : 'Game Themes',
                    subtitle: AppLocalizations.currentLanguage == 'tr' ? 'Tahta renk temasını değiştir' : 'Change board color theme',
                    gradientColors: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                    glowColor: const Color(0xFF4facfe),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ThemeSelectorScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 6. SİSTEM AYARLARI
                  _buildPremiumSettingsCard(
                    emoji: '🔧',
                    title: tr('systemSettings'),
                    subtitle: tr('systemSettingsDesc'),
                    gradientColors: [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
                    glowColor: const Color(0xFFa18cd1),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
                      ).then((_) => setState(() {}));
                    },
                  ),

                  const SizedBox(height: 14),

                  // 7. OYUN HAKKINDA
                  _buildPremiumSettingsCard(
                    emoji: 'ℹ️',
                    title: tr('aboutGame'),
                    subtitle: tr('versAndFeatures'),
                    gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    glowColor: const Color(0xFF667eea),
                    onTap: _showAboutDialog,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSettingsCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
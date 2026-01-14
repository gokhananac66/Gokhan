// BACKUP - 14 Ocak 2026
// Kullanıcı "eskiye dön" derse bu dosyayı home_screen.dart olarak geri yükle
//
// Bu tasarım:
// - Açık mavi gradient arka plan
// - Daily Challenge (turuncu) ve Leaderboard (mor) yan yana kartlar
// - Tek Oyuncu (mavi), Online Multiplayer (turuncu), Mağaza (mor), Ayarlar (gri) butonları
// - Her buton gradient + glow shadow ile
//
// GERİ YÜKLEMEK İÇİN:
// 1. Bu dosyanın içeriğini kopyala
// 2. home_screen.dart dosyasına yapıştır

/*
=== MEVCUT TASARIM KODLARI ===

BUILD METHOD:
-------------
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [const Color(0xFF1A237E), const Color(0xFF121212), const Color(0xFF121212)]
            : [const Color(0xFF90CAF9), const Color(0xFFE3F2FD), Colors.grey.shade50],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Logo
                Image.asset(
                  'assets/images/SUDOKU_CLASH_LOGO.png',
                  width: 340,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                // DAILY CHALLENGE & LEADERBOARD - YAN YANA
                Row(
                  children: [
                    Expanded(child: _buildDailyChallengeCardCompact()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLeaderboardCardCompact()),
                  ],
                ),
                const SizedBox(height: 16),

                // TEK OYUNCU - MAVİ
                _buildMenuCard(
                  icon: Icons.person_rounded,
                  title: tr('singlePlayer'),
                  subtitle: tr('singlePlayerDesc'),
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  badge: _hasSavedGame ? '⏸️' : null,
                  onTap: _showSinglePlayerDialog,
                ),
                const SizedBox(height: 16),

                // ONLINE MULTIPLAYER - TURUNCU
                _buildMenuCard(
                  icon: Icons.public_rounded,
                  title: tr('onlineMultiplayer'),
                  subtitle: tr('onlineMultiplayerDesc'),
                  colors: [Colors.orange.shade500, Colors.orange.shade700],
                  onTap: _showOnlineDialog,
                ),
                const SizedBox(height: 16),

                // MAĞAZA - MOR
                _buildMenuCard(
                  icon: Icons.shopping_cart_rounded,
                  title: tr('shop'),
                  subtitle: tr('shopDesc'),
                  colors: [Colors.purple.shade500, Colors.purple.shade700],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShopScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // AYARLAR - GRİ
                _buildMenuCard(
                  icon: Icons.settings_rounded,
                  title: tr('settings'),
                  subtitle: tr('settingsDesc'),
                  colors: [Colors.grey.shade600, Colors.grey.shade800],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

_buildMenuCard METODU:
----------------------
Widget _buildMenuCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Color> colors,
  String? badge,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    ),
  );
}

_buildLeaderboardCardCompact METODU:
------------------------------------
Widget _buildLeaderboardCardCompact() {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
              ? [Color(0xFF5E35B1), Color(0xFF311B92)]
              : [Color(0xFF7E57C2), Color(0xFF512DA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7E57C2).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('🏆', style: TextStyle(fontSize: 20)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, size: 12, color: Colors.deepPurple.shade900),
                      Text('TOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(tr('leaderboard'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(tr('globalRankings'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 12),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

*/

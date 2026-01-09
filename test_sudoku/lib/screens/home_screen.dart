import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'lobby_screen.dart';
import 'friends_screen.dart';
import '../app_localizations.dart';
import '../services/progression_service.dart';
import '../services/user_status_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedDifficulty = 'Orta';
  User? _user;
  bool _hasSavedGame = false;
  String _savedGameDifficulty = '';

  List<Map<String, dynamic>> get difficulties => [
    {'name': tr('easy'), 'key': 'Kolay', 'emoji': '😊', 'description': tr('easyDesc')},
    {'name': tr('medium'), 'key': 'Orta', 'emoji': '😐', 'description': tr('mediumDesc')},
    {'name': tr('hard'), 'key': 'Zor', 'emoji': '😣', 'description': tr('hardDesc')},
    {'name': tr('expert'), 'key': 'Uzman', 'emoji': '🤯', 'description': tr('expertDesc')},
    {'name': tr('master'), 'key': 'Usta', 'emoji': '🔥', 'description': tr('masterDesc')},
    {'name': tr('extreme'), 'key': 'Ekstrem', 'emoji': '💀', 'description': tr('extremeDesc')},
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _checkSavedGame();

    // Set status to idle when on home screen
    UserStatusService().updateStatus(UserStatus.idle);
  }

  Future<void> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSaved = prefs.getBool('hasSavedGame') ?? false;

    if (hasSaved) {
      final savedData = prefs.getString('savedGame');
      if (savedData != null) {
        try {
          final diffMatch = RegExp(r'"difficulty":"([^"]+)"').firstMatch(savedData);
          if (diffMatch != null) {
            setState(() {
              _hasSavedGame = true;
              _savedGameDifficulty = diffMatch.group(1) ?? '';
            });
            return;
          }
        } catch (e) {
          print('Saved game check error: $e');
        }
      }
    }

    setState(() {
      _hasSavedGame = false;
      _savedGameDifficulty = '';
    });
  }

  String _getLocalizedDifficulty(String key) {
    switch (key) {
      case 'Kolay': return tr('easy');
      case 'Orta': return tr('medium');
      case 'Zor': return tr('hard');
      case 'Uzman': return tr('expert');
      case 'Usta': return tr('master');
      case 'Ekstrem': return tr('extreme');
      default: return key;
    }
  }

  void _showSinglePlayerDialog() {
    String tempDifficulty = selectedDifficulty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: Colors.blue.shade700, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(tr('singlePlayer'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(tr('selectDifficulty'), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  ...difficulties.map((diff) => _buildDifficultyOption(diff, tempDifficulty, (selected) {
                    setDialogState(() => tempDifficulty = selected);
                  })),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => selectedDifficulty = tempDifficulty);
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              gameMode: GameMode.single,
                              difficulty: tempDifficulty,
                              continueGame: false,
                            ),
                          ),
                        ).then((_) => _checkSavedGame());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 28),
                          const SizedBox(width: 8),
                          Text(tr('newGame'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  if (_hasSavedGame) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameScreen(
                                gameMode: GameMode.single,
                                difficulty: _savedGameDifficulty,
                                continueGame: true,
                              ),
                            ),
                          ).then((_) => _checkSavedGame());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline, size: 28),
                            const SizedBox(width: 8),
                            Text('${tr('continue')} (${_getLocalizedDifficulty(_savedGameDifficulty)})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOnlineDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.public, color: Colors.orange.shade700, size: 32),
              ),
              const SizedBox(height: 12),
              Text(tr('onlineMultiplayer'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tr('selectGameMode'), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              // Rastgele Rakip Bul
              _buildOnlineOption(
                icon: Icons.shuffle,
                title: tr('randomOpponent'),
                subtitle: tr('randomOpponentDesc'),
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showDifficultyDialog(isRandom: true);
                },
              ),

              const SizedBox(height: 12),

              // Arkadaşla Oyna
              _buildOnlineOption(
                icon: Icons.people,
                title: tr('playWithFriend'),
                subtitle: tr('playWithFriendDesc'),
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  // Direkt arkadaşlar ekranına git, zorluk seçme!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendsScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyDialog({required bool isRandom}) {
    String tempDifficulty = selectedDifficulty;
    String tempGameMode = 'classic'; // Default to classic

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRandom ? Colors.orange.shade100 : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRandom ? Icons.shuffle : Icons.people,
                      color: isRandom ? Colors.orange.shade700 : Colors.green.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRandom ? tr('randomOpponent') : tr('playWithFriend'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Game Mode Selection (only for random)
                  if (isRandom) ...[
                    const SizedBox(height: 20),
                    Text('Oyun Modu Seç', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => tempGameMode = 'classic'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: tempGameMode == 'classic'
                                    ? [Color(0xFF2196F3), Color(0xFF1976D2)]
                                    : [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tempGameMode == 'classic' ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: tempGameMode == 'classic' ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.sports_esports, color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Text('⚔️ Klasik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Sırayla', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                  Text('30s turlar', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => tempGameMode = 'race'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: tempGameMode == 'race'
                                    ? [Color(0xFF9C27B0), Color(0xFF7B1FA2)]
                                    : [Color(0xFFBA68C8), Color(0xFFAB47BC)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tempGameMode == 'race' ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: tempGameMode == 'race' ? [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.speed, color: Colors.white, size: 32),
                                  const SizedBox(height: 8),
                                  Text('🏁 Race', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Aynı anda', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                  Text('İlk bitiren kazanır', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  Text(tr('selectDifficulty'), style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...difficulties.map((diff) => _buildDifficultyOption(diff, tempDifficulty, (selected) {
                    setDialogState(() => tempDifficulty = selected);
                  })),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => selectedDifficulty = tempDifficulty);
                        Navigator.pop(context);

                        if (isRandom) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LobbyScreen(difficulty: tempDifficulty, gameMode: tempGameMode)),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FriendsScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRandom ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isRandom ? Icons.search : Icons.people, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isRandom ? tr('findOpponent') : tr('viewFriends'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(Map<String, dynamic> diff, String currentSelection, Function(String) onSelect) {
    bool isSelected = currentSelection == diff['key'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<bool>(
      future: ProgressionService.isLocked(diff['key']),
      builder: (context, snapshot) {
        final isLocked = snapshot.data ?? false;

        return FutureBuilder<int>(
          future: isLocked ? ProgressionService.getRemainingWinsToUnlock(diff['key']) : Future.value(0),
          builder: (context, remainingSnapshot) {
            final remaining = remainingSnapshot.data ?? 0;
            final unlockInfo = ProgressionService.getUnlockInfo(diff['key']);

            return Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: InkWell(
                onTap: isLocked ? null : () => onSelect(diff['key']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : (isDark ? Colors.grey.shade800 : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue.shade200, width: 2)
                        : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Text(diff['emoji'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(diff['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isSelected ? Colors.blue.shade700 : null)),
                                if (isLocked) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                                ],
                              ],
                            ),
                            if (isLocked && unlockInfo != null)
                              Text(
                                '${_getLocalizedDifficulty(unlockInfo['previousLevel'])} ${tr('win')} $remaining ${tr('more')}',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                              )
                            else
                              Text(diff['description'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      if (isSelected && !isLocked) Icon(Icons.check_circle, color: Colors.blue.shade600),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.extension, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 30),

                // Başlık
                Text(
                  tr('sudoku'),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                Text(
                  tr('clash'),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('tagline'),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, letterSpacing: 1),
                ),
                const SizedBox(height: 50),

                // TEK OYUNCU
                _buildMenuCard(
                  icon: Icons.person_rounded,
                  title: tr('singlePlayer'),
                  subtitle: tr('singlePlayerDesc'),
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  badge: _hasSavedGame ? '⏸️' : null,
                  onTap: _showSinglePlayerDialog,
                ),
                const SizedBox(height: 16),

                // ONLINE MULTIPLAYER
                _buildMenuCard(
                  icon: Icons.public_rounded,
                  title: tr('onlineMultiplayer'),
                  subtitle: tr('onlineMultiplayerDesc'),
                  colors: [Colors.orange.shade500, Colors.orange.shade700],
                  onTap: _showOnlineDialog,
                ),
                const SizedBox(height: 16),

                // AYARLAR
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
    );
  }

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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
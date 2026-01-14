import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'lobby_screen.dart';
import 'friends_screen.dart';
import 'daily_challenge_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';
import '../app_localizations.dart';
import '../services/progression_service.dart';
import '../services/user_status_service.dart';
import '../services/friend_service.dart';
import '../services/daily_challenge_service.dart';
import '../widgets/sudoku_clash_logo.dart';

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
    {'name': tr('easy'), 'key': 'Kolay', 'emoji': '😊', 'description': tr('easyDesc'), 'colors': [Color(0xFF4CAF50), Color(0xFF2E7D32)], 'stars': 1},
    {'name': tr('medium'), 'key': 'Orta', 'emoji': '😐', 'description': tr('mediumDesc'), 'colors': [Color(0xFF2196F3), Color(0xFF1565C0)], 'stars': 2},
    {'name': tr('hard'), 'key': 'Zor', 'emoji': '😣', 'description': tr('hardDesc'), 'colors': [Color(0xFFFF9800), Color(0xFFE65100)], 'stars': 3},
    {'name': tr('expert'), 'key': 'Uzman', 'emoji': '🤯', 'description': tr('expertDesc'), 'colors': [Color(0xFFE91E63), Color(0xFFC2185B)], 'stars': 4},
    {'name': tr('master'), 'key': 'Usta', 'emoji': '🔥', 'description': tr('masterDesc'), 'colors': [Color(0xFF9C27B0), Color(0xFF6A1B9A)], 'stars': 5},
    {'name': tr('extreme'), 'key': 'Ekstrem', 'emoji': '💀', 'description': tr('extremeDesc'), 'colors': [Color(0xFF212121), Color(0xFF000000)], 'stars': 6},
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    // Set online status immediately on app start
    FriendService().setOnlineStatus(true);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                  ? [Color(0xFF1E3A5F), Color(0xFF0D1B2A), Color(0xFF0D1B2A)]
                  : [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      // Animated Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text('🎮', style: TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('singlePlayer'),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black38),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tr('selectDifficulty'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Difficulty Grid
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 2x3 Grid for difficulties
                        for (int i = 0; i < difficulties.length; i += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDifficultyCard(
                                    difficulties[i],
                                    tempDifficulty,
                                    (selected) => setDialogState(() => tempDifficulty = selected),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: i + 1 < difficulties.length
                                    ? _buildDifficultyCard(
                                        difficulties[i + 1],
                                        tempDifficulty,
                                        (selected) => setDialogState(() => tempDifficulty = selected),
                                      )
                                    : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Play Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(tr('newGame'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      if (_hasSavedGame) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
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
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle_outline, size: 24, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('${tr('continue')} (${_getLocalizedDifficulty(_savedGameDifficulty)})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('cancel'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(Map<String, dynamic> diff, String currentSelection, Function(String) onSelect) {
    bool isSelected = currentSelection == diff['key'];
    List<Color> colors = diff['colors'] as List<Color>;
    int stars = diff['stars'] as int;

    return FutureBuilder<bool>(
      future: ProgressionService.isLocked(diff['key']),
      builder: (context, snapshot) {
        final isLocked = snapshot.data ?? false;

        return FutureBuilder<int>(
          future: isLocked ? ProgressionService.getRemainingWinsToUnlock(diff['key']) : Future.value(0),
          builder: (context, remainingSnapshot) {
            final remaining = remainingSnapshot.data ?? 0;
            final unlockInfo = ProgressionService.getUnlockInfo(diff['key']);

            return GestureDetector(
              onTap: isLocked ? null : () => onSelect(diff['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLocked
                      ? [Colors.grey.shade600, Colors.grey.shade800]
                      : colors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: colors[0].withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                transform: isSelected ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(diff['emoji'], style: TextStyle(fontSize: isSelected ? 36 : 32)),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock, color: Colors.white, size: 20),
                          ),
                        if (isSelected && !isLocked)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Icon(Icons.check, color: colors[0], size: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Text(
                      diff['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black38)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(stars, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(Icons.star, size: 12, color: Colors.amber.shade300),
                      )),
                    ),
                    if (isLocked && unlockInfo != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$remaining ${tr('more')}',
                          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOnlineDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [Color(0xFF2D1B4E), Color(0xFF1A1A2E), Color(0xFF16213E)]
                : [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.purple : Colors.deepPurple).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated background
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    // Animated Globe Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Text('🌍', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 20),
                    // Title with glow
                    Text(
                      tr('onlineMultiplayer'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(offset: Offset(2, 2), blurRadius: 8, color: Colors.black45),
                          Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.white.withOpacity(0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        tr('selectGameMode'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Options
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Rastgele Rakip - Orange/Amber Theme
                    _buildOnlineOptionCard(
                      emoji: '⚔️',
                      title: tr('randomOpponent'),
                      subtitle: tr('randomOpponentDesc'),
                      gradientColors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      glowColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showDifficultyDialog(isRandom: true);
                      },
                    ),

                    const SizedBox(height: 14),

                    // Arkadaşla Oyna - Green Theme
                    _buildOnlineOptionCard(
                      emoji: '👥',
                      title: tr('playWithFriend'),
                      subtitle: tr('playWithFriendDesc'),
                      gradientColors: [Color(0xFF00C853), Color(0xFF009624)],
                      glowColor: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FriendsScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        tr('cancel'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineOptionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow with glow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyDialog({required bool isRandom}) {
    String tempDifficulty = selectedDifficulty;
    String tempGameMode = 'classic';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                  ? [Color(0xFF3D2914), Color(0xFF1A1A1A), Color(0xFF1A1A1A)]
                  : [Color(0xFFFF9800), Color(0xFFF57C00), Color(0xFFE65100)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text('⚔️', style: TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('randomOpponent'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black38),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Game Mode Selection
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Oyun Modu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Classic Mode
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => tempGameMode = 'classic'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: tempGameMode == 'classic'
                                      ? [Color(0xFF2196F3), Color(0xFF1565C0)]
                                      : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tempGameMode == 'classic' ? Colors.white : Colors.white.withOpacity(0.3),
                                    width: tempGameMode == 'classic' ? 2 : 1,
                                  ),
                                  boxShadow: tempGameMode == 'classic' ? [
                                    BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 1),
                                  ] : [],
                                ),
                                child: Column(
                                  children: [
                                    Text('⚔️', style: TextStyle(fontSize: 28)),
                                    const SizedBox(height: 6),
                                    Text('Klasik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Sırayla oyna', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Race Mode
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => tempGameMode = 'race'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: tempGameMode == 'race'
                                      ? [Color(0xFF9C27B0), Color(0xFF6A1B9A)]
                                      : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tempGameMode == 'race' ? Colors.white : Colors.white.withOpacity(0.3),
                                    width: tempGameMode == 'race' ? 2 : 1,
                                  ),
                                  boxShadow: tempGameMode == 'race' ? [
                                    BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 10, spreadRadius: 1),
                                  ] : [],
                                ),
                                child: Column(
                                  children: [
                                    Text('🏁', style: TextStyle(fontSize: 28)),
                                    const SizedBox(height: 6),
                                    Text('Race', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('İlk bitiren kazanır', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Difficulty Selection Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr('selectDifficulty'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Difficulty Grid
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < difficulties.length; i += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDifficultyCard(
                                    difficulties[i],
                                    tempDifficulty,
                                    (selected) => setDialogState(() => tempDifficulty = selected),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: i + 1 < difficulties.length
                                    ? _buildDifficultyCard(
                                        difficulties[i + 1],
                                        tempDifficulty,
                                        (selected) => setDialogState(() => tempDifficulty = selected),
                                      )
                                    : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Find Opponent Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => selectedDifficulty = tempDifficulty);
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LobbyScreen(difficulty: tempDifficulty, gameMode: tempGameMode)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_rounded, size: 26, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(tr('findOpponent'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('cancel'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

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

                  // Logo with glow effect
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.blue : Colors.white).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/SUDOKU_CLASH_LOGO.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions Row - Daily & Leaderboard
                  Row(
                    children: [
                      Expanded(child: _buildQuickActionCard(
                        emoji: '📅',
                        title: 'Daily',
                        subtitle: DailyChallengeService.getLocalizedDifficulty(DailyChallengeService.getTodayDifficulty()),
                        gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFee5a24)],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyChallengeScreen())).then((_) => setState(() {}));
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildQuickActionCard(
                        emoji: '🏆',
                        title: tr('leaderboard'),
                        subtitle: tr('globalRankings'),
                        gradientColors: [const Color(0xFFf7971e), const Color(0xFFffd200)],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Main Game Buttons
                  _buildPremiumGameCard(
                    emoji: '🎮',
                    title: tr('singlePlayer'),
                    subtitle: tr('singlePlayerDesc'),
                    gradientColors: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                    glowColor: const Color(0xFF4facfe),
                    hasBadge: _hasSavedGame,
                    onTap: _showSinglePlayerDialog,
                  ),
                  const SizedBox(height: 14),

                  _buildPremiumGameCard(
                    emoji: '⚔️',
                    title: tr('onlineMultiplayer'),
                    subtitle: tr('onlineMultiplayerDesc'),
                    gradientColors: [const Color(0xFFfa709a), const Color(0xFFfee140)],
                    glowColor: const Color(0xFFfa709a),
                    onTap: _showOnlineDialog,
                  ),
                  const SizedBox(height: 14),

                  // Secondary Actions Row
                  Row(
                    children: [
                      Expanded(child: _buildSecondaryCard(
                        emoji: '🛒',
                        title: tr('shop'),
                        gradientColors: [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()));
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSecondaryCard(
                        emoji: '⚙️',
                        title: tr('settings'),
                        gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => setState(() {}));
                        },
                      )),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Quick Action Card (Daily & Leaderboard)
  Widget _buildQuickActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 115,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black45),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black38),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Premium Game Card (Single & Multiplayer)
  Widget _buildPremiumGameCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color glowColor,
    bool hasBadge = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
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
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Emoji Container with glass effect
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(width: 18),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black45),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Saved game badge
            if (hasBadge)
              Positioned(
                top: -10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00b894), Color(0xFF00cec9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_circle_filled, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        tr('continue'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Secondary Card (Shop & Settings)
  Widget _buildSecondaryCard({
    required String emoji,
    required String title,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black45),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
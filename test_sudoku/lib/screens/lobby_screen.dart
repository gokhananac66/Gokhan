import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/matchmaking_service.dart';
import '../app_localizations.dart';
import 'online_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String difficulty;
  final String gameMode;

  const LobbyScreen({
    super.key,
    required this.difficulty,
    this.gameMode = 'classic',
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with SingleTickerProviderStateMixin {
  final _matchmakingService = MatchmakingService();

  bool _isSearching = true;
  String _statusText = '';
  int _searchSeconds = 0;

  late AnimationController _animController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_animController);

    _statusText = tr('searchingOpponent');
    _startMatchmaking();
    _startTimer();
  }

  @override
  void dispose() {
    _animController.dispose();
    _matchmakingService.cancelMatchmaking();
    _matchmakingService.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isSearching) return false;
      setState(() => _searchSeconds++);
      return true;
    });
  }

  Future<void> _startMatchmaking() async {
    print('🔴 [LOBBY] Starting matchmaking with difficulty: ${widget.difficulty}, gameMode: ${widget.gameMode}');

    try {
      await _matchmakingService.startMatchmaking(
        difficulty: widget.difficulty,
        gameMode: widget.gameMode,
        onMatch: (result) async {
          print('🟢 [LOBBY] Match found! gameId: ${result.gameId}');
        if (!mounted) return;

        setState(() {
          _isSearching = false;
          _statusText = tr('matchFound');
        });

        // Fetch game data to get difficulty and gameMode
        final gameSnapshot = await FirebaseDatabase.instance.ref('games/${result.gameId}').get();
        final gameData = gameSnapshot.exists ? Map<String, dynamic>.from(gameSnapshot.value as Map) : null;
        final difficulty = gameData?['difficulty'] ?? widget.difficulty;
        final gameMode = gameData?['gameMode'] ?? 'classic';

        // Kısa bir gecikme sonra oyuna git
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnlineGameScreen(
                gameId: result.gameId!,
                isPlayer1: result.isPlayer1,
                difficulty: difficulty,
                gameMode: gameMode,
                startsFirst: result.isPlayer1,
              ),
            ),
          );
        });
      },
      onTimeoutCallback: () {
        print('🟡 [LOBBY] Matchmaking timeout');
        if (!mounted) return;

        setState(() {
          _isSearching = false;
          _statusText = 'Rakip bulunamadı';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şu an uygun rakip yok. Daha sonra tekrar dene.'),
            backgroundColor: Colors.orange,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      },
      onWaitTime: (seconds) {
        // Her 2 saniyede log at
        if (seconds % 10 == 0) {
          print('🔵 [LOBBY] Waiting for $seconds seconds...');
        }
      },
    );
    } catch (e, stackTrace) {
      print('❌ [LOBBY] Error starting matchmaking: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusText = 'Bağlantı hatası';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Matchmaking başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  void _cancelSearch() {
    _matchmakingService.cancelMatchmaking();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isClassicMode = widget.gameMode == 'classic';
    final Color accentColor = isClassicMode ? const Color(0xFF2196F3) : const Color(0xFF9C27B0);
    final locale = AppLocalizations.currentLanguage;

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
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Geri Butonu
                    GestureDetector(
                      onTap: _cancelSearch,
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
                      isClassicMode
                          ? '⚔️ ${locale == 'tr' ? 'Klasik Mod' : 'Classic Mode'}'
                          : '🏁 ${locale == 'tr' ? 'Race Mod' : 'Race Mode'}',
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

              // İçerik
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated search icon with premium design
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isClassicMode
                                    ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
                                    : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Status text with premium styling
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Timer with premium badge
                        if (_isSearching)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                                    : [Colors.white, Colors.grey.shade50],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: accentColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(_searchSeconds),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Difficulty and Mode badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFFF9800), const Color(0xFFF57C00)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Text('📊', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.difficulty,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isClassicMode
                                      ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
                                      : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(isClassicMode ? '⚔️' : '🏁', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    isClassicMode
                                        ? (locale == 'tr' ? 'Klasik' : 'Classic')
                                        : 'Race',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 60),

                        // Cancel button with premium design
                        if (_isSearching)
                          GestureDetector(
                            onTap: _cancelSearch,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFE53935), const Color(0xFFC62828)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE53935).withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    tr('cancelSearch'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
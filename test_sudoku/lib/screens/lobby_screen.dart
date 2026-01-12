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
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => OnlineGameScreen(
                gameId: result.gameId!,
                isPlayer1: result.isPlayer1,
                difficulty: difficulty,
                gameMode: gameMode,
                startsFirst: result.isPlayer1,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Fade + Scale transition
                const curve = Curves.easeInOutCubic;
                var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: curve),
                );
                var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: curve),
                );
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF2D2D44),
                    const Color(0xFF16213E),
                  ]
                : widget.gameMode == 'classic'
                  ? [
                      const Color(0xFF2196F3),
                      const Color(0xFF1976D2),
                      const Color(0xFF64B5F6),
                    ]
                  : [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                      const Color(0xFFF093FB),
                    ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern animated search icon with pulse effect
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF667EEA),
                            const Color(0xFF764BA2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: const Color(0xFF764BA2).withOpacity(0.4),
                            blurRadius: 60,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Modern status text with shadow
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Modern timer with glow
                  if (_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667EEA).withOpacity(0.3),
                            const Color(0xFF764BA2).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        _formatTime(_searchSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Modern difficulty badge with gradient
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tr('difficulty')}: ${widget.difficulty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Modern cancel button with gradient
                  if (_isSearching)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _cancelSearch,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    tr('cancelSearch'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}
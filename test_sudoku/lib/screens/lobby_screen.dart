import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/matchmaking_service.dart';
import '../app_localizations.dart';
import 'online_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String difficulty;

  const LobbyScreen({
    super.key,
    required this.difficulty,
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
    await _matchmakingService.startMatchmaking(
      difficulty: widget.difficulty,
      onMatch: (result) async {
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
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated search icon
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade700],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Status text
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Timer
                if (_isSearching)
                  Text(
                    _formatTime(_searchSeconds),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                const SizedBox(height: 12),

                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tr('difficulty')}: ${widget.difficulty}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Cancel button
                if (_isSearching)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cancelSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        tr('cancelSearch'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
}
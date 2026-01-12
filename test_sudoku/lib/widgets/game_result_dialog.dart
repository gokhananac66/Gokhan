import 'package:flutter/material.dart';
import 'dart:math';
import '../app_localizations.dart';

class GameResultDialog extends StatefulWidget {
  final bool isWin;
  final bool isDraw;
  final int score;
  final int time;
  final int errors;
  final int maxErrors;
  final int combo;
  final bool isPerfect;
  final String? winnerName;
  final bool isMultiplayer;
  final int? player1Score;
  final int? player2Score;
  final String? player1Name;
  final String? player2Name;
  final int? player1Time;
  final int? player2Time;
  final int? player1Moves;
  final int? player2Moves;
  final int? player1Accuracy;
  final int? player2Accuracy;
  final int? player1Errors;
  final int? player2Errors;
  final String? gameMode;
  final String? difficulty;
  final VoidCallback onNewGame;
  final VoidCallback onMainMenu;
  final VoidCallback? onRematch;

  const GameResultDialog({
    super.key,
    required this.isWin,
    this.isDraw = false,
    required this.score,
    required this.time,
    required this.errors,
    required this.maxErrors,
    this.combo = 0,
    this.isPerfect = false,
    this.winnerName,
    this.isMultiplayer = false,
    this.player1Score,
    this.player2Score,
    this.player1Name,
    this.player2Name,
    this.player1Time,
    this.player2Time,
    this.player1Moves,
    this.player2Moves,
    this.player1Accuracy,
    this.player2Accuracy,
    this.player1Errors,
    this.player2Errors,
    this.gameMode,
    this.difficulty,
    required this.onNewGame,
    required this.onMainMenu,
    this.onRematch,
  });

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;

  final List<Confetti> _confettiPieces = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.isWin || widget.isDraw) {
      _generateConfetti();
      _confettiController.repeat();
    }

    _scaleController.forward();
  }

  void _generateConfetti() {
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(Confetti(
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
        ][_random.nextInt(8)],
        x: _random.nextDouble(),
        y: _random.nextDouble() * -1,
        speed: 0.5 + _random.nextDouble() * 1.5,
        size: 8 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * 360,
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Gradient colors based on result
    List<Color> headerGradient;

    if (widget.isDraw) {
      headerGradient = [const Color(0xFF1976D2), const Color(0xFF42A5F5)];
    } else if (widget.isWin) {
      headerGradient = [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
    } else {
      headerGradient = [const Color(0xFFC62828), const Color(0xFFEF5350)];
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Konfeti
          if (widget.isWin || widget.isDraw)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(320, 500),
                  painter: ConfettiPainter(
                    confetti: _confettiPieces,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),

          // Ana kart
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: headerGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Trophy/emoji
                        Text(
                          widget.isDraw ? '🤝' : (widget.isWin ? '🏆' : '😢'),
                          style: const TextStyle(fontSize: 56),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          widget.isDraw
                              ? 'Berabere!'
                              : (widget.isWin ? 'Kazandın!' : 'Kaybettin!'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Game mode badge
                        if (widget.gameMode != null || widget.difficulty != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.gameMode == 'race' ? '🏁 Race' : '⚔️ Klasik'} · ${widget.difficulty ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Multiplayer player card
                        if (widget.isMultiplayer && widget.player2Name != null) ...[
                          _buildPlayerCard(),
                          const SizedBox(height: 16),
                        ],

                        // Stats
                        widget.isMultiplayer
                            ? _buildMultiplayerStats()
                            : _buildSinglePlayerStats(),

                        const SizedBox(height: 20),

                        // Buttons
                        if (widget.isMultiplayer)
                          _buildMultiplayerButtons()
                        else
                          _buildSinglePlayerButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    String opponentName = widget.isWin
        ? (widget.player2Name ?? 'Rakip')
        : (widget.player1Name ?? 'Rakip');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                opponentName.isNotEmpty ? opponentName[0].toUpperCase() : 'R',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Rakip',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // VS badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerStats() {
    return Column(
      children: [
        _buildStatComparison(
          '⏱️',
          'Süre',
          _formatTime(widget.time),
          widget.player2Time != null ? _formatTime(widget.player2Time!) : '--:--',
          widget.time < (widget.player2Time ?? widget.time + 1),
        ),
        const SizedBox(height: 10),
        _buildStatComparison(
          '🎯',
          'Hamle',
          '${widget.player1Moves ?? widget.score}',
          '${widget.player2Moves ?? widget.player2Score ?? 0}',
          (widget.player1Moves ?? 0) < (widget.player2Moves ?? 999),
        ),
        const SizedBox(height: 10),
        _buildStatComparison(
          '✨',
          'İsabet',
          '${widget.player1Accuracy ?? 95}%',
          '${widget.player2Accuracy ?? 92}%',
          (widget.player1Accuracy ?? 0) > (widget.player2Accuracy ?? 0),
        ),
        const SizedBox(height: 10),
        _buildStatComparison(
          '❌',
          'Hata',
          '${widget.player1Errors ?? widget.errors}',
          '${widget.player2Errors ?? 0}',
          (widget.player1Errors ?? widget.errors) < (widget.player2Errors ?? 999),
        ),
      ],
    );
  }

  Widget _buildStatComparison(String emoji, String label, String myValue, String opponentValue, bool isBetter) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // My value
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isBetter ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBetter ? Colors.green : Colors.grey.shade300,
                width: isBetter ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBetter) ...[
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  myValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBetter ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Opponent value
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: !isBetter ? Colors.orange.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: !isBetter ? Colors.orange : Colors.grey.shade300,
                width: !isBetter ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isBetter) ...[
                  Icon(Icons.check_circle, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  opponentValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !isBetter ? Colors.orange.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePlayerStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow('🎯', 'Skor', '${widget.score}', isHighlight: true),
          const SizedBox(height: 12),
          _buildStatRow('⏱️', 'Süre', _formatTime(widget.time)),
          const SizedBox(height: 12),
          _buildStatRow('❌', 'Hatalar', '${widget.errors}/${widget.maxErrors}'),
          if (widget.combo > 1) ...[
            const SizedBox(height: 12),
            _buildStatRow('🔥', 'Max Combo', '${widget.combo}x'),
          ],
          if (widget.isPerfect && widget.isWin) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Text(
                    'HATASIZ!',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('⭐', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isHighlight ? 24 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplayerButtons() {
    return Row(
      children: [
        // Kapat button
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onMainMenu,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr('close'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Rövanş button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: widget.onRematch ?? widget.onNewGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${tr('rematch')}! 🔥',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinglePlayerButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onNewGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isWin ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 6),
                Text(
                  widget.isWin ? tr('newGame') : tr('tryAgain'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onMainMenu,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  tr('mainMenu'),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Konfeti modeli
class Confetti {
  Color color;
  double x;
  double y;
  double speed;
  double size;
  double rotation;

  Confetti({
    required this.color,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
  });
}

// Konfeti painter
class ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;

  ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confetti) {
      final paint = Paint()..color = piece.color;

      double currentY = piece.y + (progress * piece.speed * 2);
      if (currentY > 1.5) currentY = currentY - 2.5;

      double x = piece.x * size.width + sin(progress * 10 + piece.rotation) * 20;
      double y = currentY * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * piece.rotation * 0.1);

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Kolay kullanım için helper fonksiyonlar
void showWinDialog(
    BuildContext context, {
      required int score,
      required int time,
      required int errors,
      required int maxErrors,
      int combo = 0,
      bool isPerfect = false,
      required VoidCallback onNewGame,
      required VoidCallback onMainMenu,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => GameResultDialog(
      isWin: true,
      score: score,
      time: time,
      errors: errors,
      maxErrors: maxErrors,
      combo: combo,
      isPerfect: isPerfect,
      onNewGame: onNewGame,
      onMainMenu: onMainMenu,
    ),
  );
}

void showLoseDialog(
    BuildContext context, {
      required int score,
      required int time,
      required int errors,
      required int maxErrors,
      required VoidCallback onNewGame,
      required VoidCallback onMainMenu,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => GameResultDialog(
      isWin: false,
      score: score,
      time: time,
      errors: errors,
      maxErrors: maxErrors,
      onNewGame: onNewGame,
      onMainMenu: onMainMenu,
    ),
  );
}

void showMultiplayerResultDialog(
    BuildContext context, {
      required int player1Score,
      required int player2Score,
      required String player1Name,
      required String player2Name,
      required int time,
      String? gameMode,
      String? difficulty,
      int? player1Errors,
      int? player2Errors,
      required VoidCallback onNewGame,
      required VoidCallback onMainMenu,
      VoidCallback? onRematch,
    }) {
  bool iWon = player1Score > player2Score;
  bool isDraw = player1Score == player2Score;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => GameResultDialog(
      isWin: iWon,
      isDraw: isDraw,
      score: player1Score,
      time: time,
      errors: player1Errors ?? 0,
      maxErrors: 5,
      isMultiplayer: true,
      player1Score: player1Score,
      player2Score: player2Score,
      player1Name: player1Name,
      player2Name: player2Name,
      player1Errors: player1Errors,
      player2Errors: player2Errors,
      gameMode: gameMode,
      difficulty: difficulty,
      onNewGame: onNewGame,
      onMainMenu: onMainMenu,
      onRematch: onRematch,
    ),
  );
}

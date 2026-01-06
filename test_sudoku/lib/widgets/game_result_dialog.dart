import 'package:flutter/material.dart';
import 'dart:math';

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
  final VoidCallback onNewGame;
  final VoidCallback onMainMenu;

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
    required this.onNewGame,
    required this.onMainMenu,
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
    // Berabere için farklı renk
    List<Color> gradientColors;
    Color shadowColor;

    if (widget.isDraw) {
      gradientColors = [const Color(0xFF1565C0), const Color(0xFF1976D2), const Color(0xFF2196F3)];
      shadowColor = Colors.blue;
    } else if (widget.isWin) {
      gradientColors = [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF43A047)];
      shadowColor = Colors.green;
    } else {
      gradientColors = [const Color(0xFFB71C1C), const Color(0xFFC62828), const Color(0xFFD32F2F)];
      shadowColor = Colors.red;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
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
                  size: const Size(300, 400),
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
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.isDraw ? '🤝' : (widget.isWin ? '🏆' : '😢'),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Başlık
                  Text(
                    widget.isDraw ? 'BERABERE!' : (widget.isWin ? 'KAZANDIN!' : 'KAYBETTİN!'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  if (widget.isPerfect && widget.isWin) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 4),
                          Text(
                            'HATASIZ!',
                            style: TextStyle(
                              color: Colors.black87,
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

                  const SizedBox(height: 20),

                  // İstatistikler
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: widget.isMultiplayer
                        ? _buildMultiplayerStats()
                        : _buildSinglePlayerStats(),
                  ),

                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          icon: Icons.refresh,
                          label: widget.isWin ? 'Yeni Oyun' : 'Tekrar Dene',
                          onTap: widget.onNewGame,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          icon: Icons.home,
                          label: 'Ana Menü',
                          onTap: widget.onMainMenu,
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePlayerStats() {
    return Column(
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
      ],
    );
  }

  Widget _buildMultiplayerStats() {
    bool player1Won = (widget.player1Score ?? 0) > (widget.player2Score ?? 0);
    bool player2Won = (widget.player2Score ?? 0) > (widget.player1Score ?? 0);
    bool isDraw = widget.player1Score == widget.player2Score;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerScore(
              widget.player1Name ?? 'Oyuncu 1',
              widget.player1Score ?? 0,
              player1Won,
              Colors.blue,
            ),
            Text(
              isDraw ? '🤝' : '⚔️',
              style: const TextStyle(fontSize: 24),
            ),
            _buildPlayerScore(
              widget.player2Name ?? 'Oyuncu 2',
              widget.player2Score ?? 0,
              player2Won,
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isDraw ? 'BERABERE!' : '${player1Won ? widget.player1Name : widget.player2Name} KAZANDI!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScore(String name, int score, bool isWinner, Color color) {
    return Column(
      children: [
        if (isWinner)
          const Text('👑', style: TextStyle(fontSize: 20)),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: isWinner ? 2 : 1),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWinner ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isHighlight ? 24 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.green.shade700 : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.green.shade700 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
      required VoidCallback onNewGame,
      required VoidCallback onMainMenu,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => GameResultDialog(
      isWin: true,
      score: 0,
      time: time,
      errors: 0,
      maxErrors: 3,
      isMultiplayer: true,
      player1Score: player1Score,
      player2Score: player2Score,
      player1Name: player1Name,
      player2Name: player2Name,
      onNewGame: onNewGame,
      onMainMenu: onMainMenu,
    ),
  );
}
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Sudoku Clash Logo with 3x3 grid and gradient glow
class SudokuClashLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const SudokuClashLogo({
    super.key,
    this.size = 100,
    this.animate = false,
  });

  @override
  State<SudokuClashLogo> createState() => _SudokuClashLogoState();
}

class _SudokuClashLogoState extends State<SudokuClashLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animate) {
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SudokuGridPainter(glowIntensity: _glowAnimation.value),
          );
        },
      );
    } else {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SudokuGridPainter(glowIntensity: 0.8),
      );
    }
  }
}

class _SudokuGridPainter extends CustomPainter {
  final double glowIntensity;

  _SudokuGridPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gridSize = size.width * 0.65;
    final cellSize = gridSize / 3;

    // Gradient colors
    final gradient = LinearGradient(
      colors: [
        Color(0xFF9C27B0), // Purple
        Color(0xFFE91E63), // Pink
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Outer glow effect
    _drawGlow(canvas, center, gridSize, glowIntensity);

    // Background circle with gradient
    _drawBackgroundCircle(canvas, center, size.width / 2);

    // 3x3 Sudoku Grid
    _drawGrid(canvas, center, gridSize, cellSize, gradient);

    // Some filled cells with numbers (random pattern)
    _drawFilledCells(canvas, center, gridSize, cellSize);
  }

  void _drawGlow(Canvas canvas, Offset center, double gridSize, double intensity) {
    final glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * intensity)
      ..shader = RadialGradient(
        colors: [
          Color(0xFF9C27B0).withOpacity(0.6 * intensity),
          Color(0xFFE91E63).withOpacity(0.3 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: gridSize * 0.8));

    canvas.drawCircle(center, gridSize * 0.8, glowPaint);
  }

  void _drawBackgroundCircle(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF9C27B0).withOpacity(0.15),
          Color(0xFFE91E63).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bgPaint);
  }

  void _drawGrid(
      Canvas canvas, Offset center, double gridSize, double cellSize, LinearGradient gradient) {
    final startX = center.dx - gridSize / 2;
    final startY = center.dy - gridSize / 2;

    // Grid paint with gradient
    final gridPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(startX, startY, gridSize, gridSize),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Outer border (thicker)
    final outerBorderPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(startX, startY, gridSize, gridSize),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Draw outer border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, startY, gridSize, gridSize),
        const Radius.circular(12),
      ),
      outerBorderPaint,
    );

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final x = startX + (cellSize * i);
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + gridSize),
        gridPaint,
      );
    }

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = startY + (cellSize * i);
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + gridSize, y),
        gridPaint,
      );
    }
  }

  void _drawFilledCells(
      Canvas canvas, Offset center, double gridSize, double cellSize) {
    final startX = center.dx - gridSize / 2;
    final startY = center.dy - gridSize / 2;

    // Predefined pattern for aesthetic look
    final cells = [
      {'row': 0, 'col': 1, 'number': '5'},
      {'row': 1, 'col': 0, 'number': '9'},
      {'row': 1, 'col': 2, 'number': '3'},
      {'row': 2, 'col': 1, 'number': '7'},
    ];

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var cell in cells) {
      final row = cell['row'] as int;
      final col = cell['col'] as int;
      final number = cell['number'] as String;

      final x = startX + (col * cellSize);
      final y = startY + (row * cellSize);

      // Cell background with subtle gradient
      final cellPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Color(0xFF9C27B0).withOpacity(0.2),
            Color(0xFFE91E63).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(x, y, cellSize, cellSize));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, y + 3, cellSize - 6, cellSize - 6),
          const Radius.circular(6),
        ),
        cellPaint,
      );

      // Draw number
      textPainter.text = TextSpan(
        text: number,
        style: TextStyle(
          color: Colors.white,
          fontSize: cellSize * 0.5,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Color(0xFF9C27B0).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + (cellSize - textPainter.width) / 2,
          y + (cellSize - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuGridPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}

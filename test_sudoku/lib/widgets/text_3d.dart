import 'package:flutter/material.dart';

/// 3D efektli başlık widget'ı
class Text3D extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final Color shadowColor;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;

  const Text3D({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color = Colors.white,
    this.shadowColor = Colors.black,
    this.fontWeight = FontWeight.bold,
    this.letterSpacing = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gölge katmanları (3D efekt)
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = shadowColor.withOpacity(0.3),
          ),
        ),
        // İkinci gölge
        Transform.translate(
          offset: const Offset(2, 2),
          child: Text(
            text,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: shadowColor.withOpacity(0.5),
            ),
          ),
        ),
        // Ana metin
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            color: color,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: shadowColor.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog başlığı için 3D efektli widget
class DialogTitle3D extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color iconColor;
  final double fontSize;

  const DialogTitle3D({
    super.key,
    required this.text,
    this.icon,
    this.iconColor = Colors.blue,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 12),
        ],
        Text3D(
          text: text,
          fontSize: fontSize,
          color: isDark ? Colors.white : Colors.black87,
          shadowColor: isDark ? Colors.black : Colors.grey.shade400,
          fontWeight: FontWeight.w900,
        ),
      ],
    );
  }
}

/// Menu butonu başlığı için 3D efektli widget (gradient olmadan)
class MenuTitle3D extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  const MenuTitle3D({
    super.key,
    required this.text,
    this.fontSize = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 0,
            color: Colors.black.withOpacity(0.3),
          ),
          Shadow(
            offset: const Offset(2, 2),
            blurRadius: 0,
            color: Colors.black.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

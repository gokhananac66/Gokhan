import 'package:flutter/material.dart';
import 'dart:math';

class CoinFlipScreen extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final bool isPlayer1;
  final Function(bool startsFirst) onResult;

  const CoinFlipScreen({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.isPlayer1,
    required this.onResult,
  });

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isFlipping = false;
  bool _showResult = false;
  bool _isHeads = true; // true = yazı, false = tura
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 10 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Otomatik başlat
    Future.delayed(const Duration(milliseconds: 500), _flipCoin);
  }

  void _flipCoin() {
    if (_isFlipping) return;

    setState(() {
      _isFlipping = true;
      _showResult = false;
    });

    // Rastgele sonuç
    _isHeads = Random().nextBool();

    _controller.forward(from: 0).then((_) {
      setState(() {
        _isFlipping = false;
        _showResult = true;

        // Oyuncu 1 = Yazı, Oyuncu 2 = Tura
        bool player1Starts = _isHeads;
        bool iWin = (widget.isPlayer1 && player1Starts) || (!widget.isPlayer1 && !player1Starts);

        if (iWin) {
          _resultText = '🎯 Sen başlıyorsun!';
        } else {
          _resultText = '⏳ Rakip başlıyor!';
        }
      });

      // 2 saniye sonra oyuna geç
      Future.delayed(const Duration(seconds: 2), () {
        bool player1Starts = _isHeads;
        bool startsFirst = (widget.isPlayer1 && player1Starts) || (!widget.isPlayer1 && !player1Starts);
        widget.onResult(startsFirst);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Başlık
            const Text(
              'İLK HAMLEYİ KİM YAPACAK?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            // Oyuncu bilgileri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('Y', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.player1Name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: widget.isPlayer1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Text('YAZI', style: TextStyle(color: Colors.amber, fontSize: 12)),
                    if (widget.isPlayer1)
                      const Text('(Sen)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                const Text('VS', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('T', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.player2Name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: !widget.isPlayer1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Text('TURA', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    if (!widget.isPlayer1)
                      const Text('(Sen)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Para animasyonu
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                double angle = _animation.value;
                bool showHeads = (angle / pi).floor() % 2 == 0;

                if (_showResult) {
                  showHeads = _isHeads;
                }

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_isFlipping ? angle : 0),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: showHeads
                            ? [Colors.amber.shade300, Colors.amber.shade600]
                            : [Colors.grey.shade300, Colors.grey.shade500],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        showHeads ? 'YAZI' : 'TURA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: showHeads ? Colors.amber.shade900 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),

            // Sonuç
            if (_showResult)
              Column(
                children: [
                  Text(
                    _isHeads ? '🪙 YAZI GELDİ!' : '🪙 TURA GELDİ!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _resultText.contains('Sen') ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _resultText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                '🪙 Para havada...',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
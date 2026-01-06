import 'dart:async';
import 'package:flutter/material.dart';
import '../services/game_invite_service.dart';

class GlobalInviteOverlay extends StatefulWidget {
  final Widget child;
  final Function(GameInvite) onAccept;
  final Function(GameInvite) onReject;

  const GlobalInviteOverlay({
    super.key,
    required this.child,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<GlobalInviteOverlay> createState() => _GlobalInviteOverlayState();
}

class _GlobalInviteOverlayState extends State<GlobalInviteOverlay> with SingleTickerProviderStateMixin {
  GameInvite? _currentInvite;
  int _countdown = 30;
  Timer? _countdownTimer;
  StreamSubscription? _inviteSubscription;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _inviteSubscription = GlobalInviteNotifier().onInviteReceived.listen((invite) {
      _showInvite(invite);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _countdownTimer?.cancel();
    _inviteSubscription?.cancel();
    super.dispose();
  }

  void _showInvite(GameInvite invite) {
    if (_currentInvite != null) return;

    setState(() {
      _currentInvite = invite;
      _countdown = 30;
    });

    _animController.forward();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _dismissInvite();
        widget.onReject(invite);
      }
    });
  }

  void _dismissInvite() {
    _countdownTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) setState(() => _currentInvite = null);
    });
  }

  void _acceptInvite() {
    if (_currentInvite != null) {
      final invite = _currentInvite!;
      _dismissInvite();
      widget.onAccept(invite);
    }
  }

  void _rejectInvite() {
    if (_currentInvite != null) {
      final invite = _currentInvite!;
      _dismissInvite();
      widget.onReject(invite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_currentInvite != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildInviteCard(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.sports_esports, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Oyun Daveti!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${_currentInvite?.fromNickname ?? "Birisi"} seni oyuna davet ediyor', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    child: Center(child: Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                child: Text('Zorluk: ${_currentInvite?.difficulty ?? "Orta"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rejectInvite,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.close, size: 20), SizedBox(width: 6), Text('Reddet', style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptInvite,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check, size: 20), SizedBox(width: 6), Text('Kabul Et', style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
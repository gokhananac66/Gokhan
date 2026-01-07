import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/friend_service.dart';
import '../services/game_invite_service.dart';
import '../services/difficulty_calculator.dart';
import '../app_localizations.dart';
import 'online_game_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  final _friendService = FriendService();
  final _inviteService = GameInviteService();
  final _database = FirebaseDatabase.instance.ref();

  List<FriendData> _friends = [];
  List<FriendRequest> _friendRequests = [];
  bool _isLoading = true;
  String? _pendingInviteId;
  String? _pendingInviteTarget;
  String? _pendingGameId;
  int _inviteCountdown = 30;
  Timer? _countdownTimer;

  StreamSubscription? _friendRequestsSubscription;
  StreamSubscription? _friendsSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _setupInviteListeners();
    _setupRealtimeListeners();
    _friendService.setOnlineStatus(true);
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _friendRequestsSubscription?.cancel();
    _friendsSubscription?.cancel();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _inviteService.dispose();
    _friendService.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    _friendRequestsSubscription = _friendService.watchFriendRequests().listen(
          (requests) {
        if (mounted) setState(() => _friendRequests = requests);
      },
      onError: (e) => print('Friend requests stream error: $e'),
    );

    _friendsSubscription = _friendService.watchFriends().listen(
          (friends) {
        if (mounted) {
          setState(() {
            _friends = friends;
            _isLoading = false;
          });
        }
      },
      onError: (e) => print('Friends stream error: $e'),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final friends = await _friendService.getFriends();
      final requests = await _friendService.getFriendRequests();

      setState(() {
        _friends = friends;
        _friendRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupInviteListeners() {
    _inviteService.listenToIncomingInvites((invite) {
      _showIncomingInviteDialog(invite);
    });

    _inviteService.onInviteStatusChanged = (inviteId, status) {
      if (_pendingInviteId == inviteId) {
        _countdownTimer?.cancel();

        if (status == 'rejected') {
          setState(() {
            _pendingInviteId = null;
            _pendingInviteTarget = null;
            _pendingGameId = null;
          });
          _showSnackBar(tr('inviteRejected'), Colors.orange);
        } else if (status == 'expired') {
          setState(() {
            _pendingInviteId = null;
            _pendingInviteTarget = null;
            _pendingGameId = null;
          });
          _showSnackBar(tr('inviteExpired'), Colors.grey);
        } else if (status == 'accepted' && _pendingGameId != null) {
          _navigateToGame(_pendingGameId!, isPlayer1: true);
        }
      }
    };

    _inviteService.onGameStart = (gameId) async {
      _countdownTimer?.cancel();
      setState(() {
        _pendingInviteId = null;
        _pendingInviteTarget = null;
        _pendingGameId = null;
      });

      await _navigateToGame(gameId, isPlayer1: true);
    };
  }

  Future<void> _navigateToGame(String gameId, {required bool isPlayer1}) async {
    if (!mounted) return;

    // Fetch game data to get difficulty and gameMode
    final gameSnapshot = await FirebaseDatabase.instance.ref('games/$gameId').get();
    if (!gameSnapshot.exists) {
      _showSnackBar('Oyun bulunamadı!', Colors.red);
      return;
    }

    final gameData = Map<String, dynamic>.from(gameSnapshot.value as Map);
    final difficulty = gameData['difficulty'] ?? 'Orta';
    final gameMode = gameData['gameMode'] ?? 'classic';

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineGameScreen(
            gameId: gameId,
            isPlayer1: isPlayer1,
            difficulty: difficulty,
            gameMode: gameMode,
            startsFirst: isPlayer1,
          ),
        ),
      );
    }
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                child: Icon(Icons.person_add, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Text(tr('addFriend')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('enterFriendNickname'), style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: tr('nickname'),
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (controller.text.trim().isEmpty) return;
                setDialogState(() => isLoading = true);
                final result = await _friendService.sendFriendRequest(controller.text.trim());
                setDialogState(() => isLoading = false);
                Navigator.pop(context);
                _showSnackBar(result.message, result.success ? Colors.green : Colors.red);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('sendRequest'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncomingInviteDialog(GameInvite invite) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
              child: Icon(Icons.sports_esports, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Text(tr('gameInvite')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${invite.fromNickname} ${tr('invitesYouToPlay')}', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text('${tr('difficulty')}: ${invite.difficulty}', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _inviteService.rejectInvite(invite.id);
              Navigator.pop(context);
            },
            child: Text(tr('reject'), style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final gameId = await _inviteService.getGameIdFromInvite(invite.id);
              if (gameId == null) {
                _showSnackBar(tr('inviteExpired'), Colors.orange);
                return;
              }
              final success = await _inviteService.acceptInvite(invite.id);
              if (success) {
                await _navigateToGame(gameId, isPlayer1: false);
              } else {
                _showSnackBar(tr('inviteExpired'), Colors.orange);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(tr('accept'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGameInvite(FriendData friend) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 0. Check cooldown - 2 red = 1 minute ban
    final canSend = await _cooldownService.canSendInvite(uid, friend.uid);
    if (!canSend) {
      final remainingSeconds = await _cooldownService.getRemainingCooldownSeconds(uid, friend.uid);
      _showSnackBar('Bu kullanıcıya $remainingSeconds saniye sonra davet gönderebilirsiniz!', Colors.orange);
      return;
    }

    // 1. Get current user level
    final prefs = await SharedPreferences.getInstance();
    final myLevel = prefs.getInt('level') ?? 1;

    // 2. Check level difference (max ±20)
    if (!DifficultyCalculator.isLevelDifferenceAcceptable(myLevel, friend.level, isFriend: true)) {
      final diff = DifficultyCalculator.getLevelDifference(myLevel, friend.level);
      _showSnackBar('Level farkı çok büyük! (Fark: $diff, Max: 20)', Colors.red);
      return;
    }

    // 3. Calculate automatic difficulty
    final autoDifficulty = DifficultyCalculator.calculateDifficulty(myLevel, friend.level);

    // 4. Show game mode selection dialog
    final gameMode = await _showGameModeDialog(friend, autoDifficulty);
    if (gameMode == null) return; // User cancelled

    // 5. Send invite with auto difficulty and selected gameMode
    final result = await _inviteService.sendInvite(
      targetUid: friend.uid,
      targetNickname: friend.nickname,
      difficulty: autoDifficulty,
      gameMode: gameMode,
    );

    if (result.success) {
      setState(() {
        _pendingInviteId = result.inviteId;
        _pendingInviteTarget = friend.nickname;
        _pendingGameId = result.gameId;
        _inviteCountdown = 30;
      });

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _inviteCountdown--);
        if (_inviteCountdown <= 0) {
          timer.cancel();
          setState(() {
            _pendingInviteId = null;
            _pendingInviteTarget = null;
            _pendingGameId = null;
          });
        }
      });

      _showSnackBar('${tr('inviteSentTo')} ${friend.nickname}', Colors.green);
    } else {
      _showSnackBar(result.message, Colors.red);
    }
  }

  Future<void> _cancelPendingInvite() async {
    if (_pendingInviteId != null) {
      await _inviteService.cancelInvite(_pendingInviteId!);
      _countdownTimer?.cancel();
      setState(() {
        _pendingInviteId = null;
        _pendingInviteTarget = null;
        _pendingGameId = null;
      });
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    final success = await _friendService.acceptFriendRequest(request.uid);
    if (success) {
      _showSnackBar('${request.nickname} ${tr('addedAsFriend')}', Colors.green);
    }
  }

  Future<void> _rejectFriendRequest(FriendRequest request) async {
    await _friendService.rejectFriendRequest(request.uid);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(tr('friends')),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_rounded), onPressed: _showAddFriendDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_esports, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Text('${tr('difficulty')}: ${widget.difficulty}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (_pendingInviteId != null) _buildPendingInviteCard(),
            if (_friendRequests.isNotEmpty) ...[
              _buildSectionHeader(tr('friendRequests'), Icons.mail_rounded, Colors.orange, badge: _friendRequests.length),
              const SizedBox(height: 12),
              ..._friendRequests.map(_buildFriendRequestCard),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader(tr('onlineFriends'), Icons.circle, Colors.green, badge: _friends.where((f) => f.online).length),
            const SizedBox(height: 12),
            if (_friends.where((f) => f.online).isEmpty)
              _buildEmptyOnlineState()
            else
              ..._friends.where((f) => f.online).map(_buildFriendCard3D),
            const SizedBox(height: 24),
            if (_friends.where((f) => !f.online).isNotEmpty) ...[
              _buildSectionHeader(tr('offlineFriends'), Icons.circle_outlined, Colors.grey),
              const SizedBox(height: 12),
              ..._friends.where((f) => !f.online).map(_buildFriendCard3D),
            ],
            if (_friends.isEmpty) _buildEmptyState(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingInviteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tr('waitingFor')} $_pendingInviteTarget...', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_inviteCountdown}s', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          TextButton(onPressed: _cancelPendingInvite, child: Text(tr('cancel'), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {int? badge}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        if (badge != null && badge > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(request.nickname.isNotEmpty ? request.nickname[0].toUpperCase() : '?', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.nickname, style: const TextStyle(fontWeight: FontWeight.bold)), Text(tr('wantsToBeYourFriend'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])),
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _acceptFriendRequest(request)),
          IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _rejectFriendRequest(request)),
        ],
      ),
    );
  }

  Widget _buildFriendCard3D(FriendData friend) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = friend.online;
    final isPending = _pendingInviteTarget == friend.nickname;

    // League color
    Color getLeagueColor() {
      if (friend.level <= 20) return const Color(0xFFCD7F32); // Bronze
      if (friend.level <= 40) return const Color(0xFFC0C0C0); // Silver
      if (friend.level <= 60) return const Color(0xFFFFD700); // Gold
      if (friend.level <= 80) return const Color(0xFF00CED1); // Platinum
      return const Color(0xFF9400D3); // Diamond
    }

    final leagueColor = getLeagueColor();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline
                      ? [leagueColor.withOpacity(0.3), leagueColor.withOpacity(0.15)]
                      : isDark
                        ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
                        : [Colors.white, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline ? leagueColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    width: isOnline ? 2.5 : 1.5,
                  ),
                  boxShadow: isOnline ? [
                    BoxShadow(
                      color: leagueColor.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Animated background pulse for online friends
                      if (isOnline)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  leagueColor.withOpacity(0.2 * _pulseAnimation.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            _buildModernAvatar(friend, isOnline, leagueColor, isDark),
                            const SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nickname
                                  Text(
                                    friend.nickname,
                                    style: TextStyle(
                                      color: isOnline
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Level & Status
                                  Row(
                                    children: [
                                      _buildModernLevelBadge(friend.level, leagueColor, isOnline),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isOnline ? Colors.greenAccent : Colors.grey,
                                                shape: BoxShape.circle,
                                                boxShadow: isOnline ? [
                                                  BoxShadow(
                                                    color: Colors.greenAccent.withOpacity(0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ] : null,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                isOnline ? tr('online') : friend.lastSeenText,
                                                style: TextStyle(
                                                  color: isOnline
                                                    ? Colors.white.withOpacity(0.9)
                                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Action button
                            if (isOnline && !isPending)
                              _buildModernInviteButton(friend)
                            else if (isPending)
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAvatar(FriendData friend, bool isOnline, Color leagueColor, bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
            ? [leagueColor.withOpacity(0.8), leagueColor]
            : isDark
              ? [Colors.grey.shade700, Colors.grey.shade800]
              : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isOnline ? leagueColor.withOpacity(0.4) : Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          friend.nickname.isNotEmpty ? friend.nickname[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildModernLevelBadge(int level, Color leagueColor, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
            ? [leagueColor.withOpacity(0.3), leagueColor.withOpacity(0.15)]
            : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? leagueColor : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: isOnline ? Colors.white : Colors.grey.shade600,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$level',
            style: TextStyle(
              color: isOnline ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInviteButton(FriendData friend) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendGameInvite(friend),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'DAVET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mod seçim dialog'u - Classic vs Race
  Future<String?> _showGameModeDialog(FriendData friend, String difficulty) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sports_esports, color: Colors.green.shade700, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Oyun Modu Seç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${friend.nickname} ile oynamak için', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Auto difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Otomatik Zorluk: $difficulty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Classic Mode
              _buildModeOption(
                icon: Icons.sports_esports,
                title: '⚔️ Klasik Mod',
                description: 'Sırayla hamle yapın, 30 saniye turlar',
                color: Colors.blue,
                onTap: () => Navigator.pop(context, 'classic'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Race Mode
              _buildModeOption(
                icon: Icons.speed,
                title: '🏁 Race Mod',
                description: 'Ayrı tahtalar, ilk bitiren kazanır',
                color: Colors.purple,
                onTap: () => Navigator.pop(context, 'race'),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteButton(FriendData friend) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendGameInvite(friend),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.sports_esports, color: Colors.white, size: 18), const SizedBox(width: 6), Text(tr('invite'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
        ),
      ),
    );
  }

  Widget _buildEmptyOnlineState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [Icon(Icons.person_off, size: 48, color: Colors.grey.shade400), const SizedBox(height: 12), Text(tr('noOnlineFriends'), style: TextStyle(color: Colors.grey.shade600))]),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(Icons.people_outline, size: 64, color: Colors.blue.shade300)),
          const SizedBox(height: 24),
          Text(tr('noFriendsYet'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(tr('addFriendsToPlay'), style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _showAddFriendDialog, icon: const Icon(Icons.person_add), label: Text(tr('addFriend')), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
        ],
      ),
    );
  }
}
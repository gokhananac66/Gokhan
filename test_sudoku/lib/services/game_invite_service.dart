import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_service.dart';

/// Oyun daveti modeli
class GameInvite {
  final String id;
  final String fromUid;
  final String fromNickname;
  final String toUid;
  final String difficulty;
  final String gameMode; // 'classic' or 'race'
  final String status;
  final DateTime createdAt;
  String? gameId;

  GameInvite({
    required this.id,
    required this.fromUid,
    required this.fromNickname,
    required this.toUid,
    required this.difficulty,
    required this.gameMode,
    required this.status,
    required this.createdAt,
    this.gameId,
  });
}

/// Davet sonucu
class InviteResult {
  final bool success;
  final String message;
  final String? inviteId;
  final String? gameId;

  InviteResult({required this.success, required this.message, this.inviteId, this.gameId});
}

/// Global bildirim yöneticisi (Singleton)
class GlobalInviteNotifier {
  static final GlobalInviteNotifier _instance = GlobalInviteNotifier._internal();
  factory GlobalInviteNotifier() => _instance;
  GlobalInviteNotifier._internal();

  final _inviteController = StreamController<GameInvite>.broadcast();
  Stream<GameInvite> get onInviteReceived => _inviteController.stream;

  void notify(GameInvite invite) {
    _inviteController.add(invite);
  }

  void dispose() {
    _inviteController.close();
  }
}

/// Oyun davet servisi (Singleton)
class GameInviteService {
  static final GameInviteService _instance = GameInviteService._internal();
  factory GameInviteService() => _instance;
  GameInviteService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  StreamSubscription? _inviteSubscription;
  StreamSubscription? _sentInviteSubscription;

  Function(GameInvite)? onIncomingInvite;
  Function(String inviteId, String status)? onInviteStatusChanged;
  Function(String gameId)? onGameStart;

  static const int inviteTimeoutSeconds = 30;

  /// Gelen davetleri dinle
  void listenToIncomingInvites(Function(GameInvite) callback) {
    final uid = currentUserId;
    if (uid == null) {
      print('❌ [INVITE_LISTEN] No user logged in');
      return;
    }

    print('👂 [INVITE_LISTEN] Starting to listen for invites for uid: $uid');
    onIncomingInvite = callback;

    _inviteSubscription?.cancel();
    _inviteSubscription = _ref
        .child('game_invites')
        .orderByChild('toUid')
        .equalTo(uid)
        .onChildAdded
        .listen((event) async {
      print('🔔 [INVITE_LISTEN] New invite detected!');

      if (!event.snapshot.exists) {
        print('⚠️ [INVITE_LISTEN] Snapshot does not exist');
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      print('📩 [INVITE_LISTEN] Invite data: status=${data['status']}, fromNickname=${data['fromNickname']}');

      if (data['status'] != 'pending') {
        print('⚠️ [INVITE_LISTEN] Invite status is not pending, skipping');
        return;
      }

      // Davet eski mi kontrol et
      final createdAt = data['createdAt'] as int?;
      if (createdAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - createdAt;
        if (age > inviteTimeoutSeconds * 1000) {
          // Eski davet, ignore et
          return;
        }
      }

      var fromNickname = data['fromNickname']?.toString();
      if (fromNickname == null || fromNickname.isEmpty || fromNickname == 'Unknown') {
        fromNickname = await _friendService.getNicknameByUid(data['fromUid'].toString());
      }

      final invite = GameInvite(
        id: event.snapshot.key!,
        fromUid: data['fromUid']?.toString() ?? '',
        fromNickname: fromNickname,
        toUid: uid,
        difficulty: data['difficulty']?.toString() ?? 'Orta',
        gameMode: data['gameMode']?.toString() ?? 'classic',
        status: 'pending',
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt)
            : DateTime.now(),
        gameId: data['gameId']?.toString(),
      );

      GlobalInviteNotifier().notify(invite);
      callback(invite);
    });

    // Gönderdiğim davetlerin durumunu dinle
    _sentInviteSubscription?.cancel();
    _sentInviteSubscription = _ref
        .child('game_invites')
        .orderByChild('fromUid')
        .equalTo(uid)
        .onChildChanged
        .listen((event) {
      if (!event.snapshot.exists) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final status = data['status']?.toString() ?? '';
      final inviteId = event.snapshot.key!;
      final gameId = data['gameId']?.toString();

      onInviteStatusChanged?.call(inviteId, status);

      // Kabul edilmişse ve gameId varsa, oyuna başla
      if (status == 'accepted' && gameId != null && gameId.isNotEmpty) {
        onGameStart?.call(gameId);
      }
    });
  }

  /// Davet gönder - ÖNCE OYUNU OLUŞTUR, SONRA DAVETİ GÖNDER
  Future<InviteResult> sendInvite({
    required String targetUid,
    required String targetNickname,
    required String difficulty,
    String gameMode = 'classic', // 'classic' or 'race'
  }) async {
    print('🎮 [INVITE] Sending invite to $targetNickname (mode: $gameMode, difficulty: $difficulty)');

    final uid = currentUserId;
    if (uid == null) {
      print('❌ [INVITE] No user logged in');
      return InviteResult(success: false, message: 'Oturum açılmamış');
    }

    try {
      print('🔍 [INVITE] Getting my nickname for uid: $uid');
      final myNickname = await _friendService.getNicknameByUid(uid);
      print('✅ [INVITE] My nickname: $myNickname');

      // ÖNCE OYUNU OLUŞTUR
      print('🎲 [INVITE] Creating game...');
      final puzzleData = _generateSudokuPuzzle(difficulty);
      final gameRef = _ref.child('games').push();
      final gameId = gameRef.key!;
      print('🆔 [INVITE] Game ID: $gameId');

      Map<String, dynamic> gameData = {
        'solution': puzzleData['solution'],
        'difficulty': difficulty,
        'gameMode': gameMode,
        'player1Uid': uid,
        'player2Uid': targetUid,
        'player1Name': myNickname,
        'player2Name': targetNickname,
        'player1Score': 0,
        'player2Score': 0,
        'player1Errors': 0,
        'player2Errors': 0,
        'currentTurn': 1,
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'gameType': 'friend_invite',
      };

      // Race mode: Her oyuncunun ayrı board'u var
      if (gameMode == 'race') {
        gameData['player1Board'] = puzzleData['board'];
        gameData['player2Board'] = puzzleData['board'];
        gameData['player1Progress'] = 0;
        gameData['player2Progress'] = 0;
      } else {
        // Classic mode: Tek board paylaşılır
        gameData['board'] = puzzleData['board'];
      }

      await gameRef.set(gameData);

      // SONRA DAVETİ GÖNDER (gameId ile birlikte)
      print('📨 [INVITE] Sending invite to Firebase...');
      final inviteRef = _ref.child('game_invites').push();
      await inviteRef.set({
        'fromUid': uid,
        'fromNickname': myNickname,
        'toUid': targetUid,
        'toNickname': targetNickname,
        'difficulty': difficulty,
        'gameMode': gameMode, // 'classic' or 'race'
        'status': 'pending',
        'gameId': gameId, // OYUN ID'Sİ ZATEN MEVCUT
        'createdAt': ServerValue.timestamp,
      });
      print('✅ [INVITE] Invite sent! Invite ID: ${inviteRef.key}');

      // Timeout sonrası expire et
      Future.delayed(Duration(seconds: inviteTimeoutSeconds), () async {
        final snapshot = await _ref.child('game_invites/${inviteRef.key}').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (data['status'] == 'pending') {
            await _ref.child('game_invites/${inviteRef.key}').update({
              'status': 'expired',
            });
            // Oyunu da sil
            await _ref.child('games/$gameId').remove();
          }
        }
      });

      return InviteResult(
        success: true,
        message: 'Davet gönderildi!',
        inviteId: inviteRef.key,
        gameId: gameId,
      );
    } catch (e) {
      print('Error sending invite: $e');
      return InviteResult(success: false, message: 'Davet gönderilemedi');
    }
  }

  /// Daveti kabul et - OYUN ZATEN VAR, SADECE STATUS GÜNCELLE
  Future<bool> acceptInvite(String inviteId) async {
    try {
      final snapshot = await _ref.child('game_invites/$inviteId').get();
      if (!snapshot.exists) {
        print('Invite not found: $inviteId');
        return false;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['status'] != 'pending') {
        print('Invite not pending: ${data['status']}');
        return false;
      }

      final gameId = data['gameId']?.toString();
      if (gameId == null || gameId.isEmpty) {
        print('No gameId in invite');
        return false;
      }

      // Oyunun var olduğunu kontrol et
      final gameSnapshot = await _ref.child('games/$gameId').get();
      if (!gameSnapshot.exists) {
        print('Game not found: $gameId');
        return false;
      }

      // Daveti kabul edildi olarak işaretle
      await _ref.child('game_invites/$inviteId').update({
        'status': 'accepted',
      });

      // Oyunu başlat
      await _ref.child('games/$gameId').update({
        'status': 'playing',
        'startedAt': ServerValue.timestamp,
      });

      print('Invite accepted, game started: $gameId');
      return true;
    } catch (e) {
      print('Error accepting invite: $e');
      return false;
    }
  }

  /// Daveti reddet
  Future<void> rejectInvite(String inviteId) async {
    try {
      final snapshot = await _ref.child('game_invites/$inviteId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final gameId = data['gameId']?.toString();

        // Daveti reddet
        await _ref.child('game_invites/$inviteId').update({
          'status': 'rejected',
        });

        // Oyunu da sil
        if (gameId != null && gameId.isNotEmpty) {
          await _ref.child('games/$gameId').remove();
        }
      }
    } catch (e) {
      print('Error rejecting invite: $e');
    }
  }

  /// Daveti iptal et
  Future<void> cancelInvite(String inviteId) async {
    try {
      final snapshot = await _ref.child('game_invites/$inviteId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final gameId = data['gameId']?.toString();

        await _ref.child('game_invites/$inviteId').update({
          'status': 'cancelled',
        });

        if (gameId != null && gameId.isNotEmpty) {
          await _ref.child('games/$gameId').remove();
        }
      }
    } catch (e) {
      print('Error cancelling invite: $e');
    }
  }

  /// Davet bilgisinden gameId al
  Future<String?> getGameIdFromInvite(String inviteId) async {
    try {
      final snapshot = await _ref.child('game_invites/$inviteId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data['gameId']?.toString();
      }
      return null;
    } catch (e) {
      print('Error getting gameId: $e');
      return null;
    }
  }

  /// Sudoku puzzle oluştur
  Map<String, List<int>> _generateSudokuPuzzle(String difficulty) {
    List<int> solution = [
      5,3,4,6,7,8,9,1,2,
      6,7,2,1,9,5,3,4,8,
      1,9,8,3,4,2,5,6,7,
      8,5,9,7,6,1,4,2,3,
      4,2,6,8,5,3,7,9,1,
      7,1,3,9,2,4,8,5,6,
      9,6,1,5,3,7,2,8,4,
      2,8,7,4,1,9,6,3,5,
      3,4,5,2,8,6,1,7,9,
    ];

    int emptyCells;
    switch (difficulty) {
      case 'Kolay':
        emptyCells = 30;
        break;
      case 'Orta':
        emptyCells = 40;
        break;
      case 'Zor':
        emptyCells = 50;
        break;
      case 'Uzman':
        emptyCells = 55;
        break;
      default:
        emptyCells = 40;
    }

    List<int> board = List.from(solution);
    List<int> indices = List.generate(81, (i) => i)..shuffle();

    for (int i = 0; i < emptyCells && i < indices.length; i++) {
      board[indices[i]] = 0;
    }

    return {
      'board': board,
      'solution': solution,
    };
  }

  void dispose() {
    _inviteSubscription?.cancel();
    _sentInviteSubscription?.cancel();
  }
}
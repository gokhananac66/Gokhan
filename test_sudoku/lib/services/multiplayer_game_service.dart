import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_service.dart';

/// Oyun durumu
enum GameStatus { waiting, playing, finished, abandoned }

/// Oyun servisi
class MultiplayerGameService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  // Sabitler
  static const int turnTimeLimit = 30;  // 30 saniye
  static const int maxErrors = 3;        // 3 hata hakkı
  static const int baseScore = 10;
  static const int comboMultiplier = 5;

  StreamSubscription? _gameSubscription;
  Timer? _turnTimer;
  String? currentGameId;

  // Callbacks
  Function(Map<dynamic, dynamic>)? onGameUpdate;
  Function(int)? onTurnTimerTick;
  Function(String winnerId, String reason)? onGameEnd;
  Function()? onTurnTimeout;
  Function(String visitorId)? onOpponentLeft;

  /// Oyunu dinlemeye başla
  void listenToGame(String gameId) {
    currentGameId = gameId;

    _gameSubscription?.cancel();
    _gameSubscription = _ref
        .child('multiplayer_games/$gameId')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      onGameUpdate?.call(data);

      // Oyun durumu kontrolü
      final status = data['status']?.toString();

      if (status == 'finished' || status == 'abandoned') {
        final winnerId = data['winnerId']?.toString() ?? '';
        final reason = data['endReason']?.toString() ?? 'finished';
        onGameEnd?.call(winnerId, reason);
        _stopTurnTimer();
        return;
      }

      // Sıra kontrolü ve timer
      final currentTurn = data['currentTurn']?.toString();
      if (currentTurn == currentUserId) {
        _startTurnTimer(data);
      } else {
        _stopTurnTimer();
      }
    });

    // Opponent disconnect kontrolü
    _listenForOpponentDisconnect(gameId);
  }

  void _listenForOpponentDisconnect(String gameId) {
    _ref.child('multiplayer_games/$gameId').onValue.listen((event) async {
      if (!event.snapshot.exists) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final status = data['status']?.toString();

      if (status != 'playing') return;

      final uid = currentUserId;
      final player1 = data['player1']?.toString();
      final player2 = data['player2']?.toString();
      final opponentUid = (player1 == uid) ? player2 : player1;

      // Rakibin online durumunu kontrol et
      final opponentSnapshot = await _ref.child('users/$opponentUid/isOnline').get();
      final isOpponentOnline = opponentSnapshot.value == true;

      // Eğer rakip offline ise ve oyun hala devam ediyorsa
      if (!isOpponentOnline) {
        // 10 saniye bekle, hala offline ise oyunu bitir
        await Future.delayed(const Duration(seconds: 10));

        final recheckSnapshot = await _ref.child('users/$opponentUid/isOnline').get();
        if (recheckSnapshot.value != true) {
          final gameCheck = await _ref.child('multiplayer_games/$gameId/status').get();
          if (gameCheck.value == 'playing') {
            await endGame(gameId, uid!, 'opponent_left');
            onOpponentLeft?.call(opponentUid!);
          }
        }
      }
    });
  }

  void _startTurnTimer(Map<dynamic, dynamic> gameData) {
    _stopTurnTimer();

    final turnStartTime = gameData['turnStartTime'];
    if (turnStartTime == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(turnStartTime as int);
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    var remaining = turnTimeLimit - elapsed;

    if (remaining <= 0) {
      _handleTurnTimeout();
      return;
    }

    // Her saniye güncelle
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      onTurnTimerTick?.call(remaining);

      if (remaining <= 0) {
        timer.cancel();
        _handleTurnTimeout();
      }
    });
  }

  void _stopTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  Future<void> _handleTurnTimeout() async {
    if (currentGameId == null || currentUserId == null) return;

    onTurnTimeout?.call();

    // Hata ekle
    final gameSnapshot = await _ref.child('multiplayer_games/$currentGameId').get();
    if (!gameSnapshot.exists) return;

    final data = gameSnapshot.value as Map<dynamic, dynamic>;
    final uid = currentUserId!;

    final isPlayer1 = data['player1'] == uid;
    final errorField = isPlayer1 ? 'player1Errors' : 'player2Errors';
    final currentErrors = (data[errorField] as num?)?.toInt() ?? 0;
    final newErrors = currentErrors + 1;

    // Combo sıfırla
    final comboField = isPlayer1 ? 'player1Combo' : 'player2Combo';

    await _ref.child('multiplayer_games/$currentGameId').update({
      errorField: newErrors,
      comboField: 0,
    });

    // 3 hata kontrolü
    if (newErrors >= maxErrors) {
      final opponentUid = isPlayer1 ? data['player2'] : data['player1'];
      await endGame(currentGameId!, opponentUid.toString(), 'max_errors');
      return;
    }

    // Sırayı geçir
    await _switchTurn();
  }

  /// Hamle yap
  Future<bool> makeMove({
    required int row,
    required int col,
    required int value,
    required bool isCorrect,
  }) async {
    if (currentGameId == null || currentUserId == null) return false;

    final gameSnapshot = await _ref.child('multiplayer_games/$currentGameId').get();
    if (!gameSnapshot.exists) return false;

    final data = gameSnapshot.value as Map<dynamic, dynamic>;

    // Sıra kontrolü
    if (data['currentTurn'] != currentUserId) return false;
    if (data['status'] != 'playing') return false;

    final uid = currentUserId!;
    final isPlayer1 = data['player1'] == uid;

    final scoreField = isPlayer1 ? 'player1Score' : 'player2Score';
    final errorField = isPlayer1 ? 'player1Errors' : 'player2Errors';
    final comboField = isPlayer1 ? 'player1Combo' : 'player2Combo';

    final currentScore = (data[scoreField] as num?)?.toInt() ?? 0;
    final currentErrors = (data[errorField] as num?)?.toInt() ?? 0;
    final currentCombo = (data[comboField] as num?)?.toInt() ?? 0;

    Map<String, dynamic> updates = {};

    if (isCorrect) {
      // Doğru hamle
      final newCombo = currentCombo + 1;
      final scoreGain = baseScore + (newCombo * comboMultiplier);

      updates[scoreField] = currentScore + scoreGain;
      updates[comboField] = newCombo;
    } else {
      // Yanlış hamle
      final newErrors = currentErrors + 1;
      updates[errorField] = newErrors;
      updates[comboField] = 0;

      // 3 hata kontrolü
      if (newErrors >= maxErrors) {
        final opponentUid = isPlayer1 ? data['player2'] : data['player1'];
        await _ref.child('multiplayer_games/$currentGameId').update(updates);
        await endGame(currentGameId!, opponentUid.toString(), 'max_errors');
        return true;
      }
    }

    await _ref.child('multiplayer_games/$currentGameId').update(updates);

    // Sırayı geçir
    await _switchTurn();

    return true;
  }

  Future<void> _switchTurn() async {
    if (currentGameId == null) return;

    final gameSnapshot = await _ref.child('multiplayer_games/$currentGameId').get();
    if (!gameSnapshot.exists) return;

    final data = gameSnapshot.value as Map<dynamic, dynamic>;
    final currentTurn = data['currentTurn']?.toString();
    final player1 = data['player1']?.toString();
    final player2 = data['player2']?.toString();

    final nextTurn = (currentTurn == player1) ? player2 : player1;

    await _ref.child('multiplayer_games/$currentGameId').update({
      'currentTurn': nextTurn,
      'turnStartTime': ServerValue.timestamp,
    });
  }

  /// Oyunu bitir
  Future<void> endGame(String gameId, String winnerId, String reason) async {
    await _ref.child('multiplayer_games/$gameId').update({
      'status': reason == 'opponent_left' || reason == 'abandoned' ? 'abandoned' : 'finished',
      'winnerId': winnerId,
      'endReason': reason,
      'endedAt': ServerValue.timestamp,
    });

    _stopTurnTimer();
  }

  /// Oyunu terk et
  Future<void> abandonGame() async {
    if (currentGameId == null || currentUserId == null) return;

    final gameSnapshot = await _ref.child('multiplayer_games/$currentGameId').get();
    if (!gameSnapshot.exists) return;

    final data = gameSnapshot.value as Map<dynamic, dynamic>;
    final uid = currentUserId!;

    final opponentUid = (data['player1'] == uid)
        ? data['player2']?.toString()
        : data['player1']?.toString();

    if (opponentUid != null) {
      await endGame(currentGameId!, opponentUid, 'abandoned');
    }
  }

  /// Oyun bilgilerini al
  Future<Map<dynamic, dynamic>?> getGameData(String gameId) async {
    final snapshot = await _ref.child('multiplayer_games/$gameId').get();
    if (!snapshot.exists) return null;
    return snapshot.value as Map<dynamic, dynamic>;
  }

  /// Rakip nickname'ini al
  Future<String> getOpponentNickname(String gameId) async {
    final data = await getGameData(gameId);
    if (data == null) return 'Rakip';

    final uid = currentUserId;
    if (data['player1'] == uid) {
      return data['player2Nickname']?.toString() ??
          await _friendService.getNicknameByUid(data['player2'].toString());
    } else {
      return data['player1Nickname']?.toString() ??
          await _friendService.getNicknameByUid(data['player1'].toString());
    }
  }

  /// Temizlik
  void dispose() {
    _gameSubscription?.cancel();
    _stopTurnTimer();
    currentGameId = null;
  }
}
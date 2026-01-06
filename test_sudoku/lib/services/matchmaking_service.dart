import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_service.dart';
import '../models/player_rank.dart';

/// Matchmaking sonucu
class MatchResult {
  final bool success;
  final String? gameId;
  final String? opponentNickname;
  final bool isPlayer1;
  final String message;
  final int? opponentLevel;
  final String? opponentLeague;

  MatchResult({
    required this.success,
    this.gameId,
    this.opponentNickname,
    this.isPlayer1 = true,
    this.message = '',
    this.opponentLevel,
    this.opponentLeague,
  });
}

/// Lig bazlı Matchmaking servisi
class MatchmakingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  StreamSubscription? _queueSubscription;
  String? _myQueueKey;
  String? _myLeague;
  Timer? _searchTimer;
  Timer? _timeoutTimer;
  bool _isSearching = false;
  int _waitTimeSeconds = 0;

  Function(MatchResult)? onMatchFound;
  Function()? onTimeout;
  Function(int)? onWaitTimeUpdate;

  /// Eşleşme aramaya başla
  Future<void> startMatchmaking({
    required String difficulty,
    required Function(MatchResult) onMatch,
    required Function() onTimeoutCallback,
    Function(int)? onWaitTime,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    if (_isSearching) {
      print('Already searching...');
      return;
    }

    _isSearching = true;
    _waitTimeSeconds = 0;
    onMatchFound = onMatch;
    onTimeout = onTimeoutCallback;
    onWaitTimeUpdate = onWaitTime;

    try {
      // Kendi bilgilerimi al
      final myNickname = await _friendService.getNicknameByUid(uid);
      int myLevel = 1;
      double myWinRate = 0.0;

      final userSnapshot = await _ref.child('users/$uid/rank').get();
      if (userSnapshot.exists) {
        final rankData = Map<String, dynamic>.from(userSnapshot.value as Map);
        myLevel = rankData['level'] ?? 1;
        myWinRate = (rankData['winRate'] ?? 0.0).toDouble();
      }

      // Lig belirle
      final myLeague = RankCalculator.getLeagueFromLevel(myLevel);
      _myLeague = RankCalculator.getLeagueKey(myLeague);

      print('Starting matchmaking - uid: $uid, nickname: $myNickname, level: $myLevel, league: $_myLeague');

      // Kendi ligimin kuyruğuna ekle
      _myQueueKey = uid; // UID'yi key olarak kullan (duplicate önleme)
      await _ref.child('matchmaking/$_myLeague/$_myQueueKey').set({
        'uid': uid,
        'nickname': myNickname,
        'level': myLevel,
        'winRate': myWinRate,
        'difficulty': difficulty,
        'timestamp': ServerValue.timestamp,
        'matched': false,
        'gameId': null,
        'opponentUid': null,
        'opponentNickname': null,
      });

      print('Added to queue: matchmaking/$_myLeague/$_myQueueKey');

      // Kendi kaydımı dinle - eşleştiğimde bildirilecek
      _queueSubscription = _ref
          .child('matchmaking/$_myLeague/$_myQueueKey')
          .onValue
          .listen((event) {
        if (!event.snapshot.exists) return;

        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        print('Queue data changed: $data');

        if (data['matched'] == true && data['gameId'] != null) {
          _handleMatchFound(
            gameId: data['gameId'],
            opponentNickname: data['opponentNickname'] ?? 'Rakip',
            isPlayer1: data['isPlayer1'] ?? false,
            difficulty: difficulty,
            opponentLevel: data['opponentLevel'],
            opponentLeague: data['opponentLeague'],
          );
        }
      });

      // Her 2 saniyede eşleşme ara
      _searchTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _waitTimeSeconds += 2;
        onWaitTimeUpdate?.call(_waitTimeSeconds);
        _searchForMatch(difficulty, uid, myNickname, myLevel, myWinRate);
      });

      // 90 saniye timeout
      _timeoutTimer = Timer(const Duration(seconds: 90), () {
        print('Matchmaking timeout');
        cancelMatchmaking();
        onTimeout?.call();
      });

      // İlk aramayı hemen yap
      _searchForMatch(difficulty, uid, myNickname, myLevel, myWinRate);

    } catch (e) {
      print('Error starting matchmaking: $e');
      _isSearching = false;
    }
  }

  /// Kuyrukta rakip ara - LİG BAZLI
  Future<void> _searchForMatch(
      String difficulty,
      String myUid,
      String myNickname,
      int myLevel,
      double myWinRate,
      ) async {
    if (!_isSearching) return;

    try {
      final myLeague = RankCalculator.getLeagueFromLevel(myLevel);

      // Bekleme süresine göre aranacak ligleri belirle
      final searchLeagues = RankCalculator.getMatchmakingLeagues(myLeague, _waitTimeSeconds);

      print('Searching in leagues: ${searchLeagues.map((l) => l.name).join(", ")} (wait: $_waitTimeSeconds s)');

      for (var league in searchLeagues) {
        final leagueKey = RankCalculator.getLeagueKey(league);
        final snapshot = await _ref.child('matchmaking/$leagueKey').get();

        if (!snapshot.exists) continue;

        final queue = Map<String, dynamic>.from(snapshot.value as Map);
        print('League $leagueKey has ${queue.length} entries');

        // Eşleşmemiş rakip ara
        for (var entry in queue.entries) {
          final queueKey = entry.key;
          final data = Map<String, dynamic>.from(entry.value as Map);

          // Kendimi atla
          if (data['uid'] == myUid) continue;

          // Zaten eşleşmiş mi
          if (data['matched'] == true) continue;

          // Aynı zorluk seviyesinde mi
          if (data['difficulty'] != difficulty) continue;

          // Rakip buldum! Ama önce Transaction ile kilitle
          final opponentUid = data['uid'];
          final opponentNickname = data['nickname'] ?? 'Rakip';
          final opponentLevel = data['level'] ?? 1;

          print('Found potential opponent: $opponentNickname (Level $opponentLevel) in $leagueKey');

          // Transaction ile atomic olarak eşleştir
          final matchResult = await _tryMatchWithTransaction(
            leagueKey: leagueKey,
            queueKey: queueKey,
            opponentUid: opponentUid,
            opponentNickname: opponentNickname,
            opponentLevel: opponentLevel,
            myUid: myUid,
            myNickname: myNickname,
            myLevel: myLevel,
            difficulty: difficulty,
          );

          if (matchResult != null) {
            // Eşleşme başarılı!
            _handleMatchFound(
              gameId: matchResult['gameId'],
              opponentNickname: opponentNickname,
              isPlayer1: matchResult['isPlayer1'],
              difficulty: difficulty,
              opponentLevel: opponentLevel,
              opponentLeague: leagueKey,
            );
            return;
          }
          // Eşleşme başarısız (başkası kapmış), devam et
        }
      }
    } catch (e) {
      print('Error searching for match: $e');
    }
  }

  /// Transaction ile atomic eşleştirme
  Future<Map<String, dynamic>?> _tryMatchWithTransaction({
    required String leagueKey,
    required String queueKey,
    required String opponentUid,
    required String opponentNickname,
    required int opponentLevel,
    required String myUid,
    required String myNickname,
    required int myLevel,
    required String difficulty,
  }) async {
    try {
      // Rakibin kaydını transaction ile kilitle
      final opponentRef = _ref.child('matchmaking/$leagueKey/$queueKey');

      final transactionResult = await opponentRef.runTransaction((currentData) {
        if (currentData == null) {
          return Transaction.abort();
        }

        final data = Map<String, dynamic>.from(currentData as Map);

        // Zaten eşleşmiş mi kontrol et
        if (data['matched'] == true) {
          return Transaction.abort();
        }

        // Eşleşti olarak işaretle
        data['matched'] = true;
        data['matchedBy'] = myUid;

        return Transaction.success(data);
      });

      if (!transactionResult.committed) {
        print('Transaction aborted - opponent already matched');
        return null;
      }

      // Transaction başarılı, oyun oluştur
      final gameId = await _createGame(
        difficulty: difficulty,
        player1Uid: myUid,
        player1Name: myNickname,
        player1Level: myLevel,
        player2Uid: opponentUid,
        player2Name: opponentNickname,
        player2Level: opponentLevel,
      );

      if (gameId == null) {
        // Oyun oluşturulamadı, rakibi serbest bırak
        await opponentRef.update({'matched': false, 'matchedBy': null});
        return null;
      }

      print('Game created: $gameId');

      // Rakibin kaydını güncelle
      await opponentRef.update({
        'gameId': gameId,
        'opponentUid': myUid,
        'opponentNickname': myNickname,
        'opponentLevel': myLevel,
        'opponentLeague': _myLeague,
        'isPlayer1': false,
      });

      // Kendi kaydımı güncelle
      await _ref.child('matchmaking/$_myLeague/$_myQueueKey').update({
        'matched': true,
        'gameId': gameId,
        'opponentUid': opponentUid,
        'opponentNickname': opponentNickname,
        'opponentLevel': opponentLevel,
        'opponentLeague': leagueKey,
        'isPlayer1': true,
      });

      return {
        'gameId': gameId,
        'isPlayer1': true,
      };

    } catch (e) {
      print('Transaction error: $e');
      return null;
    }
  }

  /// Eşleşme bulundu
  void _handleMatchFound({
    required String gameId,
    required String opponentNickname,
    required bool isPlayer1,
    required String difficulty,
    int? opponentLevel,
    String? opponentLeague,
  }) {
    print('Match found! gameId: $gameId, opponent: $opponentNickname (Level $opponentLevel), isPlayer1: $isPlayer1');

    _searchTimer?.cancel();
    _timeoutTimer?.cancel();
    _queueSubscription?.cancel();
    _isSearching = false;

    // Kuyruktan sil
    _cleanupQueue();

    onMatchFound?.call(MatchResult(
      success: true,
      gameId: gameId,
      opponentNickname: opponentNickname,
      isPlayer1: isPlayer1,
      message: 'Eşleşme bulundu!',
      opponentLevel: opponentLevel,
      opponentLeague: opponentLeague,
    ));
  }

  /// Oyun oluştur
  Future<String?> _createGame({
    required String difficulty,
    required String player1Uid,
    required String player1Name,
    required int player1Level,
    required String player2Uid,
    required String player2Name,
    required int player2Level,
  }) async {
    try {
      final puzzleData = _generateSudokuPuzzle(difficulty);
      final gameRef = _ref.child('games').push();
      final gameId = gameRef.key!;

      await gameRef.set({
        'board': puzzleData['board'],
        'solution': puzzleData['solution'],
        'difficulty': difficulty,
        'player1Uid': player1Uid,
        'player2Uid': player2Uid,
        'player1Name': player1Name,
        'player2Name': player2Name,
        'player1Level': player1Level,
        'player2Level': player2Level,
        'player1Score': 0,
        'player2Score': 0,
        'player1Errors': 0,
        'player2Errors': 0,
        'currentTurn': 1,
        'status': 'playing',
        'createdAt': ServerValue.timestamp,
        'gameType': 'matchmaking',
      });

      return gameId;
    } catch (e) {
      print('Error creating game: $e');
      return null;
    }
  }

  /// Kuyruktan temizle
  Future<void> _cleanupQueue() async {
    if (_myQueueKey != null && _myLeague != null) {
      try {
        await _ref.child('matchmaking/$_myLeague/$_myQueueKey').remove();
      } catch (e) {
        print('Error cleaning up queue: $e');
      }
      _myQueueKey = null;
      _myLeague = null;
    }
  }

  /// Aramayı iptal et
  Future<void> cancelMatchmaking() async {
    print('Cancelling matchmaking...');

    _searchTimer?.cancel();
    _timeoutTimer?.cancel();
    _queueSubscription?.cancel();
    _isSearching = false;
    _waitTimeSeconds = 0;

    await _cleanupQueue();
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
        emptyCells = 37;
        break;
      case 'Orta':
        emptyCells = 48;
        break;
      case 'Zor':
        emptyCells = 54;
        break;
      case 'Uzman':
        emptyCells = 58;
        break;
      case 'Usta':
        emptyCells = 61;
        break;
      case 'Ekstrem':
        emptyCells = 64;
        break;
      default:
        emptyCells = 48;
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
    cancelMatchmaking();
  }
}
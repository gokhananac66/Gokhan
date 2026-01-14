import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import '../main.dart'; // navigatorKey için
import '../services/leaderboard_service.dart';
import '../services/progression_service.dart';
import '../services/user_status_service.dart';
import '../services/recent_players_service.dart';
import '../services/game_invite_service.dart';
import '../services/win_streak_service.dart';
import '../services/achievement_service.dart';
import '../services/theme_service.dart';
import '../widgets/game_result_dialog.dart';
import '../widgets/post_game_stats_dialog.dart';
import '../widgets/win_streak_badge.dart';
import '../widgets/achievement_unlock_dialog.dart';
import '../widgets/hint_dialog.dart';

class OnlineGameScreen extends StatefulWidget {
  final String gameId;
  final bool isPlayer1;
  final String difficulty;
  final String gameMode; // 'classic' or 'race'
  final bool startsFirst;

  const OnlineGameScreen({
    super.key,
    required this.gameId,
    required this.isPlayer1,
    required this.difficulty,
    this.gameMode = 'classic',
    required this.startsFirst,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> isOriginal;
  late List<List<Set<int>>> notes;

  int? selectedRow;
  int? selectedCol;
  bool notesMode = false;

  String player1Name = 'Oyuncu 1';
  String player2Name = 'Oyuncu 2';
  int player1Score = 0;
  int player2Score = 0;
  int player1Errors = 0;
  int player2Errors = 0;
  int player1Progress = 0; // 0-81 (Race mode için)
  int player2Progress = 0; // 0-81 (Race mode için)
  int totalEmptyCells = 0; // Toplam boş hücre sayısı (Race mode progress max değeri)

  int currentTurn = 1;
  late int maxErrors;

  // Race mode warning
  bool _showOpponentWarning = false;
  int _lastOpponentProgress = 0;

  int seconds = 0;
  bool isPaused = false;

  // Turn timer for Classic mode
  int turnTimeRemaining = 30;
  Timer? _turnTimer;
  int _lastTurnNumber = 0;

  // Combo and speed bonus tracking
  int _consecutiveCorrect = 0;
  int _player1ConsecutiveCorrect = 0;
  int _player2ConsecutiveCorrect = 0;
  DateTime? _lastMoveTime;
  bool _firstMoveMade = false;

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // Game theme
  GameTheme? _gameTheme;

  // Confetti controller
  late ConfettiController _confettiController;

  StreamSubscription? _gameSubscription;
  bool _isLoading = true;
  bool _gameEnded = false;

  // Yanlış girilen hücreyi takip et
  int? _lastWrongRow;
  int? _lastWrongCol;

  // Animation: Track recently completed cells for pulse effect
  Set<int> _animatingCells = {}; // Linear cell indices (row * 9 + col)
  Set<int> completedRows = {};
  Set<int> completedCols = {};
  Set<int> completedBoxes = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _setMaxErrors();
    _loadSettings();
    _loadTheme();
    _loadGame();
    _startTimer();

    // Set status to in_online_game
    UserStatusService().updateStatus(UserStatus.inOnlineGame);
  }

  Future<void> _loadTheme() async {
    final themeId = await ThemeService().getSelectedTheme();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setState(() {
      _gameTheme = GameTheme.getTheme(themeId, isDark);
    });
  }

  void _setMaxErrors() {
    switch (widget.difficulty) {
      case 'Kolay':
      case 'Orta':
      case 'Zor':
      case 'Uzman':
        maxErrors = 5;
        break;
      case 'Usta':
      case 'Ekstrem':
        maxErrors = 3;
        break;
      default:
        maxErrors = 5;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    });
  }

  Future<void> _loadGame() async {
    print('🎮 Loading game with ID: ${widget.gameId}');
    print('🎮 Am I Player1: ${widget.isPlayer1}');

    final gameSnapshot = await _database.child('games/${widget.gameId}').get();

    if (!gameSnapshot.exists) {
      _showError('Oyun bulunamadı!');
      return;
    }

    final gameData = Map<String, dynamic>.from(gameSnapshot.value as Map);

    // Race mode: Her oyuncu kendi board'unu görür
    // Classic mode: Tek board paylaşılır
    List<int> flatBoard;
    if (widget.gameMode == 'race') {
      final myBoardKey = widget.isPlayer1 ? 'player1Board' : 'player2Board';
      flatBoard = List<int>.from(gameData[myBoardKey] ?? []);
      print('🏁 [RACE] Loading my board: $myBoardKey');
    } else {
      flatBoard = List<int>.from(gameData['board'] ?? []);
      print('⚔️ [CLASSIC] Loading shared board');
    }

    List<int> flatSolution = List<int>.from(gameData['solution']);

    print('📊 Board first 9 cells: ${flatBoard.sublist(0, 9)}');
    print('📊 Solution first 9 cells: ${flatSolution.sublist(0, 9)}');

    board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
    solution = List.generate(9, (i) => flatSolution.sublist(i * 9, (i + 1) * 9));
    isOriginal = List.generate(9, (i) => List.generate(9, (j) => board[i][j] != 0));
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));

    // Race mode: Toplam boş hücre sayısını hesapla (progress max değeri için)
    if (widget.gameMode == 'race') {
      totalEmptyCells = 0;
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (!isOriginal[i][j]) totalEmptyCells++;
        }
      }
      print('🏁 [RACE] Total empty cells: $totalEmptyCells');
    }

    player1Name = gameData['player1Name'] ?? 'Oyuncu 1';
    player2Name = gameData['player2Name'] ?? 'Oyuncu 2';
    player1Score = gameData['player1Score'] ?? 0;
    player2Score = gameData['player2Score'] ?? 0;
    player1Errors = gameData['player1Errors'] ?? 0;
    player2Errors = gameData['player2Errors'] ?? 0;
    player1Progress = gameData['player1Progress'] ?? 0;
    player2Progress = gameData['player2Progress'] ?? 0;
    currentTurn = gameData['currentTurn'] ?? (widget.startsFirst ? (widget.isPlayer1 ? 1 : 2) : (widget.isPlayer1 ? 2 : 1));

    setState(() => _isLoading = false);
    _listenToGame();

    // Start turn timer for Classic mode
    if (widget.gameMode == 'classic') {
      _startTurnTimer();
    }
  }

  void _listenToGame() {
    _gameSubscription = _database
        .child('games/${widget.gameId}')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists || _gameEnded) return;

      final gameData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final newTurn = gameData['currentTurn'] ?? 1;

      setState(() {
        player1Score = gameData['player1Score'] ?? 0;
        player2Score = gameData['player2Score'] ?? 0;
        player1Errors = gameData['player1Errors'] ?? 0;
        player2Errors = gameData['player2Errors'] ?? 0;
        player1Progress = gameData['player1Progress'] ?? 0;
        player2Progress = gameData['player2Progress'] ?? 0;

        // Race mode: Kendi board'umu güncelle
        // Classic mode: Paylaşılan board'u güncelle
        if (widget.gameMode == 'race') {
          final myBoardKey = widget.isPlayer1 ? 'player1Board' : 'player2Board';
          if (gameData[myBoardKey] != null) {
            List<int> flatBoard = List<int>.from(gameData[myBoardKey]);
            board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
          }

          // Race mode: Rakip ilerlemesini kontrol et ve uyar
          // Warning: Rakip %70 tamamladığında uyar
          int opponentProgress = widget.isPlayer1 ? player2Progress : player1Progress;
          int warningThreshold = (totalEmptyCells * 0.7).toInt();
          if (opponentProgress > _lastOpponentProgress && opponentProgress >= warningThreshold && totalEmptyCells > 0) {
            _showOpponentWarning = true;
            _vibrateHeavy();
            // Ses efekti çal
            if (soundEnabled) {
              SystemSound.play(SystemSoundType.alert);
            }
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _showOpponentWarning = false);
            });
          }
          _lastOpponentProgress = opponentProgress;
        } else {
          if (gameData['board'] != null) {
            List<int> flatBoard = List<int>.from(gameData['board']);
            board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
          }
        }

        // Check if turn changed
        if (currentTurn != newTurn) {
          currentTurn = newTurn;
          if (widget.gameMode == 'classic') {
            _startTurnTimer();
          }
        } else {
          currentTurn = newTurn;
        }
      });

      if (gameData['status'] == 'finished' && !_gameEnded) {
        _gameEnded = true;
        _handleGameEnd(gameData['winner'], gameData['winReason'] ?? 'completed');
      }
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (!isPaused && !_isLoading && !_gameEnded) {
        setState(() => seconds++);
      }
      return true;
    });
  }

  void _playSound() {
    if (soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _vibrate() {
    if (vibrationEnabled) HapticFeedback.mediumImpact();
  }

  void _vibrateHeavy() {
    if (vibrationEnabled) HapticFeedback.heavyImpact();
  }

  void _startTurnTimer() {
    if (widget.gameMode != 'classic') return; // Only for Classic mode

    _turnTimer?.cancel();
    setState(() => turnTimeRemaining = 30);

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _gameEnded) {
        timer.cancel();
        return;
      }

      setState(() => turnTimeRemaining--);

      if (turnTimeRemaining <= 0) {
        timer.cancel();
        _handleTurnTimeout();
      }
    });
  }

  Future<void> _handleTurnTimeout() async {
    if (!isMyTurn || _gameEnded) return;

    // Auto-switch turn on timeout
    await _database.child('games/${widget.gameId}').update({
      'currentTurn': widget.isPlayer1 ? 2 : 1,
    });
  }

  bool get isMyTurn {
    // Race mode: herkes her zaman oynayabilir
    if (widget.gameMode == 'race') return true;

    // Classic mode: sıra bazlı
    return widget.isPlayer1 ? currentTurn == 1 : currentTurn == 2;
  }

  int get myScore => widget.isPlayer1 ? player1Score : player2Score;

  void _selectCell(int row, int col) {
    if (!isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sıra rakipte! Bekle...'), duration: Duration(seconds: 1)),
      );
      return;
    }
    _playSound();
    _vibrate();
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  Future<void> _inputNumber(int number) async {
    if (!isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sıra rakipte! Bekle...'), duration: Duration(seconds: 1)),
      );
      return;
    }

    if (selectedRow == null || selectedCol == null) return;
    if (isOriginal[selectedRow!][selectedCol!]) return;
    if (board[selectedRow!][selectedCol!] == solution[selectedRow!][selectedCol!]) return;

    _playSound();
    _vibrate();

    int row = selectedRow!;
    int col = selectedCol!;

    // Önceki yanlış hücreyi temizle
    if (_lastWrongRow != null && _lastWrongCol != null) {
      if (board[_lastWrongRow!][_lastWrongCol!] != solution[_lastWrongRow!][_lastWrongCol!]) {
        board[_lastWrongRow!][_lastWrongCol!] = 0;
      }
      _lastWrongRow = null;
      _lastWrongCol = null;
    }

    if (notesMode) {
      setState(() {
        if (notes[row][col].contains(number)) {
          notes[row][col].remove(number);
        } else {
          notes[row][col].add(number);
        }
      });
    } else {
      bool isCorrect = number == solution[row][col];

      List<int> flatBoard = board.expand((r) => r).toList();
      flatBoard[row * 9 + col] = number;

      // Race mode: Kendi board'umu güncelle
      // Classic mode: Paylaşılan board'u güncelle
      Map<String, dynamic> updates = {};
      if (widget.gameMode == 'race') {
        final myBoardKey = widget.isPlayer1 ? 'player1Board' : 'player2Board';
        updates[myBoardKey] = flatBoard;
      } else {
        updates['board'] = flatBoard;
      }

      if (isCorrect) {
        String scoreKey = widget.isPlayer1 ? 'player1Score' : 'player2Score';
        int currentScore = widget.isPlayer1 ? player1Score : player2Score;

        // Calculate score with bonuses
        int points = 10; // Base score

        // First move bonus
        if (!_firstMoveMade) {
          points += 10;
          _firstMoveMade = true;
        }

        // Speed bonus (move within 10 seconds)
        final now = DateTime.now();
        if (_lastMoveTime != null) {
          final diff = now.difference(_lastMoveTime!).inSeconds;
          if (diff <= 10) {
            points += 50;
          }
        }
        _lastMoveTime = now;

        // Combo bonus (3+ consecutive correct moves)
        _consecutiveCorrect++;
        if (widget.isPlayer1) {
          _player1ConsecutiveCorrect++;
        } else {
          _player2ConsecutiveCorrect++;
        }

        if (_consecutiveCorrect >= 3) {
          points += 5;
        }

        updates[scoreKey] = currentScore + points;

        // Race mode: Progress güncelle (sadece KULLANICININ doldurduğu doğru hücreler)
        if (widget.gameMode == 'race') {
          int correctCells = 0;
          for (int i = 0; i < 9; i++) {
            for (int j = 0; j < 9; j++) {
              // Sadece kullanıcının doldurduğu doğru hücreleri say (başlangıç hücreleri değil!)
              if (!isOriginal[i][j] && board[i][j] != 0 && board[i][j] == solution[i][j]) {
                correctCells++;
              }
            }
          }
          String progressKey = widget.isPlayer1 ? 'player1Progress' : 'player2Progress';
          updates[progressKey] = correctCells;
        }

        setState(() {
          board[row][col] = number;
          notes[row][col].clear();
        });

        // Classic mode: Doğru hamle yaptı, timer'ı reset et!
        if (widget.gameMode == 'classic') {
          _startTurnTimer();
        }

        // Show bonus notification if earned
        if (points > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 +$points puan! ${points > 50 ? 'Hızlı hareket!' : points > 15 ? 'Kombo!' : 'İlk hamle bonusu!'}'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (_checkWin()) {
          await _database.child('games/${widget.gameId}').update(updates);
          await _endGame('completed');
          return;
        }
      } else {
        _vibrateHeavy();

        // Reset combo on wrong move
        _consecutiveCorrect = 0;
        if (widget.isPlayer1) {
          _player1ConsecutiveCorrect = 0;
        } else {
          _player2ConsecutiveCorrect = 0;
        }

        String errorKey = widget.isPlayer1 ? 'player1Errors' : 'player2Errors';
        int currentErrors = widget.isPlayer1 ? player1Errors : player2Errors;
        int newErrors = currentErrors + 1;
        updates[errorKey] = newErrors;

        // Classic mode: yanlış yaparsan sıra değişir
        // Race mode: sıra değişmez, herkes devam eder
        if (widget.gameMode == 'classic') {
          updates['currentTurn'] = widget.isPlayer1 ? 2 : 1;
        }

        // Yanlış hücreyi kaydet
        _lastWrongRow = row;
        _lastWrongCol = col;

        setState(() {
          board[row][col] = number;
          notes[row][col].clear();
        });

        if (newErrors >= maxErrors) {
          await _database.child('games/${widget.gameId}').update(updates);
          await _endGame('errors');
          return;
        }
      }

      await _database.child('games/${widget.gameId}').update(updates);
    }
  }

  bool _checkWin() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != solution[i][j]) return false;
      }
    }
    return true;
  }

  Future<void> _endGame(String reason) async {
    String winner;

    if (reason == 'errors') {
      int myErr = widget.isPlayer1 ? player1Errors + 1 : player2Errors + 1;
      if (myErr >= maxErrors) {
        winner = widget.isPlayer1 ? player2Name : player1Name;
      } else {
        winner = widget.isPlayer1 ? player1Name : player2Name;
      }
    } else if (reason == 'completed') {
      // Race mode: İlk bitiren kazanır (bu fonksiyonu çağıran kazanır)
      // Classic mode: Skor karşılaştır
      if (widget.gameMode == 'race') {
        winner = widget.isPlayer1 ? player1Name : player2Name; // Ben bitirdim, ben kazandım
      } else {
        if (player1Score > player2Score) {
          winner = player1Name;
        } else if (player2Score > player1Score) {
          winner = player2Name;
        } else {
          winner = 'draw';
        }
      }
    } else {
      if (player1Score > player2Score) {
        winner = player1Name;
      } else if (player2Score > player1Score) {
        winner = player2Name;
      } else {
        winner = 'draw';
      }
    }

    await _database.child('games/${widget.gameId}').update({
      'status': 'finished',
      'winner': winner,
      'winReason': reason,
      'finishedAt': ServerValue.timestamp,
    });
  }

  Future<void> _handleGameEnd(String? winner, String reason) async {
    _gameSubscription?.cancel();

    String myName = widget.isPlayer1 ? player1Name : player2Name;
    int myScore = widget.isPlayer1 ? player1Score : player2Score;
    int opponentScore = widget.isPlayer1 ? player2Score : player1Score;
    int myErrors = widget.isPlayer1 ? player1Errors : player2Errors;

    bool isDraw = winner == 'draw' || (reason == 'completed' && myScore == opponentScore);
    bool iWon;

    if (isDraw) {
      iWon = false; // Beraberede kimse kazanmadı
    } else if (reason == 'abandoned') {
      // Terk eden kaybeder - winner Firebase'den rakibin ismi olarak geliyor
      iWon = winner == myName;
    } else if (reason == 'errors') {
      // Hata limiti aşıldıysa, ben mi aştım kontrol et
      iWon = myErrors < maxErrors;
    } else if (reason == 'completed') {
      // Oyun tamamlandı - skor karşılaştır
      iWon = myScore > opponentScore;
    } else {
      // Fallback - winner ismine bak
      iWon = winner == myName;
    }


    // LEADERBOARD'A KAYDET (Kazanan ve Kaybeden için)
    WinStreakResult? streakResult;
    if (!isDraw) {
      print('📊 Submitting to leaderboard - Won: $iWon, Score: $myScore, Mode: ${widget.gameMode}');
      try {
        await LeaderboardService.submitGameResult(
          won: iWon,
          scoreEarned: iWon ? myScore : 0,
          gameMode: widget.gameMode,
          gameTimeSeconds: seconds, // Oyun süresi (Race mode için fastest win tracking)
        );
        print('✅ Leaderboard submission SUCCESS!');

        // Progression system - kazanıldıysa zorluk seviyesi kazanma sayısını artır
        if (iWon) {
          await ProgressionService.incrementWins(widget.difficulty);
          print('📈 Progression updated for difficulty: ${widget.difficulty}');
          // Play confetti animation
          _confettiController.play();
        }

        // Track win streak
        streakResult = await WinStreakService().recordGameResult(iWon);
        if (streakResult.milestoneReached && streakResult.milestoneStreak != null) {
          print('🎉 Milestone reached: ${streakResult.milestoneStreak} wins!');
        }

        // Check achievements
        final newAchievements = await AchievementService().checkGameAchievements(
          isWin: iWon,
          gameTimeSeconds: seconds,
          errorCount: widget.isPlayer1 ? player1Errors : player2Errors,
          currentWinStreak: streakResult.currentStreak,
        );

        if (newAchievements.isNotEmpty) {
          print('🏆 Achievements unlocked: ${newAchievements.map((a) => a.id).join(', ')}');
        }
      } catch (e) {
        print('❌ Leaderboard submission ERROR: $e');
      }
    } else {
      print('⏭️ Draw - NOT submitting to leaderboard');
    }

    // Record recent player
    await _recordRecentPlayer(iWon, isDraw);

    _showWinDialog(winner, reason, iWon, isDraw, streakResult);
  }

  Future<void> _recordRecentPlayer(bool iWon, bool isDraw) async {
    try {
      final opponentUid = await _getOpponentUid();
      if (opponentUid == null) return;

      final opponentName = widget.isPlayer1 ? player2Name : player1Name;
      final gameResult = isDraw ? 'draw' : (iWon ? 'win' : 'loss');

      await RecentPlayersService().addRecentPlayer(
        opponentUid: opponentUid,
        opponentNickname: opponentName,
        gameResult: gameResult,
        gameMode: widget.gameMode,
        difficulty: widget.difficulty,
      );

      print('✅ Recent player recorded: $opponentName ($gameResult)');
    } catch (e) {
      print('❌ Failed to record recent player: $e');
    }
  }

  Future<String?> _getOpponentUid() async {
    try {
      final gameSnapshot = await _database.child('games/${widget.gameId}').get();
      if (!gameSnapshot.exists) return null;

      final gameData = Map<String, dynamic>.from(gameSnapshot.value as Map);
      final player1Uid = gameData['player1Uid'];
      final player2Uid = gameData['player2Uid'];

      return widget.isPlayer1 ? player2Uid : player1Uid;
    } catch (e) {
      print('❌ Failed to get opponent UID: $e');
      return null;
    }
  }

  void _showWinDialog(String? winner, String reason, bool iWon, bool isDraw, [WinStreakResult? streakResult]) {
    final gameContext = context; // Game screen context'ini yakala

    // Calculate move counts (approximate from score)
    final myMoves = (widget.isPlayer1 ? player1Score : player2Score) ~/ 10;
    final opponentMoves = (widget.isPlayer1 ? player2Score : player1Score) ~/ 10;
    final myErrors = widget.isPlayer1 ? player1Errors : player2Errors;
    final opponentErrors = widget.isPlayer1 ? player2Errors : player1Errors;
    final opponentName = widget.isPlayer1 ? player2Name : player1Name;

    // Show post-game stats first
    showDialog(
      context: gameContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) => PostGameStatsDialog(
        isWinner: iWon,
        isDraw: isDraw,
        opponentNickname: opponentName,
        myTime: seconds,
        opponentTime: seconds, // Both players have same game time
        myMoves: myMoves,
        opponentMoves: opponentMoves,
        myErrors: myErrors,
        opponentErrors: opponentErrors,
        gameMode: widget.gameMode,
        difficulty: widget.difficulty,
        onRematch: () async {
          // Get opponent UID for rematch invite
          final opponentUid = await _getOpponentUid();
          if (opponentUid != null) {
            final inviteService = GameInviteService();
            final result = await inviteService.sendInvite(
              targetUid: opponentUid,
              targetNickname: opponentName,
              difficulty: widget.difficulty,
              gameMode: widget.gameMode,
              isRevanche: true,
            );

            if (result.success) {
              // ✅ Rövanş daveti başarılı - Davet gönderen kişi için listener başlat
              final inviteId = result.inviteId;
              final gameId = result.gameId;

              print('🎮 [REVANCHE] Invite sent successfully. InviteId: $inviteId, GameId: $gameId');

              // Ana ekrana dön
              if (mounted && Navigator.canPop(gameContext)) {
                Navigator.popUntil(gameContext, (route) => route.isFirst || route.settings.name == '/home');
              }

              // Show success message
              ScaffoldMessenger.of(gameContext).showSnackBar(
                SnackBar(
                  content: Text('Rövanş daveti gönderildi! Rakip kabul ederse oyuna başlayacaksınız... 🔥'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );

              // ✅ ÇÖZÜM: Davet kabul edildiğinde otomatik oyuna başla
              if (inviteId != null && gameId != null) {
                final inviteService = GameInviteService();

                // Davet durumunu dinle
                final inviteRef = FirebaseDatabase.instance.ref().child('game_invites/$inviteId');
                final subscription = inviteRef.onValue.listen((event) async {
                  if (!event.snapshot.exists) return;

                  final data = Map<String, dynamic>.from(event.snapshot.value as Map);
                  final status = data['status']?.toString();

                  print('🔔 [REVANCHE] Invite status changed: $status');

                  if (status == 'accepted') {
                    print('✅ [REVANCHE] Invite accepted! Starting game...');

                    // Oyun verilerini al
                    final gameSnapshot = await FirebaseDatabase.instance.ref().child('games/$gameId').get();
                    if (!gameSnapshot.exists) {
                      print('❌ [REVANCHE] Game not found: $gameId');
                      return;
                    }

                    final gameData = Map<String, dynamic>.from(gameSnapshot.value as Map);
                    final player1Uid = gameData['player1Uid']?.toString();
                    final player2Uid = gameData['player2Uid']?.toString();
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;

                    final isPlayer1 = currentUid == player1Uid;

                    // Navigator key ile context'e erişim (global)
                    final navigatorContext = navigatorKey.currentContext;
                    if (navigatorContext != null && navigatorContext.mounted) {
                      Navigator.push(
                        navigatorContext,
                        MaterialPageRoute(
                          builder: (context) => OnlineGameScreen(
                            gameId: gameId,
                            difficulty: gameData['difficulty']?.toString() ?? 'Orta',
                            isPlayer1: isPlayer1,
                            gameMode: gameData['gameMode']?.toString() ?? 'classic',
                            startsFirst: isPlayer1, // Player1 başlar
                          ),
                        ),
                      );
                    }
                  } else if (status == 'rejected' || status == 'expired') {
                    print('❌ [REVANCHE] Invite $status');
                    // Kullanıcıya bildir
                    final navigatorContext = navigatorKey.currentContext;
                    if (navigatorContext != null && navigatorContext.mounted) {
                      ScaffoldMessenger.of(navigatorContext).showSnackBar(
                        SnackBar(
                          content: Text(status == 'rejected' ? 'Rövanş daveti reddedildi.' : 'Rövanş daveti zaman aşımına uğradı.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                });

                // 35 saniye sonra listener'ı temizle (timeout + buffer)
                Future.delayed(Duration(seconds: 35), () {
                  subscription.cancel();
                });
              }
            } else {
              ScaffoldMessenger.of(gameContext).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        onClose: () {
          // Show milestone dialog if reached
          if (streakResult != null &&
              streakResult.milestoneReached &&
              streakResult.milestoneStreak != null &&
              streakResult.milestoneReward != null) {
            showDialog(
              context: gameContext,
              builder: (context) => MilestoneReachedDialog(
                milestoneStreak: streakResult.milestoneStreak!,
                rewardPoints: streakResult.milestoneReward!,
              ),
            ).then((_) {
              // Navigate back to home after milestone dialog
              if (mounted && Navigator.canPop(gameContext)) {
                Navigator.popUntil(gameContext, (route) => route.isFirst || route.settings.name == '/home');
              }
            });
          } else {
            // Navigate back to home
            if (mounted && Navigator.canPop(gameContext)) {
              Navigator.popUntil(gameContext, (route) => route.isFirst || route.settings.name == '/home');
            }
          }
        },
      ),
    );

    // Keep old dialog commented for reference
    /*
    showDialog(
      context: gameContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => GameResultDialog(
        isWin: iWon,
        isDraw: isDraw,
        score: widget.isPlayer1 ? player1Score : player2Score,
        time: seconds,
        errors: widget.isPlayer1 ? player1Errors : player2Errors,
        maxErrors: maxErrors,
        isMultiplayer: true,
        player1Score: player1Score,
        player2Score: player2Score,
        player1Name: player1Name,
        player2Name: player2Name,
        onNewGame: () {
          Navigator.pop(dialogContext); // Dialog'u kapat
          // Dialog animasyonu bitsin diye kısa delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && Navigator.canPop(gameContext)) {
              Navigator.pop(gameContext); // Game screen'i kapat
            }
          });
        },
        onMainMenu: () {
          Navigator.pop(dialogContext); // Dialog'u kapat
          // Dialog animasyonu bitsin diye kısa delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // HomeScreen'e kadar tüm ekranları kapat (FriendsScreen, LobbyScreen, GameScreen)
              Navigator.popUntil(gameContext, (route) {
                // HomeScreen veya LoginScreen'e gelene kadar pop et
                return route.isFirst || route.settings.name == '/home';
              });
            }
          });
        },
      ),
    );
    */
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _clearCell() {
    if (!isMyTurn) return;
    if (selectedRow == null || selectedCol == null) return;
    if (isOriginal[selectedRow!][selectedCol!]) return;

    _playSound();
    _vibrate();

    setState(() {
      board[selectedRow!][selectedCol!] = 0;
      notes[selectedRow!][selectedCol!].clear();
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _leaveGame() async {
    _gameSubscription?.cancel();

    String winner = widget.isPlayer1 ? player2Name : player1Name;

    // Firebase'e oyun sonu bilgisini yaz
    await _database.child('games/${widget.gameId}').update({
      'status': 'finished',
      'winner': winner,
      'winReason': 'abandoned',
      'finishedAt': ServerValue.timestamp,
    });

    // Firebase'in update'i yayması için kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _gameSubscription?.cancel();
    _turnTimer?.cancel();

    // Set status back to idle
    UserStatusService().updateStatus(UserStatus.idle);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Oyun yükleniyor...', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildScoreBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: _buildSudokuGrid(),
                  ),
                ),
                _buildActionButtons(),
                _buildNumberButtons(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Confetti widget
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                          ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
                          : [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade700],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.exit_to_app, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        const Text(
                          'Oyundan Çık',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Message
                        Text(
                          'Çıkarsan oyunu kaybedersin. Emin misin?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  foregroundColor: isDark ? Colors.white : Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('İptal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _leaveGame();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Çık', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text('CANLI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
              ],
            ),
          ),
          const Spacer(),
          Text(_formatTime(seconds), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    bool amIPlayer1 = widget.isPlayer1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D)]
            : [Colors.grey.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Warning Banner (Race mode)
          if (widget.gameMode == 'race' && _showOpponentWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '⚠️ Rakip bitirmeye çok yakın! Hızlan!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.gameMode == 'race' && _showOpponentWarning)
            const SizedBox(height: 8),

          // Player Cards
          Row(
            children: [
              // Player 1 Card (my card if I'm player1)
              Expanded(
                child: _buildPlayerCard(
                  name: player1Name,
                  score: player1Score,
                  errors: player1Errors,
                  progress: player1Progress,
                  // Race mode: Her iki oyuncu da vurgulu (aynı anda oynayabilirler)
                  // Classic mode: Sadece sıradaki oyuncu vurgulu
                  isMyTurn: widget.gameMode == 'race' ? true : currentTurn == 1,
                  isMe: amIPlayer1,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),

              // VS Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.pink.shade400],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text('⚔️', style: TextStyle(fontSize: 16)),
                    ),

                    // Race mode: Progress difference
                    if (widget.gameMode == 'race' && totalEmptyCells > 0) ...[
                      const SizedBox(height: 6),
                      _buildProgressDifference(isDark),
                    ],

                    if (widget.gameMode == 'classic') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: turnTimeRemaining <= 10 ? Colors.red.shade600 : Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (turnTimeRemaining <= 10 ? Colors.red : Colors.blue).withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              '$turnTimeRemaining',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Player 2 Card (my card if I'm player2)
              Expanded(
                child: _buildPlayerCard(
                  name: player2Name,
                  score: player2Score,
                  errors: player2Errors,
                  progress: player2Progress,
                  // Race mode: Her iki oyuncu da vurgulu (aynı anda oynayabilirler)
                  // Classic mode: Sadece sıradaki oyuncu vurgulu
                  isMyTurn: widget.gameMode == 'race' ? true : currentTurn == 2,
                  isMe: !amIPlayer1,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDifference(bool isDark) {
    final amIPlayer1 = widget.isPlayer1;
    final myProgress = amIPlayer1 ? player1Progress : player2Progress;
    final opponentProgress = amIPlayer1 ? player2Progress : player1Progress;
    final difference = myProgress - opponentProgress;

    if (difference == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'EŞIT',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      );
    }

    final isAhead = difference > 0;
    final absValue = difference.abs();
    final displayColor = isAhead ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: displayColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAhead ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: displayColor,
          ),
          const SizedBox(width: 2),
          Text(
            isAhead ? '+$absValue' : '-$absValue',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required int score,
    required int errors,
    required int progress, // 0-totalEmptyCells for race mode
    required bool isMyTurn,
    required bool isMe,
    required MaterialColor color,
    required bool isDark,
  }) {
    final errorProgress = (maxErrors - errors) / maxErrors;
    // Race mode: Progress bar 0.0-1.0 arası (totalEmptyCells'e göre)
    final completionProgress = totalEmptyCells > 0 ? (progress / totalEmptyCells) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMyTurn
            ? [color.withOpacity(0.3), color.withOpacity(0.15)]
            : isDark
              ? [Colors.grey.shade800, Colors.grey.shade900]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: isMyTurn ? 3 : 1.5,
        ),
        boxShadow: isMyTurn ? [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color[300]!, color[600]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isMyTurn ? color[700]! : (isDark ? Colors.white : Colors.black87),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SEN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '⭐',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isMyTurn ? color[700]! : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bars
          Column(
            children: [
              // Race mode: Completion Progress
              if (widget.gameMode == 'race') ...[
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(
                    begin: 0.0,
                    end: completionProgress,
                  ),
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(
                          value >= 0.8
                            ? Colors.red
                            : (value >= 0.6 ? Colors.orange : Colors.green),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progress/$totalEmptyCells',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (totalEmptyCells > 0 && progress >= (totalEmptyCells * 0.7).toInt())
                      Text(
                        '🏁',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Error Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: errorProgress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(
                    errorProgress > 0.5 ? Colors.green : (errorProgress > 0.25 ? Colors.orange : Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '❌ $errors / $maxErrors',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Turn Indicator (only in Classic mode)
          if (isMyTurn && widget.gameMode == 'classic') ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💚', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    isMe ? 'SENDE!' : 'OYNUYOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSudokuGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 32,
          maxHeight: MediaQuery.of(context).size.width - 32,
        ),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: List.generate(3, (blockRow) => Expanded(
                child: Row(
                  children: List.generate(3, (blockCol) => Expanded(
                    child: Container(
                      margin: EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade800,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        children: List.generate(3, (cellRow) => Expanded(
                          child: Row(
                            children: List.generate(3, (cellCol) {
                              final row = blockRow * 3 + cellRow;
                              final col = blockCol * 3 + cellCol;
                              return Expanded(child: _buildCell(row, col));
                            }),
                          ),
                        )),
                      ),
                    ),
                  )),
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use theme colors, fallback to default if not loaded yet
    final theme = _gameTheme ?? GameTheme.getTheme('default', isDark);

    bool isSelected = row == selectedRow && col == selectedCol;
    bool isOriginalCell = isOriginal[row][col];
    bool isWrong = board[row][col] != 0 && board[row][col] != solution[row][col] && !isOriginalCell;
    int value = board[row][col];
    Set<int> cellNotes = notes[row][col];

    // Check animation state
    final cellIndex = row * 9 + col;
    final isAnimating = _animatingCells.contains(cellIndex);

    // Check if in completed group
    int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
    bool isInCompletedGroup = completedRows.contains(row) || completedCols.contains(col) || completedBoxes.contains(boxIndex);

    // Arka plan rengi - tema kullan
    Color bgColor;
    if (isWrong) {
      bgColor = isDark ? Colors.red.withOpacity(0.3) : const Color(0xFFFFCDD2);
    } else if (isSelected) {
      bgColor = isMyTurn ? theme.selectedCell : theme.highlightedCell;
    } else if (isInCompletedGroup) {
      bgColor = theme.completedCell;
    } else {
      bgColor = isDark ? const Color(0xFF262626) : Colors.white;
    }

    // Yazı rengi - HATALAR BELİRGİN KIRMIZI
    Color textColor;
    if (isWrong) {
      textColor = const Color(0xFFE53935); // Belirgin kırmızı
    } else if (isOriginalCell) {
      textColor = theme.textColor;
    } else {
      textColor = theme.textColor.withOpacity(0.8);
    }

    return AnimatedScale(
      scale: isAnimating ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: GestureDetector(
        onTap: () => _selectCell(row, col),
        child: Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Center(
            child: value != 0
                ? Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isOriginalCell ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  )
                : cellNotes.isNotEmpty
                    ? GridView.count(
                        crossAxisCount: 3,
                        padding: const EdgeInsets.all(1),
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(
                          9,
                          (i) => Center(
                            child: Text(
                              cellNotes.contains(i + 1) ? '${i + 1}' : '',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.delete_outline, 'Sil', _clearCell),
          _buildActionButton(Icons.edit_note, notesMode ? 'NOT: ON' : 'NOT: OFF', () {
            _playSound();
            _vibrate();
            setState(() => notesMode = !notesMode);
          }, isActive: notesMode),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.grey.shade700, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.blue : Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildNumberButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (i) {
          int num = i + 1;
          bool canPress = isMyTurn;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canPress ? () => _inputNumber(num) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        '$num',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: canPress
                              ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
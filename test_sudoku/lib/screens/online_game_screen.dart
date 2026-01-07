import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/leaderboard_service.dart';
import '../services/progression_service.dart';
import '../widgets/game_result_dialog.dart';

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

  int currentTurn = 1;
  late int maxErrors;

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

  StreamSubscription? _gameSubscription;
  bool _isLoading = true;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _setMaxErrors();
    _loadSettings();
    _loadGame();
    _startTimer();
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

    List<int> flatBoard = List<int>.from(gameData['board']);
    List<int> flatSolution = List<int>.from(gameData['solution']);

    print('📊 Board first 9 cells: ${flatBoard.sublist(0, 9)}');
    print('📊 Solution first 9 cells: ${flatSolution.sublist(0, 9)}');

    board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
    solution = List.generate(9, (i) => flatSolution.sublist(i * 9, (i + 1) * 9));
    isOriginal = List.generate(9, (i) => List.generate(9, (j) => board[i][j] != 0));
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));

    player1Name = gameData['player1Name'] ?? 'Oyuncu 1';
    player2Name = gameData['player2Name'] ?? 'Oyuncu 2';
    player1Score = gameData['player1Score'] ?? 0;
    player2Score = gameData['player2Score'] ?? 0;
    player1Errors = gameData['player1Errors'] ?? 0;
    player2Errors = gameData['player2Errors'] ?? 0;
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

        if (gameData['board'] != null) {
          List<int> flatBoard = List<int>.from(gameData['board']);
          board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
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

  bool get isMyTurn => widget.isPlayer1 ? currentTurn == 1 : currentTurn == 2;

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

      Map<String, dynamic> updates = {'board': flatBoard};

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

        setState(() {
          board[row][col] = number;
          notes[row][col].clear();
        });

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
        updates['currentTurn'] = widget.isPlayer1 ? 2 : 1;

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

    // DEBUG LOG
    print('=== GAME END DEBUG ===');
    print('Winner from Firebase: $winner');
    print('Reason: $reason');
    print('My Name: $myName');
    print('Am I Player1: ${widget.isPlayer1}');
    print('Player1 Name: $player1Name, Score: $player1Score, Errors: $player1Errors');
    print('Player2 Name: $player2Name, Score: $player2Score, Errors: $player2Errors');
    print('My Score: $myScore, Opponent Score: $opponentScore');
    print('Is Draw: $isDraw');
    print('I Won: $iWon');
    print('======================');

    // LEADERBOARD'A KAYDET (Kazanan ve Kaybeden için)
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
        }
      } catch (e) {
        print('❌ Leaderboard submission ERROR: $e');
      }
    } else {
      print('⏭️ Draw - NOT submitting to leaderboard');
    }

    _showWinDialog(winner, reason, iWon, isDraw);
  }

  void _showWinDialog(String? winner, String reason, bool iWon, bool isDraw) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => GameResultDialog(
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
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onMainMenu: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
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
    _gameSubscription?.cancel();
    _turnTimer?.cancel();
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

    return Scaffold(
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Oyundan Çık'),
                  content: const Text('Çıkarsan oyunu kaybedersin. Emin misin?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _leaveGame();
                      },
                      child: const Text('Çık', style: TextStyle(color: Colors.red)),
                    ),
                  ],
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
      child: Row(
        children: [
          // Player 1 Card
          Expanded(
            child: _buildPlayerCard(
              name: player1Name,
              score: player1Score,
              errors: player1Errors,
              isMyTurn: currentTurn == 1,
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

          // Player 2 Card
          Expanded(
            child: _buildPlayerCard(
              name: player2Name,
              score: player2Score,
              errors: player2Errors,
              isMyTurn: currentTurn == 2,
              isMe: !amIPlayer1,
              color: Colors.orange,
              isDark: isDark,
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
    required bool isMyTurn,
    required bool isMe,
    required MaterialColor color,
    required bool isDark,
  }) {
    final progress = (maxErrors - errors) / maxErrors;

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

          // Progress Bar
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.5 ? Colors.green : (progress > 0.25 ? Colors.orange : Colors.red),
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

          // Turn Indicator
          if (isMyTurn) ...[
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: List.generate(9, (row) => Expanded(
                  child: Row(children: List.generate(9, (col) => Expanded(child: _buildCell(row, col)))),
                )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = row == selectedRow && col == selectedCol;
    bool isOriginalCell = isOriginal[row][col];
    bool isWrong = board[row][col] != 0 && board[row][col] != solution[row][col] && !isOriginalCell;
    int value = board[row][col];
    Set<int> cellNotes = notes[row][col];

    // Border widths for 3x3 blocks
    double rightBorder = (col == 2 || col == 5) ? 2.0 : 0.8;
    double bottomBorder = (row == 2 || row == 5) ? 2.0 : 0.8;

    // Colors
    Color bgColor;
    if (isWrong) {
      bgColor = Colors.red.shade100;
    } else if (isSelected) {
      bgColor = isMyTurn
        ? Colors.blue.shade100
        : Colors.grey.shade300;
    } else {
      bgColor = isDark ? Color(0xFF2D2D2D) : Colors.white;
    }

    return GestureDetector(
      onTap: () => _selectCell(row, col),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: row == 0 ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: 0,
            ),
            left: BorderSide(
              color: col == 0 ? Colors.transparent : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: 0,
            ),
            right: BorderSide(
              color: (col == 2 || col == 5)
                ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: rightBorder,
            ),
            bottom: BorderSide(
              color: (row == 2 || row == 5)
                ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: bottomBorder,
            ),
          ),
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: isOriginalCell ? FontWeight.w700 : FontWeight.w500,
                    color: isOriginalCell
                        ? (isDark ? Colors.white : Colors.black87)
                        : isWrong
                            ? Colors.red.shade700
                            : Colors.blue.shade600,
                  ),
                )
              : cellNotes.isNotEmpty
                  ? GridView.count(
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(2),
                      children: List.generate(
                        9,
                        (i) => Center(
                          child: Text(
                            cellNotes.contains(i + 1) ? '${i + 1}' : '',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (i) {
          int num = i + 1;
          bool canPress = isMyTurn;

          return InkWell(
            onTap: canPress ? () => _inputNumber(num) : null,
            child: Container(
              width: 34,
              height: 46,
              decoration: BoxDecoration(
                color: canPress ? Colors.blue : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('$num', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
          );
        }),
      ),
    );
  }
}
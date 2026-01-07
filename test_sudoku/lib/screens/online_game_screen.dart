import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/leaderboard_service.dart';
import '../widgets/game_result_dialog.dart';

class OnlineGameScreen extends StatefulWidget {
  final String gameId;
  final bool isPlayer1;
  final String difficulty;
  final bool startsFirst;

  const OnlineGameScreen({
    super.key,
    required this.gameId,
    required this.isPlayer1,
    required this.difficulty,
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
  }

  void _listenToGame() {
    _gameSubscription = _database
        .child('games/${widget.gameId}')
        .onValue
        .listen((event) {
      if (!event.snapshot.exists || _gameEnded) return;

      final gameData = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        player1Score = gameData['player1Score'] ?? 0;
        player2Score = gameData['player2Score'] ?? 0;
        player1Errors = gameData['player1Errors'] ?? 0;
        player2Errors = gameData['player2Errors'] ?? 0;
        currentTurn = gameData['currentTurn'] ?? 1;

        if (gameData['board'] != null) {
          List<int> flatBoard = List<int>.from(gameData['board']);
          board = List.generate(9, (i) => flatBoard.sublist(i * 9, (i + 1) * 9));
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
        updates[scoreKey] = currentScore + 10;

        setState(() {
          board[row][col] = number;
          notes[row][col].clear();
        });

        if (_checkWin()) {
          await _database.child('games/${widget.gameId}').update(updates);
          await _endGame('completed');
          return;
        }
      } else {
        _vibrateHeavy();

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

    // KAZANAN İÇİN LEADERBOARD'A KAYDET
    if (iWon && !isDraw) {
      print('📊 Submitting to leaderboard with score: $myScore');
      try {
        await LeaderboardService.submitMultiplayerWin(scoreEarned: myScore);
        print('✅ Leaderboard submission SUCCESS!');
      } catch (e) {
        print('❌ Leaderboard submission ERROR: $e');
      }
    } else {
      print('⏭️ NOT submitting to leaderboard - iWon: $iWon, isDraw: $isDraw');
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
            _buildTurnIndicator(),
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

  Widget _buildTurnIndicator() {
    String turnText = isMyTurn ? '🎯 SENİN SIRAN!' : '⏳ Rakibin oynuyor...';
    Color bgColor = isMyTurn ? Colors.green.shade100 : Colors.grey.shade200;
    Color textColor = isMyTurn ? Colors.green.shade700 : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: bgColor,
      child: Text(
        turnText,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
      ),
    );
  }

  Widget _buildScoreBar() {
    bool amIPlayer1 = widget.isPlayer1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (currentTurn == 1) ? Colors.green.shade100 : (amIPlayer1 ? Colors.blue.shade50 : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (currentTurn == 1) ? Colors.green : (amIPlayer1 ? Colors.blue : Colors.grey.shade300),
                  width: (currentTurn == 1) ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          player1Name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: (currentTurn == 1) ? Colors.green.shade700 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (amIPlayer1) const SizedBox(width: 4),
                      if (amIPlayer1) const Text('(Sen)', style: TextStyle(fontSize: 10, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$player1Score puan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('❌ $player1Errors / $maxErrors', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('⚔️', style: TextStyle(fontSize: 20)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (currentTurn == 2) ? Colors.green.shade100 : (!amIPlayer1 ? Colors.blue.shade50 : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (currentTurn == 2) ? Colors.green : (!amIPlayer1 ? Colors.blue : Colors.grey.shade300),
                  width: (currentTurn == 2) ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          player2Name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: (currentTurn == 2) ? Colors.green.shade700 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!amIPlayer1) const SizedBox(width: 4),
                      if (!amIPlayer1) const Text('(Sen)', style: TextStyle(fontSize: 10, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$player2Score puan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('❌ $player2Errors / $maxErrors', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
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
    bool isSelected = row == selectedRow && col == selectedCol;
    bool isOriginalCell = isOriginal[row][col];
    bool isWrong = board[row][col] != 0 && board[row][col] != solution[row][col] && !isOriginalCell;
    int value = board[row][col];
    Set<int> cellNotes = notes[row][col];

    double rightBorder = (col == 2 || col == 5) ? 2.0 : 0.5;
    double bottomBorder = (row == 2 || row == 5) ? 2.0 : 0.5;

    return GestureDetector(
      onTap: () => _selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? (isMyTurn ? Colors.green.shade100 : Colors.grey.shade200) : isWrong ? Colors.red.shade50 : Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade800, width: row == 0 ? 0 : 0.5),
            left: BorderSide(color: Colors.grey.shade800, width: col == 0 ? 0 : 0.5),
            right: BorderSide(color: (col == 2 || col == 5) ? Colors.black : Colors.grey.shade800, width: rightBorder),
            bottom: BorderSide(color: (row == 2 || row == 5) ? Colors.black : Colors.grey.shade800, width: bottomBorder),
          ),
        ),
        child: Center(
          child: value != 0
              ? Text('$value', style: TextStyle(fontSize: 24, fontWeight: isOriginalCell ? FontWeight.bold : FontWeight.normal, color: isOriginalCell ? Colors.black87 : isWrong ? Colors.red : Colors.blue.shade700))
              : cellNotes.isNotEmpty
              ? GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(2),
            children: List.generate(9, (i) => Center(child: Text(cellNotes.contains(i + 1) ? '${i + 1}' : '', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)))),
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
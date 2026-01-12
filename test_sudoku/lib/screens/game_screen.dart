import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:convert';
import '../app_localizations.dart';
import '../widgets/game_result_dialog.dart';
import '../services/progression_service.dart';
import '../services/user_status_service.dart';
import '../services/theme_service.dart';
import '../services/powerup_service.dart';
import 'settings_screen.dart';
import 'dart:async';

enum GameMode { single, multiplayer, race }

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final String difficulty;
  final bool continueGame;

  const GameScreen({
    super.key,
    required this.gameMode,
    this.difficulty = 'Orta',
    this.continueGame = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> isOriginal;
  late List<List<Set<int>>> notes;

  int? selectedRow;
  int? selectedCol;
  bool notesMode = false;
  int errors = 0;
  int maxErrors = 3;
  int hints = 3;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;

  int currentPlayer = 1;
  int player1Score = 0;
  int player2Score = 0;
  int player1Combo = 0;
  int player2Combo = 0;

  String player1Name = 'Oyuncu 1';
  String player2Name = 'Oyuncu 2';

  int seconds = 0;
  bool isPaused = false;
  bool timerEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Set<int> completedRows = {};
  Set<int> completedCols = {};
  Set<int> completedBoxes = {};

  // Animation: Track recently completed cells for pulse effect
  Set<int> _animatingCells = {}; // Linear cell indices (row * 9 + col)

  List<Map<String, dynamic>> moveHistory = [];
  bool _initialized = false;

  // Yanlış girilen hücreyi takip et
  int? _lastWrongRow;
  int? _lastWrongCol;

  // Game theme
  GameTheme? _gameTheme;

  // Power-ups
  bool _doubleScoreActive = false;
  bool _autoCheckActive = false;
  bool _timeFreezeActive = false;
  bool _timeFrozen = false;
  int _timeFreezeSecondsLeft = 0;
  Timer? _autoCheckTimer;
  Timer? _timeFreezeTimer;
  Set<int> _errorCells = {}; // Linear cell indices (row * 9 + col) for error highlighting

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPlayerNames();
    _loadTheme();
    _loadPowerUps();
    _initializeGame();

    // Set status to in_offline_game
    UserStatusService().updateStatus(UserStatus.inOfflineGame);
  }

  Future<void> _loadPowerUps() async {
    final powerUpService = PowerUpService();
    final doubleScore = await powerUpService.hasPowerUp(PowerUpType.doubleScore);
    final autoCheck = await powerUpService.hasPowerUp(PowerUpType.autoCheck);
    final timeFreeze = await powerUpService.hasPowerUp(PowerUpType.timeFreeze);

    setState(() {
      _doubleScoreActive = doubleScore;
      _autoCheckActive = autoCheck;
      _timeFreezeActive = timeFreeze && widget.gameMode == GameMode.race;
    });

    // Start auto-check timer if active
    if (_autoCheckActive) {
      _startAutoCheckTimer();
    }
  }

  void _startAutoCheckTimer() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || isPaused) return;
      _performAutoCheck();
    });
  }

  void _performAutoCheck() {
    final newErrorCells = <int>{};

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        // Skip original cells and empty cells
        if (isOriginal[row][col] || board[row][col] == 0) continue;

        // Check if the value is wrong
        if (board[row][col] != solution[row][col]) {
          newErrorCells.add(row * 9 + col);
        }
      }
    }

    if (newErrorCells.isNotEmpty && mounted) {
      setState(() {
        _errorCells = newErrorCells;
      });

      // Clear error highlights after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorCells.clear();
          });
        }
      });

      // Show notification
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔍 ${tr('autoCheckFound')} ${newErrorCells.length} ${tr('errors')}!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _activateTimeFreeze() {
    if (!_timeFreezeActive || _timeFrozen) return;

    setState(() {
      _timeFrozen = true;
      _timeFreezeSecondsLeft = 60; // 1 minute freeze
    });

    // Show notification
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❄️ ${tr('timeFrozen')} 60 ${tr('seconds')}!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Start countdown timer
    _timeFreezeTimer?.cancel();
    _timeFreezeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeFreezeSecondsLeft--;
      });

      if (_timeFreezeSecondsLeft <= 0) {
        timer.cancel();
        setState(() {
          _timeFrozen = false;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ ${tr('timeFreezeEnded')}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _loadTheme() async {
    final themeId = await ThemeService().getSelectedTheme();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setState(() {
      _gameTheme = GameTheme.getTheme(themeId, isDark);
    });
  }

  Future<void> _initializeGame() async {
    if (widget.continueGame && widget.gameMode == GameMode.single) {
      await _loadSavedGame();
    } else {
      _initGame();
    }
    _startTimer();
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    if (widget.gameMode == GameMode.single && _initialized && !_checkWin() && errors < maxErrors) {
      _saveGame();
    }

    // Cancel timers
    _autoCheckTimer?.cancel();
    _timeFreezeTimer?.cancel();

    // Set status back to idle
    UserStatusService().updateStatus(UserStatus.idle);

    super.dispose();
  }

  String _getLocalizedDifficulty(String key) {
    switch (key) {
      case 'Kolay': return tr('easy');
      case 'Orta': return tr('medium');
      case 'Zor': return tr('hard');
      case 'Uzman': return tr('expert');
      case 'Usta': return tr('master');
      case 'Ekstrem': return tr('extreme');
      default: return key;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      timerEnabled = prefs.getBool('timerEnabled') ?? true;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    });
  }

  Future<void> _loadPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    String nickname = prefs.getString('nickname') ?? '';

    if (nickname.isNotEmpty) {
      player1Name = nickname;
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      player1Name = user.displayName!;
    } else if (user?.email != null) {
      player1Name = user!.email!.split('@')[0];
    } else {
      player1Name = tr('you');
    }
    player2Name = tr('opponent');
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    final gameData = {
      'board': board.map((row) => row.toList()).toList(),
      'solution': solution.map((row) => row.toList()).toList(),
      'isOriginal': isOriginal.map((row) => row.toList()).toList(),
      'notes': notes.map((row) => row.map((cell) => cell.toList()).toList()).toList(),
      'errors': errors,
      'hints': hints,
      'score': score,
      'combo': combo,
      'maxCombo': maxCombo,
      'seconds': seconds,
      'difficulty': widget.difficulty,
      'completedRows': completedRows.toList(),
      'completedCols': completedCols.toList(),
      'completedBoxes': completedBoxes.toList(),
    };
    await prefs.setString('savedGame', jsonEncode(gameData));
    await prefs.setBool('hasSavedGame', true);
  }

  Future<void> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('savedGame');

    if (savedData != null) {
      try {
        final gameData = jsonDecode(savedData);
        board = (gameData['board'] as List).map((row) => (row as List).map((cell) => cell as int).toList()).toList();
        solution = (gameData['solution'] as List).map((row) => (row as List).map((cell) => cell as int).toList()).toList();
        isOriginal = (gameData['isOriginal'] as List).map((row) => (row as List).map((cell) => cell as bool).toList()).toList();
        notes = (gameData['notes'] as List).map((row) => (row as List).map((cell) => (cell as List).map((n) => n as int).toSet()).toList()).toList();
        errors = gameData['errors'];
        hints = gameData['hints'];
        score = gameData['score'];
        combo = gameData['combo'] ?? 0;
        maxCombo = gameData['maxCombo'] ?? 0;
        seconds = gameData['seconds'];
        completedRows = (gameData['completedRows'] as List?)?.map((e) => e as int).toSet() ?? {};
        completedCols = (gameData['completedCols'] as List?)?.map((e) => e as int).toSet() ?? {};
        completedBoxes = (gameData['completedBoxes'] as List?)?.map((e) => e as int).toSet() ?? {};
        return;
      } catch (e) {
        print('Error loading saved game: $e');
      }
    }
    _initGame();
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedGame');
    await prefs.setBool('hasSavedGame', false);
  }

  Future<void> _playClickSound() async {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _playCorrectSound() async {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _playWinSound() async {
    if (!soundEnabled) return;
    for (int i = 0; i < 3; i++) {
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _vibrate() async {
    if (!vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }

  Future<void> _vibrateHeavy() async {
    if (!vibrationEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (!isPaused && _initialized && !_timeFrozen) setState(() => seconds++);
      return true;
    });
  }

  int _getEmptyCells() {
    switch (widget.difficulty) {
      case 'Kolay': return 37;
      case 'Orta': return 48;
      case 'Zor': return 54;
      case 'Uzman': return 58;
      case 'Usta': return 61;
      case 'Ekstrem': return 64;
      default: return 48;
    }
  }

  void _initGame() {
    // Zorluk seviyesine göre max hata sayısını ayarla
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

    solution = List.generate(9, (_) => List.filled(9, 0));
    _generateSolution(0, 0);
    board = List.generate(9, (i) => List.from(solution[i]));
    isOriginal = List.generate(9, (_) => List.filled(9, true));
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));

    int cellsToRemove = _getEmptyCells();
    final random = Random();
    int removed = 0;
    while (removed < cellsToRemove) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);
      if (board[row][col] != 0) {
        board[row][col] = 0;
        isOriginal[row][col] = false;
        removed++;
      }
    }

    errors = 0; hints = 3; score = 0; combo = 0; maxCombo = 0; seconds = 0;
    currentPlayer = 1; player1Score = 0; player2Score = 0; player1Combo = 0; player2Combo = 0;
    moveHistory.clear(); completedRows.clear(); completedCols.clear(); completedBoxes.clear();
  }

  bool _generateSolution(int row, int col) {
    if (row == 9) return true;
    if (col == 9) return _generateSolution(row + 1, 0);
    List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
    for (int num in numbers) {
      if (_isValidPlacement(solution, row, col, num)) {
        solution[row][col] = num;
        if (_generateSolution(row, col + 1)) return true;
        solution[row][col] = 0;
      }
    }
    return false;
  }

  bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num || grid[i][col] == num) return false;
    }
    int boxRow = (row ~/ 3) * 3, boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[boxRow + i][boxCol + j] == num) return false;
      }
    }
    return true;
  }

  void _selectCell(int row, int col) {
    _playClickSound(); _vibrate();
    setState(() { selectedRow = row; selectedCol = col; });
  }

  bool _isRowComplete(int row) {
    for (int col = 0; col < 9; col++) if (board[row][col] != solution[row][col]) return false;
    return true;
  }

  bool _isColComplete(int col) {
    for (int row = 0; row < 9; row++) if (board[row][col] != solution[row][col]) return false;
    return true;
  }

  bool _isBoxComplete(int boxIndex) {
    int startRow = (boxIndex ~/ 3) * 3, startCol = (boxIndex % 3) * 3;
    for (int i = 0; i < 3; i++) for (int j = 0; j < 3; j++) if (board[startRow + i][startCol + j] != solution[startRow + i][startCol + j]) return false;
    return true;
  }

  void _checkCompletions(int row, int col) {
    int bonusPoints = 0;
    List<String> completedTypes = [];
    final newlyCompleted = <int>{};
    final tempCompletedRows = <int>{};
    final tempCompletedCols = <int>{};
    final tempCompletedBoxes = <int>{};

    // Check row completion
    if (!completedRows.contains(row) && _isRowComplete(row)) {
      tempCompletedRows.add(row);
      bonusPoints += 50;
      completedTypes.add(tr('rowCompleted'));
      // Add all cells in this row to animation set
      for (int c = 0; c < 9; c++) {
        newlyCompleted.add(row * 9 + c);
      }
    }

    // Check column completion
    if (!completedCols.contains(col) && _isColComplete(col)) {
      tempCompletedCols.add(col);
      bonusPoints += 50;
      completedTypes.add(tr('colCompleted'));
      // Add all cells in this column to animation set
      for (int r = 0; r < 9; r++) {
        newlyCompleted.add(r * 9 + col);
      }
    }

    // Check box completion
    int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
    if (!completedBoxes.contains(boxIndex) && _isBoxComplete(boxIndex)) {
      tempCompletedBoxes.add(boxIndex);
      bonusPoints += 50;
      completedTypes.add(tr('boxCompleted'));
      // Add all cells in this box to animation set
      int boxRow = (row ~/ 3) * 3;
      int boxCol = (col ~/ 3) * 3;
      for (int r = boxRow; r < boxRow + 3; r++) {
        for (int c = boxCol; c < boxCol + 3; c++) {
          newlyCompleted.add(r * 9 + c);
        }
      }
    }

    if (bonusPoints > 0) {
      score += _doubleScoreActive ? bonusPoints * 2 : bonusPoints;
      _vibrateHeavy();

      // Temporarily add to completed sets for animation
      setState(() {
        completedRows.addAll(tempCompletedRows);
        completedCols.addAll(tempCompletedCols);
        completedBoxes.addAll(tempCompletedBoxes);
        _animatingCells.addAll(newlyCompleted);
      });

      // Clear animation AND remove from completed sets after delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _animatingCells.removeAll(newlyCompleted);
            completedRows.removeAll(tempCompletedRows);
            completedCols.removeAll(tempCompletedCols);
            completedBoxes.removeAll(tempCompletedBoxes);
          });
        }
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ ${completedTypes.join(" + ")} ${tr('completed')} +$bonusPoints ${tr('bonus')}!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _inputNumber(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (isOriginal[selectedRow!][selectedCol!]) return;
    _playClickSound(); _vibrate();

    int row = selectedRow!, col = selectedCol!;

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
        if (notes[row][col].contains(number)) notes[row][col].remove(number);
        else notes[row][col].add(number);
        board[row][col] = 0;
      });
    } else {
      moveHistory.add({'row': row, 'col': col, 'oldValue': board[row][col], 'newValue': number});
      bool isCorrect = number == solution[row][col];

      setState(() {
        board[row][col] = number;
        notes[row][col].clear();

        if (isCorrect) {
          _playCorrectSound(); combo++;
          if (combo > maxCombo) maxCombo = combo;
          if (widget.gameMode == GameMode.multiplayer) {
            final comboScore = 10;
            if (currentPlayer == 1) {
              player1Combo++;
              player1Score += _doubleScoreActive ? comboScore * player1Combo * 2 : comboScore * player1Combo;
            } else {
              player2Combo++;
              player2Score += _doubleScoreActive ? comboScore * player2Combo * 2 : comboScore * player2Combo;
            }
          } else {
            score += _doubleScoreActive ? (10 * combo * 2) : (10 * combo);
          }
        } else {
          _vibrateHeavy(); errors++; combo = 0;
          // Yanlış hücreyi kaydet
          _lastWrongRow = row;
          _lastWrongCol = col;
          if (widget.gameMode == GameMode.multiplayer) {
            if (currentPlayer == 1) { player1Combo = 0; currentPlayer = 2; }
            else { player2Combo = 0; currentPlayer = 1; }
          }
        }
      });

      if (isCorrect && combo >= 3 && widget.gameMode == GameMode.single) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔥 ${combo}x ${tr('combo')}! +${10 * combo} ${tr('points')}!'), duration: const Duration(milliseconds: 800), backgroundColor: Colors.orange));
      }

      if (isCorrect) {
        _checkCompletions(row, col);
        if (_checkWin()) { _playWinSound(); _clearSavedGame(); _saveStats(won: true); _showWinDialog(); }
      } else if (errors >= maxErrors) { _clearSavedGame(); _saveStats(won: false); _showGameOverDialog(); }
    }
  }

  Future<void> _saveStats({required bool won}) async {
    final prefs = await SharedPreferences.getInstance();
    int totalGames = prefs.getInt('totalGames') ?? 0;
    int gamesWon = prefs.getInt('gamesWon') ?? 0;
    int gamesLost = prefs.getInt('gamesLost') ?? 0;
    await prefs.setInt('totalGames', totalGames + 1);

    if (won) {
      await prefs.setInt('gamesWon', gamesWon + 1);
      if (errors == 0) { int perfectWins = prefs.getInt('perfectWins') ?? 0; await prefs.setInt('perfectWins', perfectWins + 1); }
      String bestTimeKey = 'bestTime${widget.difficulty}';
      int bestTime = prefs.getInt(bestTimeKey) ?? 0;
      if (bestTime == 0 || seconds < bestTime) await prefs.setInt(bestTimeKey, seconds);
      String bestScoreKey = 'bestScore${widget.difficulty}';
      int bestScore = prefs.getInt(bestScoreKey) ?? 0;
      if (score > bestScore) await prefs.setInt(bestScoreKey, score);

      // Progression system - zorluk seviyesi kazanma sayısını artır
      await ProgressionService.incrementWins(widget.difficulty);
    } else {
      await prefs.setInt('gamesLost', gamesLost + 1);
    }
  }

  void _undo() {
    if (moveHistory.isEmpty) return;
    _playClickSound(); _vibrate();
    setState(() { var lastMove = moveHistory.removeLast(); board[lastMove['row']][lastMove['col']] = lastMove['oldValue']; });
  }

  void _clearCell() {
    if (selectedRow == null || selectedCol == null) return;
    if (isOriginal[selectedRow!][selectedCol!]) return;
    _playClickSound(); _vibrate();
    setState(() { board[selectedRow!][selectedCol!] = 0; notes[selectedRow!][selectedCol!].clear(); });
  }

  void _useHint() {
    if (hints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('noHintsLeft')), backgroundColor: Colors.red),
      );
      return;
    }

    _playClickSound();
    _vibrate();

    // Find first empty cell and fill with correct answer
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          setState(() {
            board[row][col] = solution[row][col];
            hints--;
            combo = 0;
            selectedRow = row;
            selectedCol = col;
          });

          _checkCompletions(row, col);
          if (_checkWin()) {
            _playWinSound();
            _clearSavedGame();
            _saveStats(won: true);
            _showWinDialog();
          }
          return;
        }
      }
    }

    // No empty cells found
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('noHintAvailable')), backgroundColor: Colors.orange),
    );
  }

  bool _checkWin() {
    for (int i = 0; i < 9; i++) for (int j = 0; j < 9; j++) if (board[i][j] != solution[i][j]) return false;
    return true;
  }

  void _showWinDialog() {
    if (widget.gameMode == GameMode.multiplayer) {
      showMultiplayerResultDialog(
        context,
        player1Score: player1Score,
        player2Score: player2Score,
        player1Name: player1Name,
        player2Name: player2Name,
        time: seconds,
        onNewGame: () { Navigator.pop(context); setState(() => _initGame()); },
        onMainMenu: () { Navigator.pop(context); Navigator.pop(context); },
      );
    } else {
      showWinDialog(
        context,
        score: score,
        time: seconds,
        errors: errors,
        maxErrors: maxErrors,
        combo: maxCombo,
        isPerfect: errors == 0,
        onNewGame: () { Navigator.pop(context); setState(() => _initGame()); },
        onMainMenu: () { Navigator.pop(context); Navigator.pop(context); },
      );
    }
  }

  void _showGameOverDialog() {
    showLoseDialog(
      context,
      score: score,
      time: seconds,
      errors: errors,
      maxErrors: maxErrors,
      onNewGame: () { Navigator.pop(context); setState(() => _initGame()); },
      onMainMenu: () { Navigator.pop(context); Navigator.pop(context); },
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60, secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        _buildInfoBar(),
        if (_doubleScoreActive || _autoCheckActive) _buildPowerUpIndicators(),
        if (widget.gameMode == GameMode.multiplayer) _buildMultiplayerScore(),
        if (widget.gameMode == GameMode.single && combo >= 2)
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6), color: Colors.orange.withOpacity(0.2),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🔥 ', style: TextStyle(fontSize: 18)),
                Text('${combo}x ${tr('combo')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                Text('  (${tr('nextPoints')}: +${10 * (combo + 1)} ${tr('points')})', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
              ])),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: _buildSudokuGrid())),
        _buildActionButtons(),
        _buildNumberButtons(),
        const SizedBox(height: 12),
      ])),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(children: [
        // Back button
        IconButton(
          icon: Icon(Icons.arrow_back, size: 24, color: isDark ? Colors.white : Colors.grey[800]),
          onPressed: () {
            if (widget.gameMode == GameMode.single) _saveGame();
            Navigator.pop(context);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        // Score display
        Text(
          widget.gameMode == GameMode.single ? '$score' : '$player1Score',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey[900],
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        // Settings button (top-right)
        IconButton(
          icon: Icon(Icons.settings_outlined, size: 24, color: isDark ? Colors.white : Colors.grey[800]),
          onPressed: () {
            _showGameSettings();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  // Navigate to main settings screen
  void _showGameSettings() async {
    // Pause game when going to settings
    if (!isPaused) {
      setState(() => isPaused = true);
    }

    // Navigate to settings screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Widget _buildInfoBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // All Levels: Always show these 4 stats
          _buildModernInfoItem(
            label: widget.gameMode == GameMode.single ? tr('score') : tr('score'),
            value: widget.gameMode == GameMode.single ? '$score' : '$player1Score',
            icon: Icons.star_rounded,
            color: Colors.amber[700]!,
          ),
          _buildModernInfoItem(
            label: tr('difficulty'),
            value: _getShortDifficulty(widget.difficulty),
            icon: Icons.speed_rounded,
            color: Colors.blue[600]!,
          ),
          _buildModernInfoItem(
            label: tr('errors'),
            value: '$errors/$maxErrors',
            icon: Icons.warning_rounded,
            color: errors >= maxErrors - 1 ? Colors.red[600]! : Colors.orange[600]!,
          ),
          if (timerEnabled)
            _buildModernInfoItem(
              label: tr('time'),
              value: _formatTime(seconds),
              icon: Icons.timer_outlined,
              color: Colors.teal[600]!,
            ),
          // Pause button
          InkWell(
            onTap: () {
              _playClickSound();
              setState(() => isPaused = !isPaused);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 26,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpIndicators() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.purple.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_doubleScoreActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on, color: Colors.purple, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '2x ${tr('score')}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_autoCheckActive) const SizedBox(width: 12),
          ],
          if (_autoCheckActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    tr('autoCheck'),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInfoItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _getShortDifficulty(String difficulty) {
    // Return full difficulty name instead of truncated version
    return difficulty;
  }

  Widget _buildMultiplayerScore() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Row(children: [
      Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: currentPlayer == 1 ? Colors.blue.shade100 : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: currentPlayer == 1 ? Colors.blue : Colors.grey.shade300, width: currentPlayer == 1 ? 2 : 1)),
          child: Column(children: [Text(player1Name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentPlayer == 1 ? Colors.blue.shade700 : Colors.black87), overflow: TextOverflow.ellipsis), Text('$player1Score ${tr('points')}', style: const TextStyle(fontSize: 12)), if (player1Combo > 1) Text('🔥 x$player1Combo', style: const TextStyle(fontSize: 11))]))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('⚔️', style: TextStyle(fontSize: 20))),
      Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: currentPlayer == 2 ? Colors.red.shade100 : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: currentPlayer == 2 ? Colors.red : Colors.grey.shade300, width: currentPlayer == 2 ? 2 : 1)),
          child: Column(children: [Text(player2Name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentPlayer == 2 ? Colors.red.shade700 : Colors.black87), overflow: TextOverflow.ellipsis), Text('$player2Score ${tr('points')}', style: const TextStyle(fontSize: 12)), if (player2Combo > 1) Text('🔥 x$player2Combo', style: const TextStyle(fontSize: 11))]))),
    ]));
  }

  Widget _buildSudokuGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade800,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(10),
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

    // Use theme colors, fallback to default if not loaded yet
    final theme = _gameTheme ?? GameTheme.getTheme('default', isDark);

    bool isSelected = row == selectedRow && col == selectedCol;
    bool isOriginalCell = isOriginal[row][col];
    bool isWrong = board[row][col] != 0 && board[row][col] != solution[row][col] && !isOriginalCell;
    int value = board[row][col];
    Set<int> cellNotes = notes[row][col];

    int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
    bool isInCompletedGroup = completedRows.contains(row) || completedCols.contains(col) || completedBoxes.contains(boxIndex);
    bool isSameRow = selectedRow != null && row == selectedRow;
    bool isSameCol = selectedCol != null && col == selectedCol;
    bool isSameBox = selectedRow != null && selectedCol != null && (row ~/ 3 == selectedRow! ~/ 3) && (col ~/ 3 == selectedCol! ~/ 3);
    bool isHighlighted = (isSameRow || isSameCol || isSameBox) && !isSelected;
    bool isSameNumber = selectedRow != null && selectedCol != null && board[selectedRow!][selectedCol!] != 0 && board[row][col] == board[selectedRow!][selectedCol!] && !isSelected;

    // Check if this cell is currently animating
    final cellIndex = row * 9 + col;
    final isAnimating = _animatingCells.contains(cellIndex);

    // Check if auto-check detected an error in this cell
    final isAutoCheckError = _errorCells.contains(cellIndex);

    // Border widths for 3x3 blocks
    double rightBorder = (col == 2 || col == 5) ? 2.5 : 0.8;
    double bottomBorder = (row == 2 || row == 5) ? 2.5 : 0.8;

    // Use cleaner colors inspired by reference
    Color bgColor;
    if (isSelected) {
      bgColor = const Color(0xFFBBDEFB); // Light blue selection
    } else if (isAutoCheckError) {
      // Auto-check detected error - show orange highlight
      bgColor = Colors.orange.withOpacity(0.5);
    } else if (isWrong) {
      bgColor = const Color(0xFFFFCDD2); // Light red for errors
    } else if (isInCompletedGroup) {
      bgColor = theme.completedCell;
    } else if (isSameNumber) {
      bgColor = const Color(0xFFE3F2FD); // Very light blue
    } else if (isHighlighted) {
      bgColor = const Color(0xFFF5F5F5); // Very light grey
    } else {
      bgColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    }

    Color textColor;
    if (isOriginalCell) {
      textColor = isDark ? Colors.white : Colors.black87;
    } else if (isWrong) {
      textColor = const Color(0xFFD32F2F); // Red text for errors
    } else {
      textColor = isDark ? Colors.white70 : const Color(0xFF1976D2); // Blue text for user entries
    }

    // Wrap in AnimatedScale for completion animation
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
          border: Border(
            top: BorderSide(
              color: row == 0 ? Colors.transparent : theme.gridLineColor,
              width: 0,
            ),
            left: BorderSide(
              color: col == 0 ? Colors.transparent : theme.gridLineColor,
              width: 0,
            ),
            right: BorderSide(
              color: (col == 2 || col == 5)
                ? theme.thickGridLineColor
                : theme.gridLineColor,
              width: rightBorder,
            ),
            bottom: BorderSide(
              color: (row == 2 || row == 5)
                ? theme.thickGridLineColor
                : theme.gridLineColor,
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
                    color: textColor,
                  ),
                )
              : cellNotes.isNotEmpty
                  ? GridView.count(
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(2),
                      physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttons = <Widget>[
      _buildActionButton(Icons.undo_rounded, tr('undo'), _undo, isDark),
      _buildActionButton(Icons.backspace_outlined, tr('delete'), _clearCell, isDark),
      _buildActionButton(notesMode ? Icons.edit : Icons.edit_outlined, AppLocalizations.currentLanguage == 'en' ? 'Notes' : 'Notlar', () { _playClickSound(); _vibrate(); setState(() => notesMode = !notesMode); }, isDark, isActive: notesMode, badge: notesMode ? 'ON' : 'OFF'),
      _buildActionButton(Icons.lightbulb_outline_rounded, tr('hint'), _useHint, isDark, badge: '$hints'),
    ];

    // Add time freeze button for race mode
    if (_timeFreezeActive && widget.gameMode == GameMode.race) {
      buttons.add(
        _buildActionButton(
          Icons.ac_unit,
          tr('freeze'),
          _timeFrozen ? () {} : _activateTimeFreeze,
          isDark,
          isActive: _timeFrozen,
          badge: _timeFrozen ? '${_timeFreezeSecondsLeft}s' : null,
        ),
      );
    }

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons));
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, bool isDark, {bool isActive = false, String? badge}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(children: [
      Stack(clipBehavior: Clip.none, children: [
        Icon(icon, color: isActive ? Colors.blue : (isDark ? Colors.grey.shade300 : Colors.grey.shade700), size: 26),
        if (badge != null) Positioned(right: -8, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: isActive ? Colors.blue : Colors.grey.shade500, borderRadius: BorderRadius.circular(8)), child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.blue : (isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
    ])));
  }

  Widget _buildNumberButtons() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(9, (i) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: AspectRatio(aspectRatio: 0.75, child: Material(color: Colors.transparent, child: InkWell(onTap: () => _inputNumber(i + 1), borderRadius: BorderRadius.circular(8), child: Container(decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))))))))))));
  }
}
import 'package:flutter/material.dart';
import '../app_localizations.dart';

/// Post-game statistics dialog shown after online game completion
/// Shows detailed stats: winner, time, moves, accuracy, and quick rematch option
class PostGameStatsDialog extends StatelessWidget {
  final bool isWinner;
  final bool isDraw;
  final String opponentNickname;
  final int myTime; // seconds
  final int opponentTime; // seconds
  final int myMoves;
  final int opponentMoves;
  final int myErrors;
  final int opponentErrors;
  final String gameMode; // 'classic' or 'race'
  final String difficulty;
  final VoidCallback? onRematch;
  final VoidCallback? onClose;

  const PostGameStatsDialog({
    super.key,
    required this.isWinner,
    this.isDraw = false,
    required this.opponentNickname,
    required this.myTime,
    required this.opponentTime,
    required this.myMoves,
    required this.opponentMoves,
    required this.myErrors,
    required this.opponentErrors,
    required this.gameMode,
    required this.difficulty,
    this.onRematch,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate accuracy (percentage of correct moves)
    final myAccuracy = myMoves > 0 ? ((myMoves - myErrors) / myMoves * 100).toInt() : 0;
    final opponentAccuracy = opponentMoves > 0 ? ((opponentMoves - opponentErrors) / opponentMoves * 100).toInt() : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDraw
                ? [const Color(0xFF607D8B), const Color(0xFF455A64)]
                : isWinner
                    ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
                    : [const Color(0xFFE91E63), const Color(0xFFC2185B)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Stats content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opponent info
                  _buildOpponentBanner(isDark),
                  const SizedBox(height: 20),

                  // Stats comparison
                  _buildStatRow('⏱️ Süre', _formatTime(myTime), _formatTime(opponentTime), myTime < opponentTime, isDark),
                  const SizedBox(height: 12),
                  _buildStatRow('🎯 Hamle', '$myMoves', '$opponentMoves', myMoves < opponentMoves, isDark),
                  const SizedBox(height: 12),
                  _buildStatRow('✨ İsabet', '$myAccuracy%', '$opponentAccuracy%', myAccuracy > opponentAccuracy, isDark),
                  const SizedBox(height: 12),
                  _buildStatRow('❌ Hata', '$myErrors', '$opponentErrors', myErrors < opponentErrors, isDark),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      // Close button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onClose?.call();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Kapat',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Rematch button
                      if (onRematch != null)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRematch?.call();
                            },
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            label: const Text(
                              'Revanche! 🔥',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Result icon
          Text(
            isDraw ? '🤝' : isWinner ? '🏆' : '💔',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),

          // Result text
          Text(
            isDraw
                ? 'Berabere!'
                : isWinner
                    ? 'Kazandın!'
                    : 'Kaybettin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Game mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${gameMode == 'race' ? '🏁 Race' : '⚔️ Classic'} • $difficulty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D2D), const Color(0xFF1E1E1E)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Opponent avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                opponentNickname.isNotEmpty ? opponentNickname[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Opponent info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponentNickname,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rakip',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // VS badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String myValue, String opponentValue, bool iAmBetter, bool isDark) {
    return Row(
      children: [
        // Label
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),

        // My value
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: iAmBetter
                  ? Colors.green.withOpacity(0.15)
                  : isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iAmBetter ? Colors.green : Colors.transparent,
                width: iAmBetter ? 2 : 0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iAmBetter)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 14),
                  ),
                Flexible(
                  child: Text(
                    myValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: iAmBetter
                          ? Colors.green.shade700
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Opponent value
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: !iAmBetter
                  ? Colors.orange.withOpacity(0.15)
                  : isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !iAmBetter ? Colors.orange : Colors.transparent,
                width: !iAmBetter ? 2 : 0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!iAmBetter)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle, color: Colors.orange, size: 14),
                  ),
                Flexible(
                  child: Text(
                    opponentValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !iAmBetter
                          ? Colors.orange.shade700
                          : (isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}

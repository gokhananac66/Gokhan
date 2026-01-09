import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for tracking recent players you've played with
/// Stores last 10 players with game results for easy re-invites
class RecentPlayersService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int maxRecentPlayers = 10;

  /// Add a player to recent players list after a game
  Future<void> addRecentPlayer({
    required String opponentUid,
    required String opponentNickname,
    required String gameResult, // 'win', 'loss', 'draw'
    required String gameMode, // 'classic', 'race'
    required String difficulty,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [RecentPlayersService] No current user');
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final playerData = {
        'uid': opponentUid,
        'nickname': opponentNickname,
        'gameResult': gameResult,
        'gameMode': gameMode,
        'difficulty': difficulty,
        'timestamp': timestamp,
      };

      print('📝 [RecentPlayersService] Adding recent player:');
      print('   User: ${currentUser.uid}');
      print('   Opponent: $opponentNickname ($opponentUid)');
      print('   Result: $gameResult');
      print('   Path: users/${currentUser.uid}/recent_players/$opponentUid');

      // Add to recent players list
      await _database
          .child('users/${currentUser.uid}/recent_players/$opponentUid')
          .set(playerData);

      print('✅ [RecentPlayersService] Recent player added successfully');

      // Clean up if more than maxRecentPlayers
      await _cleanupOldPlayers(currentUser.uid);
    } catch (e) {
      print('❌ [RecentPlayersService] Error adding recent player: $e');
    }
  }

  /// Get list of recent players (last 10)
  Future<List<RecentPlayer>> getRecentPlayers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ [RecentPlayersService] No current user (getRecentPlayers)');
      return [];
    }

    try {
      print('🔍 [RecentPlayersService] Fetching recent players for: ${currentUser.uid}');

      final snapshot = await _database
          .child('users/${currentUser.uid}/recent_players')
          .orderByChild('timestamp')
          .limitToLast(maxRecentPlayers)
          .get();

      if (!snapshot.exists) {
        print('⚠️ [RecentPlayersService] No recent players found in Firebase');
        return [];
      }

      final List<RecentPlayer> players = [];
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      print('📦 [RecentPlayersService] Raw data keys: ${data.keys.toList()}');

      data.forEach((key, value) {
        final playerMap = Map<String, dynamic>.from(value);
        final player = RecentPlayer.fromMap(playerMap);
        players.add(player);
        print('   - ${player.nickname}: ${player.gameResult}');
      });

      // Sort by timestamp descending (most recent first)
      players.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ [RecentPlayersService] Found ${players.length} recent players');
      return players;
    } catch (e) {
      print('❌ [RecentPlayersService] Error getting recent players: $e');
      return [];
    }
  }

  /// Clean up old players if more than maxRecentPlayers
  Future<void> _cleanupOldPlayers(String uid) async {
    try {
      final snapshot = await _database
          .child('users/$uid/recent_players')
          .orderByChild('timestamp')
          .get();

      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<MapEntry<String, dynamic>> entries = data.entries.toList();

      // Sort by timestamp
      entries.sort((a, b) {
        final aTime = a.value['timestamp'] as int;
        final bTime = b.value['timestamp'] as int;
        return aTime.compareTo(bTime);
      });

      // Remove oldest entries if more than max
      if (entries.length > maxRecentPlayers) {
        final toRemove = entries.length - maxRecentPlayers;
        for (int i = 0; i < toRemove; i++) {
          await _database
              .child('users/$uid/recent_players/${entries[i].key}')
              .remove();
        }
      }
    } catch (e) {
      print('❌ [RecentPlayersService] Error cleaning up old players: $e');
    }
  }

  /// Check if a user is in recent players
  Future<bool> isRecentPlayer(String opponentUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final snapshot = await _database
          .child('users/${currentUser.uid}/recent_players/$opponentUid')
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Remove a player from recent list
  Future<void> removeRecentPlayer(String opponentUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _database
          .child('users/${currentUser.uid}/recent_players/$opponentUid')
          .remove();
    } catch (e) {
      print('❌ [RecentPlayersService] Error removing recent player: $e');
    }
  }
}

/// Model for recent player data
class RecentPlayer {
  final String uid;
  final String nickname;
  final String gameResult; // 'win', 'loss', 'draw'
  final String gameMode;
  final String difficulty;
  final int timestamp;

  RecentPlayer({
    required this.uid,
    required this.nickname,
    required this.gameResult,
    required this.gameMode,
    required this.difficulty,
    required this.timestamp,
  });

  factory RecentPlayer.fromMap(Map<String, dynamic> map) {
    return RecentPlayer(
      uid: map['uid'] ?? '',
      nickname: map['nickname'] ?? 'Unknown',
      gameResult: map['gameResult'] ?? 'draw',
      gameMode: map['gameMode'] ?? 'classic',
      difficulty: map['difficulty'] ?? 'easy',
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'gameResult': gameResult,
      'gameMode': gameMode,
      'difficulty': difficulty,
      'timestamp': timestamp,
    };
  }

  /// Get relative time string (e.g., "2 saat önce")
  String getRelativeTime(String locale) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final minutes = diff ~/ 60000;
    final hours = diff ~/ 3600000;
    final days = diff ~/ 86400000;

    if (locale == 'tr') {
      if (minutes < 1) return 'Şimdi';
      if (minutes < 60) return '$minutes dk önce';
      if (hours < 24) return '$hours sa önce';
      if (days < 7) return '$days gün önce';
      return '${days ~/ 7} hafta önce';
    } else {
      if (minutes < 1) return 'Now';
      if (minutes < 60) return '$minutes min ago';
      if (hours < 24) return '$hours hr ago';
      if (days < 7) return '$days days ago';
      return '${days ~/ 7} weeks ago';
    }
  }

  /// Get result icon
  String getResultIcon() {
    switch (gameResult) {
      case 'win':
        return '🏆';
      case 'loss':
        return '💔';
      default:
        return '🤝';
    }
  }

  /// Get result color
  static getResultColor(String result) {
    switch (result) {
      case 'win':
        return const Color(0xFF4CAF50); // Green
      case 'loss':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Gray
    }
  }
}

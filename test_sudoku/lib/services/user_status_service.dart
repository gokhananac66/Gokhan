import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcı durumu
enum UserStatus {
  idle, // Ana menüde, profile'de vs.
  inOfflineGame, // Tek başına oynuyor
  inOnlineGame, // Multiplayer oyunda (DAVET ATMA!)
}

/// Kullanıcı durumu takip servisi
class UserStatusService {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  /// Durumu güncelle
  Future<void> updateStatus(UserStatus status) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final statusString = _statusToString(status);
      await _ref.child('users/$uid/status').set({
        'status': statusString,
        'lastUpdated': ServerValue.timestamp,
      });
      print('✅ Status updated: $statusString');
    } catch (e) {
      print('❌ Error updating status: $e');
    }
  }

  /// Kullanıcının durumunu getir
  Future<UserStatus> getUserStatus(String uid) async {
    try {
      final snapshot = await _ref.child('users/$uid/status/status').get();
      if (snapshot.exists) {
        final statusString = snapshot.value as String;
        return _stringToStatus(statusString);
      }
      return UserStatus.idle;
    } catch (e) {
      print('❌ Error getting user status: $e');
      return UserStatus.idle;
    }
  }

  /// Kullanıcının durumunu stream olarak dinle
  Stream<UserStatus> watchUserStatus(String uid) {
    return _ref.child('users/$uid/status/status').onValue.map((event) {
      if (event.snapshot.exists) {
        final statusString = event.snapshot.value as String;
        return _stringToStatus(statusString);
      }
      return UserStatus.idle;
    });
  }

  /// Kullanıcı online oyunda mı?
  Future<bool> isUserInOnlineGame(String uid) async {
    final status = await getUserStatus(uid);
    return status == UserStatus.inOnlineGame;
  }

  /// Kullanıcıya davet gönderilebilir mi?
  Future<bool> canSendInvite(String uid) async {
    final status = await getUserStatus(uid);
    // Online oyunda değilse davet gönderilebilir
    return status != UserStatus.inOnlineGame;
  }

  /// Offline olarak işaretle (logout, app close)
  Future<void> setOffline() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _ref.child('users/$uid/status').remove();
      print('✅ User set to offline');
    } catch (e) {
      print('❌ Error setting offline: $e');
    }
  }

  /// Enum to String
  String _statusToString(UserStatus status) {
    switch (status) {
      case UserStatus.idle:
        return 'idle';
      case UserStatus.inOfflineGame:
        return 'in_offline_game';
      case UserStatus.inOnlineGame:
        return 'in_online_game';
    }
  }

  /// String to Enum
  UserStatus _stringToStatus(String status) {
    switch (status) {
      case 'idle':
        return UserStatus.idle;
      case 'in_offline_game':
        return UserStatus.inOfflineGame;
      case 'in_online_game':
        return UserStatus.inOnlineGame;
      default:
        return UserStatus.idle;
    }
  }
}

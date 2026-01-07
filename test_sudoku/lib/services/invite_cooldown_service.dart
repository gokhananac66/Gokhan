import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Davet red etme cooldown servisi
/// 2 kez red = 1 dakika cooldown
class InviteCooldownService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  static const int cooldownDurationSeconds = 60; // 1 minute
  static const int maxRejectionsBeforeCooldown = 2;

  /// Davet reddetme sayısını kaydet
  Future<void> recordRejection(String fromUid, String toUid) async {
    try {
      final blockKey = '${fromUid}_$toUid';
      final now = DateTime.now().millisecondsSinceEpoch;

      final snapshot = await _ref.child('invite_blocks/$blockKey').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final rejectionCount = (data['rejectionCount'] as int? ?? 0) + 1;
        final lastRejectionTime = data['lastRejectionTime'] as int?;

        // Eğer son red 5 dakikadan eskiyse, sayacı sıfırla
        if (lastRejectionTime != null) {
          final timeDiff = now - lastRejectionTime;
          if (timeDiff > 300000) {
            // 5 dakika
            await _ref.child('invite_blocks/$blockKey').set({
              'rejectionCount': 1,
              'lastRejectionTime': now,
              'blockedUntil': null,
            });
            return;
          }
        }

        // 2. red ise cooldown başlat
        if (rejectionCount >= maxRejectionsBeforeCooldown) {
          final blockedUntil = now + (cooldownDurationSeconds * 1000);
          await _ref.child('invite_blocks/$blockKey').set({
            'rejectionCount': rejectionCount,
            'lastRejectionTime': now,
            'blockedUntil': blockedUntil,
            'fromUid': fromUid,
            'toUid': toUid,
          });
        } else {
          await _ref.child('invite_blocks/$blockKey').update({
            'rejectionCount': rejectionCount,
            'lastRejectionTime': now,
          });
        }
      } else {
        // İlk red
        await _ref.child('invite_blocks/$blockKey').set({
          'rejectionCount': 1,
          'lastRejectionTime': now,
          'blockedUntil': null,
          'fromUid': fromUid,
          'toUid': toUid,
        });
      }
    } catch (e) {
      print('Error recording rejection: $e');
    }
  }

  /// Kullanıcının davet gönderme izni var mı kontrol et
  Future<bool> canSendInvite(String fromUid, String toUid) async {
    try {
      final blockKey = '${fromUid}_$toUid';
      final snapshot = await _ref.child('invite_blocks/$blockKey').get();

      if (!snapshot.exists) return true;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final blockedUntil = data['blockedUntil'] as int?;

      if (blockedUntil == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < blockedUntil) {
        // Hala cooldown süresi içinde
        return false;
      } else {
        // Cooldown süresi bitti, temizle
        await _ref.child('invite_blocks/$blockKey').remove();
        return true;
      }
    } catch (e) {
      print('Error checking invite permission: $e');
      return true; // Hata durumunda izin ver
    }
  }

  /// Kalan cooldown süresini saniye cinsinden döndür
  Future<int> getRemainingCooldownSeconds(String fromUid, String toUid) async {
    try {
      final blockKey = '${fromUid}_$toUid';
      final snapshot = await _ref.child('invite_blocks/$blockKey').get();

      if (!snapshot.exists) return 0;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final blockedUntil = data['blockedUntil'] as int?;

      if (blockedUntil == null) return 0;

      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = blockedUntil - now;

      return remaining > 0 ? (remaining / 1000).ceil() : 0;
    } catch (e) {
      print('Error getting remaining cooldown: $e');
      return 0;
    }
  }

  /// Red sayısını al
  Future<int> getRejectionCount(String fromUid, String toUid) async {
    try {
      final blockKey = '${fromUid}_$toUid';
      final snapshot = await _ref.child('invite_blocks/$blockKey').get();

      if (!snapshot.exists) return 0;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data['rejectionCount'] as int? ?? 0;
    } catch (e) {
      print('Error getting rejection count: $e');
      return 0;
    }
  }
}

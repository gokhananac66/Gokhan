import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arkadaş verisi modeli
class FriendData {
  final String uid;
  final String nickname;
  final int level;
  final bool online;
  final DateTime? lastSeen;

  FriendData({
    required this.uid,
    required this.nickname,
    required this.level,
    required this.online,
    this.lastSeen,
  });

  String get lastSeenText {
    if (online) return 'Çevrimiçi';
    if (lastSeen == null) return 'Çevrimdışı';

    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}

/// Arkadaşlık isteği modeli
class FriendRequest {
  final String uid;
  final String nickname;
  final DateTime createdAt;

  FriendRequest({
    required this.uid,
    required this.nickname,
    required this.createdAt,
  });
}

/// İşlem sonucu
class FriendResult {
  final bool success;
  final String message;

  FriendResult({required this.success, required this.message});
}

/// Arkadaşlık servisi
class FriendService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference get _ref => _database.ref();
  String? get currentUserId => _auth.currentUser?.uid;

  Timer? _presenceTimer;

  /// Nickname'i UID'den al
  Future<String> getNicknameByUid(String uid) async {
    try {
      print('🔍 Getting nickname for UID: $uid');

      // 1. users/{uid}/nickname'e bak
      final userSnapshot = await _ref.child('users/$uid/nickname').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        final nickname = userSnapshot.value.toString();
        if (nickname.isNotEmpty && nickname != 'null') {
          print('✅ Found nickname in users/$uid/nickname: $nickname');
          return nickname;
        }
      }

      // 2. Kendi UID'miz ise SharedPreferences'tan al
      if (uid == currentUserId) {
        final prefs = await SharedPreferences.getInstance();
        final savedNickname = prefs.getString('nickname');
        if (savedNickname != null && savedNickname.isNotEmpty) {
          print('✅ Found nickname in SharedPreferences: $savedNickname');
          // Firebase'e de kaydet (senkronizasyon)
          await _ref.child('users/$uid').update({
            'nickname': savedNickname,
            'nicknameLower': savedNickname.toLowerCase(),
          });
          await _ref.child('nicknames/${savedNickname.toLowerCase()}').set(uid);
          return savedNickname;
        }
      }

      // 3. nicknames tablosunda ters arama yap
      final nicknamesSnapshot = await _ref.child('nicknames').get();
      if (nicknamesSnapshot.exists && nicknamesSnapshot.value != null) {
        final nicknames = Map<String, dynamic>.from(nicknamesSnapshot.value as Map);
        for (var entry in nicknames.entries) {
          if (entry.value.toString() == uid) {
            print('✅ Found nickname in nicknames table: ${entry.key}');
            return entry.key;
          }
        }
      }

      print('⚠️ No nickname found for $uid, returning Player');
      return 'Player';
    } catch (e) {
      print('❌ Error getting nickname for $uid: $e');
      return 'Player';
    }
  }

  /// UID'yi nickname'den al - TÜM YOLLARI DENE
  Future<String?> getUidByNickname(String nickname) async {
    try {
      final searchNickname = nickname.trim();
      if (searchNickname.isEmpty) return null;

      final lowerNickname = searchNickname.toLowerCase();
      print('🔍 Searching for nickname: "$searchNickname" (lower: "$lowerNickname")');

      // YÖNTEM 1: nicknames/{nickname} -> uid (lowercase)
      try {
        final snap1 = await _ref.child('nicknames/$lowerNickname').get();
        print('📍 nicknames/$lowerNickname exists: ${snap1.exists}, value: ${snap1.value}');
        if (snap1.exists && snap1.value != null) {
          return snap1.value.toString();
        }
      } catch (e) {
        print('❌ Error checking nicknames/$lowerNickname: $e');
      }

      // YÖNTEM 2: nicknames/{nickname} -> uid (exact case)
      try {
        final snap2 = await _ref.child('nicknames/$searchNickname').get();
        print('📍 nicknames/$searchNickname exists: ${snap2.exists}, value: ${snap2.value}');
        if (snap2.exists && snap2.value != null) {
          return snap2.value.toString();
        }
      } catch (e) {
        print('❌ Error checking nicknames/$searchNickname: $e');
      }

      // YÖNTEM 3: Tüm nicknames tablosunu tara
      try {
        final allNicknamesSnapshot = await _ref.child('nicknames').get();
        print('📍 nicknames table exists: ${allNicknamesSnapshot.exists}');

        if (allNicknamesSnapshot.exists && allNicknamesSnapshot.value != null) {
          final data = allNicknamesSnapshot.value;
          print('📍 nicknames data type: ${data.runtimeType}');
          print('📍 nicknames data: $data');

          if (data is Map) {
            final nicknames = Map<String, dynamic>.from(data);
            print('📍 All nicknames keys: ${nicknames.keys.toList()}');

            for (var entry in nicknames.entries) {
              print('📍 Comparing: "${entry.key.toLowerCase()}" == "$lowerNickname"');
              if (entry.key.toLowerCase() == lowerNickname) {
                print('✅ Found match in nicknames table: ${entry.key} -> ${entry.value}');
                return entry.value.toString();
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error scanning nicknames table: $e');
      }

      // YÖNTEM 4: users tablosunda nickname field'ında ara
      try {
        final usersSnapshot = await _ref.child('users').get();
        print('📍 users table exists: ${usersSnapshot.exists}');

        if (usersSnapshot.exists && usersSnapshot.value != null) {
          final data = usersSnapshot.value;

          if (data is Map) {
            final users = Map<String, dynamic>.from(data);
            print('📍 Total users: ${users.length}');

            for (var entry in users.entries) {
              final uid = entry.key;
              final userData = entry.value;

              if (userData is Map) {
                final userNickname = userData['nickname']?.toString() ?? '';
                final userNicknameLower = userData['nicknameLower']?.toString() ?? '';

                print('📍 User $uid: nickname="$userNickname", nicknameLower="$userNicknameLower"');

                if (userNickname.toLowerCase() == lowerNickname ||
                    userNicknameLower == lowerNickname) {
                  print('✅ Found match in users table: $uid');
                  return uid;
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error scanning users table: $e');
      }

      print('❌ Nickname not found: $searchNickname');
      return null;
    } catch (e) {
      print('❌ Error in getUidByNickname: $e');
      return null;
    }
  }

  /// Nickname mapping kaydet - HEM nicknames HEM users tablosuna
  Future<void> saveNicknameMapping(String nickname) async {
    final uid = currentUserId;
    if (uid == null || nickname.isEmpty) return;

    try {
      final lowerNickname = nickname.toLowerCase();
      print('💾 Saving nickname mapping: $nickname -> $uid');

      // 1. Eski nickname'i sil (varsa)
      try {
        final oldNicknameSnapshot = await _ref.child('users/$uid/nickname').get();
        if (oldNicknameSnapshot.exists && oldNicknameSnapshot.value != null) {
          final oldNickname = oldNicknameSnapshot.value.toString().toLowerCase();
          if (oldNickname.isNotEmpty && oldNickname != lowerNickname) {
            await _ref.child('nicknames/$oldNickname').remove();
            print('🗑️ Removed old nickname mapping: $oldNickname');
          }
        }
      } catch (e) {
        print('⚠️ Error removing old nickname: $e');
      }

      // 2. nicknames tablosuna kaydet
      await _ref.child('nicknames/$lowerNickname').set(uid);
      print('✅ Saved to nicknames/$lowerNickname');

      // 3. users tablosuna kaydet
      await _ref.child('users/$uid').update({
        'nickname': nickname,
        'nicknameLower': lowerNickname,
      });
      print('✅ Saved to users/$uid/nickname');

    } catch (e) {
      print('❌ Error saving nickname mapping: $e');
    }
  }

  /// Online durumunu ayarla
  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      await _ref.child('users/$uid').update({
        'isOnline': isOnline,
        'lastSeen': now,
      });

      await _ref.child('presence/$uid').set({
        'online': isOnline,
        'lastSeen': now,
      });

      if (isOnline) {
        _ref.child('users/$uid/isOnline').onDisconnect().set(false);
        _ref.child('users/$uid/lastSeen').onDisconnect().set(ServerValue.timestamp);
        _ref.child('presence/$uid/online').onDisconnect().set(false);
        _ref.child('presence/$uid/lastSeen').onDisconnect().set(ServerValue.timestamp);

        _presenceTimer?.cancel();
        _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          _ref.child('users/$uid/lastSeen').set(ServerValue.timestamp);
          _ref.child('presence/$uid/lastSeen').set(ServerValue.timestamp);
        });
      } else {
        _presenceTimer?.cancel();
      }
    } catch (e) {
      print('Error setting online status: $e');
    }
  }

  /// Kullanıcı online mı kontrol et
  Future<bool> _isUserOnline(String uid) async {
    try {
      final presenceSnapshot = await _ref.child('presence/$uid').get();
      if (presenceSnapshot.exists && presenceSnapshot.value != null) {
        final data = Map<String, dynamic>.from(presenceSnapshot.value as Map);
        final online = data['online'] == true;
        final lastSeen = data['lastSeen'] as int?;

        if (lastSeen != null) {
          final diff = DateTime.now().millisecondsSinceEpoch - lastSeen;
          if (diff < 120000) return true;
        }
        if (online) return true;
      }

      final userSnapshot = await _ref.child('users/$uid').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        final data = Map<String, dynamic>.from(userSnapshot.value as Map);
        final online = data['isOnline'] == true;
        final lastSeen = data['lastSeen'] as int?;

        if (lastSeen != null) {
          final diff = DateTime.now().millisecondsSinceEpoch - lastSeen;
          if (diff < 120000) return true;
        }
        return online;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Arkadaşlık isteği gönder
  Future<FriendResult> sendFriendRequest(String targetNickname) async {
    final uid = currentUserId;
    if (uid == null) {
      return FriendResult(success: false, message: 'Oturum açılmamış');
    }

    try {
      print('📤 Sending friend request to: "$targetNickname"');

      // Hedef kullanıcının UID'sini bul
      final targetUid = await getUidByNickname(targetNickname);

      if (targetUid == null) {
        print('❌ Target user not found');
        return FriendResult(success: false, message: 'Kullanıcı bulunamadı');
      }

      print('✅ Found target UID: $targetUid');

      if (targetUid == uid) {
        return FriendResult(success: false, message: 'Kendinize istek gönderemezsiniz');
      }

      // Zaten arkadaş mı
      final existingFriend = await _ref.child('users/$uid/friends/$targetUid').get();
      if (existingFriend.exists) {
        return FriendResult(success: false, message: 'Zaten arkadaşsınız');
      }

      // Bekleyen istek var mı
      final pendingRequest = await _ref.child('users/$targetUid/friendRequests/$uid').get();
      if (pendingRequest.exists) {
        return FriendResult(success: false, message: 'İstek zaten gönderilmiş');
      }

      // Kendi nickname'imi al
      final myNickname = await getNicknameByUid(uid);

      // İsteği gönder
      await _ref.child('users/$targetUid/friendRequests/$uid').set({
        'nickname': myNickname,
        'createdAt': ServerValue.timestamp,
      });

      print('✅ Friend request sent successfully');
      return FriendResult(success: true, message: 'İstek gönderildi!');
    } catch (e) {
      print('❌ Error sending friend request: $e');
      return FriendResult(success: false, message: 'Bir hata oluştu');
    }
  }

  /// Arkadaşlık isteğini kabul et
  Future<bool> acceptFriendRequest(String fromUid) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final myNickname = await getNicknameByUid(uid);
      final theirNickname = await getNicknameByUid(fromUid);

      await _ref.child('users/$uid/friends/$fromUid').set({
        'nickname': theirNickname,
        'addedAt': ServerValue.timestamp,
      });

      await _ref.child('users/$fromUid/friends/$uid').set({
        'nickname': myNickname,
        'addedAt': ServerValue.timestamp,
      });

      await _ref.child('users/$uid/friendRequests/$fromUid').remove();

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Arkadaşlık isteğini reddet
  Future<void> rejectFriendRequest(String fromUid) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _ref.child('users/$uid/friendRequests/$fromUid').remove();
  }

  /// Arkadaş listesini al
  Future<List<FriendData>> getFriends() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final snapshot = await _ref.child('users/$uid/friends').get();
      if (!snapshot.exists) return [];

      final friendsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<FriendData> friends = [];

      for (var friendUid in friendsMap.keys) {
        final nickname = await getNicknameByUid(friendUid);
        final isOnline = await _isUserOnline(friendUid);

        int level = 1;
        DateTime? lastSeen;

        final userSnapshot = await _ref.child('users/$friendUid').get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          level = userData['level'] ?? 1;
          if (userData['lastSeen'] != null) {
            lastSeen = DateTime.fromMillisecondsSinceEpoch(userData['lastSeen'] as int);
          }
        }

        friends.add(FriendData(
          uid: friendUid,
          nickname: nickname,
          level: level,
          online: isOnline,
          lastSeen: lastSeen,
        ));
      }

      friends.sort((a, b) {
        if (a.online && !b.online) return -1;
        if (!a.online && b.online) return 1;
        return a.nickname.compareTo(b.nickname);
      });

      return friends;
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  /// Arkadaşlık isteklerini al
  Future<List<FriendRequest>> getFriendRequests() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final snapshot = await _ref.child('users/$uid/friendRequests').get();
      if (!snapshot.exists) return [];

      final requestsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<FriendRequest> requests = [];

      for (var entry in requestsMap.entries) {
        final fromUid = entry.key;
        final nickname = await getNicknameByUid(fromUid);

        requests.add(FriendRequest(
          uid: fromUid,
          nickname: nickname,
          createdAt: DateTime.now(),
        ));
      }

      return requests;
    } catch (e) {
      print('Error getting friend requests: $e');
      return [];
    }
  }

  /// Real-time arkadaş istekleri
  Stream<List<FriendRequest>> watchFriendRequests() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _ref.child('users/$uid/friendRequests').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return <FriendRequest>[];

      final requestsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<FriendRequest> requests = [];

      for (var entry in requestsMap.entries) {
        final fromUid = entry.key;
        final nickname = await getNicknameByUid(fromUid);
        requests.add(FriendRequest(uid: fromUid, nickname: nickname, createdAt: DateTime.now()));
      }

      return requests;
    });
  }

  /// Real-time arkadaş listesi
  Stream<List<FriendData>> watchFriends() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _ref.child('users/$uid/friends').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return <FriendData>[];

      final friendsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<FriendData> friends = [];

      for (var friendUid in friendsMap.keys) {
        final nickname = await getNicknameByUid(friendUid);
        final isOnline = await _isUserOnline(friendUid);

        int level = 1;
        DateTime? lastSeen;

        final userSnapshot = await _ref.child('users/$friendUid').get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          level = userData['level'] ?? 1;
          if (userData['lastSeen'] != null) {
            lastSeen = DateTime.fromMillisecondsSinceEpoch(userData['lastSeen'] as int);
          }
        }

        friends.add(FriendData(
          uid: friendUid,
          nickname: nickname,
          level: level,
          online: isOnline,
          lastSeen: lastSeen,
        ));
      }

      friends.sort((a, b) {
        if (a.online && !b.online) return -1;
        if (!a.online && b.online) return 1;
        return a.nickname.compareTo(b.nickname);
      });

      return friends;
    });
  }

  void dispose() {
    _presenceTimer?.cancel();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';

/// Available badge types
class BadgeType {
  final String id;
  final String nameEn;
  final String nameTr;
  final String icon;
  final String shopId;

  const BadgeType({
    required this.id,
    required this.nameEn,
    required this.nameTr,
    required this.icon,
    required this.shopId,
  });

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;

  static const master = BadgeType(
    id: 'master',
    nameEn: 'Sudoku Master',
    nameTr: 'Sudoku Ustası',
    icon: '🎖️',
    shopId: 'badge_master',
  );

  static const speedster = BadgeType(
    id: 'speedster',
    nameEn: 'Speed Demon',
    nameTr: 'Hız Şeytanı',
    icon: '🏎️',
    shopId: 'badge_speedster',
  );

  static const genius = BadgeType(
    id: 'genius',
    nameEn: 'Puzzle Genius',
    nameTr: 'Bulmaca Dehası',
    icon: '🧠',
    shopId: 'badge_genius',
  );

  static const champion = BadgeType(
    id: 'champion',
    nameEn: 'Champion',
    nameTr: 'Şampiyon',
    icon: '🏆',
    shopId: 'badge_champion',
  );

  static const List<BadgeType> all = [
    master,
    speedster,
    genius,
    champion,
  ];

  static BadgeType? getById(String id) {
    try {
      return all.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Service for managing user badges
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get user's selected badge
  Future<String?> getSelectedBadge() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final snapshot = await _database.child('users/$userId/selectedBadge').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedBadge');
    } catch (e) {
      print('Error getting selected badge: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedBadge');
    }
  }

  /// Set user's selected badge
  Future<void> setSelectedBadge(String? badgeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      if (badgeId == null) {
        await _database.child('users/$userId/selectedBadge').remove();
      } else {
        await _database.child('users/$userId/selectedBadge').set(badgeId);
      }

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      if (badgeId == null) {
        await prefs.remove('selectedBadge');
      } else {
        await prefs.setString('selectedBadge', badgeId);
      }
    } catch (e) {
      print('Error setting selected badge: $e');
    }
  }

  /// Check if user owns a badge
  Future<bool> hasBadge(String badgeId) async {
    final badge = BadgeType.getById(badgeId);
    if (badge == null) return false;

    final currencyService = CurrencyService();
    final purchased = await currencyService.getPurchasedItems();

    return purchased.contains(badge.shopId);
  }

  /// Get all owned badges
  Future<List<BadgeType>> getOwnedBadges() async {
    final owned = <BadgeType>[];

    for (final badge in BadgeType.all) {
      if (await hasBadge(badge.id)) {
        owned.add(badge);
      }
    }

    return owned;
  }

  /// Get badge display text (icon + name or just nickname)
  Future<String> getBadgeDisplayName(String nickname, String locale) async {
    final badgeId = await getSelectedBadge();
    if (badgeId == null) return nickname;

    final badge = BadgeType.getById(badgeId);
    if (badge == null) return nickname;

    return '${badge.icon} $nickname';
  }
}

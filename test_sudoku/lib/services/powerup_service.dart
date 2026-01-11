import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';

/// Power-up types available in the game
enum PowerUpType {
  doubleScore,   // 2x Score Multiplier
  autoCheck,     // Auto Error Detection
  timeFreeze,    // Time Freeze (Race mode)
}

/// Service for managing power-ups
class PowerUpService {
  static final PowerUpService _instance = PowerUpService._internal();
  factory PowerUpService() => _instance;
  PowerUpService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get power-up count for a specific type
  Future<int> getPowerUpCount(PowerUpType type) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final key = _getPowerUpKey(type);

    try {
      final snapshot = await _database.child('users/$userId/powerups/$key').get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('powerup_$key') ?? 0;
    } catch (e) {
      print('Error getting power-up count: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('powerup_$key') ?? 0;
    }
  }

  /// Check if user owns a power-up (purchased from shop)
  Future<bool> hasPowerUp(PowerUpType type) async {
    final currencyService = CurrencyService();
    final purchased = await currencyService.getPurchasedItems();

    final shopItemId = _getShopItemId(type);
    return purchased.contains(shopItemId);
  }

  /// Use a power-up (one-time use for non-permanent power-ups)
  Future<bool> usePowerUp(PowerUpType type) async {
    // For now, power-ups are permanent unlocks from shop
    // They don't have a count, just ownership
    return await hasPowerUp(type);
  }

  /// Get shop item ID for power-up
  String _getShopItemId(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleScore:
        return 'powerup_2x_score';
      case PowerUpType.autoCheck:
        return 'powerup_auto_check';
      case PowerUpType.timeFreeze:
        return 'powerup_time_freeze';
    }
  }

  /// Get power-up key for storage
  String _getPowerUpKey(PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleScore:
        return 'double_score';
      case PowerUpType.autoCheck:
        return 'auto_check';
      case PowerUpType.timeFreeze:
        return 'time_freeze';
    }
  }

  /// Get all owned power-ups
  Future<List<PowerUpType>> getOwnedPowerUps() async {
    final owned = <PowerUpType>[];

    for (final type in PowerUpType.values) {
      if (await hasPowerUp(type)) {
        owned.add(type);
      }
    }

    return owned;
  }
}

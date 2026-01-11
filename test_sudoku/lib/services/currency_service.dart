import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing in-game currency (coins)
/// Coins are earned from achievements and daily challenges
/// and can be spent in the shop for premium items
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get current coin balance
  Future<int> getCoins() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      // Try to get from Firebase first
      final snapshot = await _database.child('users/$userId/coins').get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('coins') ?? 0;
    } catch (e) {
      print('Error getting coins: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('coins') ?? 0;
    }
  }

  /// Add coins to user's balance
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final currentCoins = await getCoins();
      final newBalance = currentCoins + amount;

      // Save to Firebase
      await _database.child('users/$userId/coins').set(newBalance);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', newBalance);
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  /// Spend coins (returns true if successful, false if insufficient funds)
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return false;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final currentCoins = await getCoins();
      if (currentCoins < amount) return false;

      final newBalance = currentCoins - amount;

      // Save to Firebase
      await _database.child('users/$userId/coins').set(newBalance);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', newBalance);

      return true;
    } catch (e) {
      print('Error spending coins: $e');
      return false;
    }
  }

  /// Check if user has purchased an item
  Future<bool> hasPurchased(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await _database.child('users/$userId/purchases/$itemId').get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking purchase: $e');
      return false;
    }
  }

  /// Mark an item as purchased
  Future<void> markAsPurchased(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _database.child('users/$userId/purchases/$itemId').set({
        'purchasedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error marking purchase: $e');
    }
  }

  /// Get purchased items
  Future<List<String>> getPurchasedItems() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _database.child('users/$userId/purchases').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.keys.toList();
    } catch (e) {
      print('Error getting purchases: $e');
      return [];
    }
  }
}

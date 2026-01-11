import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing hint inventory
class HintService {
  static final HintService _instance = HintService._internal();
  factory HintService() => _instance;
  HintService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get current hint count
  Future<int> getHintCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 3; // Default hints

    try {
      final snapshot = await _database.child('users/$userId/hints').get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('totalHints') ?? 3;
    } catch (e) {
      print('Error getting hints: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('totalHints') ?? 3;
    }
  }

  /// Add hints to user's inventory
  Future<void> addHints(int amount) async {
    if (amount <= 0) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final currentHints = await getHintCount();
      final newCount = currentHints + amount;

      // Save to Firebase
      await _database.child('users/$userId/hints').set(newCount);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalHints', newCount);

      print('✅ Added $amount hints. New total: $newCount');
    } catch (e) {
      print('Error adding hints: $e');
    }
  }

  /// Use a hint (decrease count)
  Future<bool> useHint() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final currentHints = await getHintCount();
      if (currentHints <= 0) return false;

      final newCount = currentHints - 1;

      // Save to Firebase
      await _database.child('users/$userId/hints').set(newCount);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalHints', newCount);

      return true;
    } catch (e) {
      print('Error using hint: $e');
      return false;
    }
  }

  /// Set hint count (for game initialization)
  Future<void> setHintCount(int count) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Save to Firebase
      await _database.child('users/$userId/hints').set(count);

      // Save to SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalHints', count);
    } catch (e) {
      print('Error setting hints: $e');
    }
  }
}

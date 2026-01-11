import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Quick script to add test coins to a user
/// Run with: dart add_test_coins.dart
Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  final database = FirebaseDatabase.instance.ref();

  // Find user by nickname
  final nicknameSnapshot = await database.child('nicknames/gokhananac66').get();

  if (!nicknameSnapshot.exists) {
    print('❌ User not found with nickname: gokhananac66');
    return;
  }

  final userId = nicknameSnapshot.value as String;
  print('✅ Found user ID: $userId');

  // Add 1000 coins
  await database.child('users/$userId/coins').set(1000);

  print('✅ Added 1000 coins to gokhananac66!');
  print('🎉 User can now test the shop!');
}

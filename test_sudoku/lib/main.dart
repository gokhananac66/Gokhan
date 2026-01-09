import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/online_game_screen.dart';
import 'app_localizations.dart';
import 'widgets/global_invite_overlay.dart';
import 'services/game_invite_service.dart';
import 'services/sound_service.dart';
import 'services/haptic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseDatabase.instance.databaseURL =
  'https://multiplayer-sudoku-v1-default-rtdb.europe-west1.firebasedatabase.app';

  await AppLocalizations.loadLanguage();

  // Initialize services
  await SoundService().init();
  await HapticService().init();

  runApp(const MyApp());
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GameInviteService _inviteService = GameInviteService();

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() {
      setState(() {});
    });

    // Global davet dinleyicisi - kullanıcı login olduğunda otomatik başlar
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print('🌍 [MAIN] User logged in, starting global invite listener');
        // GlobalInviteNotifier içeride zaten notify ediyor, callback'e gerek yok
        _inviteService.listenToIncomingInvites((_) {});
      }
    });
  }

  @override
  void dispose() {
    _inviteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalInviteOverlay(
      onAccept: _handleInviteAccept,
      onReject: _handleInviteReject,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Sudoku Clash',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey.shade50,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white, elevation: 0),
          cardColor: const Color(0xFF1E1E1E),
          dialogBackgroundColor: const Color(0xFF2D2D2D),
        ),
        themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }

  void _handleInviteAccept(GameInvite invite) async {
    final inviteService = GameInviteService();
    await inviteService.acceptInvite(invite.id);

    // Navigate to game screen
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => OnlineGameScreen(
          gameId: invite.gameId!,
          isPlayer1: false, // Davet kabul eden player2
          difficulty: invite.difficulty,
          gameMode: invite.gameMode ?? 'classic',
          startsFirst: invite.gameMode == 'race' ? true : false,
        ),
      ),
    );
  }

  void _handleInviteReject(GameInvite invite) async {
    final inviteService = GameInviteService();
    await inviteService.rejectInvite(invite.id);
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
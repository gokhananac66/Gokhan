import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global context for translations
BuildContext? _globalContext;

void setGlobalContext(BuildContext context) {
  _globalContext = context;
}

/// Shorthand translation function
String tr(String key) {
  return AppLocalizations.get(key);
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // ========== STATIC METHODS ==========
  static String _currentLanguage = 'tr';

  static String get currentLanguage => _currentLanguage;

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'tr';
  }

  static Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }

  static String get(String key) {
    return _localizedValues[_currentLanguage]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
  // =====================================

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'Sudoku Clash',
      'loading': 'Loading...',
      'error': 'Error',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'close': 'Close',
      'back': 'Back',
      'retry': 'Retry',

      // Menu & Home
      'sudoku': 'SUDOKU',
      'clash': 'CLASH',
      'tagline': 'Challenge Your Mind',
      'play': 'Play',
      'singlePlayer': 'Single Player',
      'singlePlayerDesc': 'Play alone and improve your skills',
      'onlineMultiplayer': 'Online Multiplayer',
      'onlineMultiplayerDesc': 'Compete with players worldwide',
      'randomOpponent': 'Random Opponent',
      'randomOpponentDesc': 'Find a random player to play',
      'playWithFriend': 'Play with Friend',
      'playWithFriendDesc': 'Invite your friends to play',
      'settings': 'Settings',
      'settingsDesc': 'Customize your game experience',
      'leaderboard': 'Leaderboard',
      'profile': 'Profile',
      'selectGameMode': 'Select Game Mode',
      'findOpponent': 'Find Opponent',
      'viewFriends': 'View Friends',

      // Settings Screen
      'editAccountInfo': 'Edit account information',
      'statistics': 'Statistics',
      'viewPerformance': 'View your performance',
      'globalRankings': 'Global rankings',
      'systemSettings': 'System Settings',
      'systemSettingsDesc': 'App preferences',
      'aboutGame': 'About Game',
      'versAndFeatures': 'Version and features',
      'resetData': 'Reset Data',
      'clearAllStats': 'Clear all statistics',

      // System Settings Screen - YENİ EKLENENLER
      'soundEffects': 'Sound Effects',
      'soundEffectsDesc': 'Enable game sounds',
      'vibration': 'Vibration',
      'vibrationDesc': 'Enable haptic feedback',
      'timer': 'Timer',
      'timerDesc': 'Show game timer',
      'darkTheme': 'Dark Theme',
      'darkThemeDesc': 'Enable dark mode',
      'language': 'Language',
      'languageDesc': 'Select app language',

      // Difficulty
      'selectDifficulty': 'Select Difficulty',
      'easy': 'Easy',
      'easyDesc': 'Perfect for beginners',
      'medium': 'Medium',
      'mediumDesc': 'A balanced challenge',
      'hard': 'Hard',
      'hardDesc': 'For experienced players',
      'expert': 'Expert',
      'expertDesc': 'Ultimate challenge',
      'newGame': 'New Game',
      'continue': 'Continue',

      // Game
      'score': 'Score',
      'errors': 'Errors',
      'combo': 'Combo',
      'time': 'Time',
      'yourTurn': 'YOUR TURN',
      'opponentTurn': "OPPONENT'S TURN",
      'timeUp': "Time's up!",
      'notes': 'Notes',

      // Friends
      'friends': 'Friends',
      'addFriend': 'Add Friend',
      'friendRequests': 'Friend Requests',
      'onlineFriends': 'Online Friends',
      'offlineFriends': 'Offline Friends',
      'noOnlineFriends': 'No online friends',
      'noFriendsYet': 'No friends yet',
      'addFriendsToPlay': 'Add friends to play together!',
      'enterFriendNickname': "Enter your friend's nickname",
      'nickname': 'Nickname',
      'sendRequest': 'Send Request',
      'wantsToBeYourFriend': 'wants to be your friend',
      'addedAsFriend': 'added as friend!',
      'online': 'Online',
      'offline': 'Offline',

      // Invites
      'invite': 'Invite',
      'gameInvite': 'Game Invite',
      'invitesYouToPlay': 'invites you to play!',
      'difficulty': 'Difficulty',
      'accept': 'Accept',
      'reject': 'Reject',
      'inviteSentTo': 'Invite sent to',
      'waitingFor': 'Waiting for',
      'inviteRejected': 'Invite rejected',
      'inviteExpired': 'Invite expired',

      // Matchmaking
      'searchingOpponent': 'Searching for opponent...',
      'matchFound': 'Match found!',
      'preparingGame': 'Preparing game...',
      'cancelSearch': 'Cancel Search',

      // Game Results
      'youWin': 'YOU WIN!',
      'youLose': 'YOU LOSE!',
      'draw': 'DRAW!',
      'opponentLeft': 'Opponent left the game',
      'youWonByDefault': 'You won! Opponent left.',
      'maxErrorsReached': 'Maximum errors reached!',
      'playAgain': 'Play Again',
      'backToMenu': 'Back to Menu',

      // Errors
      'userNotFound': 'User not found',
      'alreadyFriends': 'Already friends',
      'requestSent': 'Request sent!',
      'connectionError': 'Connection error',

      // Leaderboard
      'lbToday': 'Today',
      'lbThisWeek': 'This Week',
      'lbAllTime': 'All Time',
      'noScoresYet': 'No scores yet',
      'yourRank': 'Your Rank',
    },
    'tr': {
      // Genel
      'app_name': 'Sudoku Clash',
      'loading': 'Yükleniyor...',
      'error': 'Hata',
      'cancel': 'İptal',
      'ok': 'Tamam',
      'yes': 'Evet',
      'no': 'Hayır',
      'save': 'Kaydet',
      'close': 'Kapat',
      'back': 'Geri',
      'retry': 'Tekrar Dene',

      // Menü & Ana Sayfa
      'sudoku': 'SUDOKU',
      'clash': 'CLASH',
      'tagline': 'Zihnini Zorla',
      'play': 'Oyna',
      'singlePlayer': 'Tek Oyunculu',
      'singlePlayerDesc': 'Yalnız oyna ve yeteneklerini geliştir',
      'onlineMultiplayer': 'Online Multiplayer',
      'onlineMultiplayerDesc': 'Dünya genelinde oyuncularla yarış',
      'randomOpponent': 'Rastgele Rakip',
      'randomOpponentDesc': 'Rastgele bir oyuncu bul',
      'playWithFriend': 'Arkadaşla Oyna',
      'playWithFriendDesc': 'Arkadaşlarını oyuna davet et',
      'settings': 'Ayarlar',
      'settingsDesc': 'Oyun deneyimini özelleştir',
      'leaderboard': 'Liderlik Tablosu',
      'profile': 'Profil',
      'selectGameMode': 'Oyun Modu Seç',
      'findOpponent': 'Rakip Bul',
      'viewFriends': 'Arkadaşları Gör',

      // Ayarlar Ekranı
      'editAccountInfo': 'Hesap bilgilerini düzenle',
      'statistics': 'İstatistikler',
      'viewPerformance': 'Performansını görüntüle',
      'globalRankings': 'Dünya sıralaması',
      'systemSettings': 'Sistem Ayarları',
      'systemSettingsDesc': 'Uygulama tercihleri',
      'aboutGame': 'Oyun Hakkında',
      'versAndFeatures': 'Versiyon ve özellikler',
      'resetData': 'Verileri Sıfırla',
      'clearAllStats': 'Tüm istatistikleri temizle',

      // Sistem Ayarları Ekranı - YENİ EKLENENLER
      'soundEffects': 'Ses Efektleri',
      'soundEffectsDesc': 'Oyun seslerini etkinleştir',
      'vibration': 'Titreşim',
      'vibrationDesc': 'Dokunsal geri bildirimi etkinleştir',
      'timer': 'Zamanlayıcı',
      'timerDesc': 'Oyun zamanlayıcısını göster',
      'darkTheme': 'Karanlık Tema',
      'darkThemeDesc': 'Karanlık modu etkinleştir',
      'language': 'Dil',
      'languageDesc': 'Uygulama dilini seç',

      // Zorluk
      'selectDifficulty': 'Zorluk Seç',
      'easy': 'Kolay',
      'easyDesc': 'Yeni başlayanlar için',
      'medium': 'Orta',
      'mediumDesc': 'Dengeli bir meydan okuma',
      'hard': 'Zor',
      'hardDesc': 'Deneyimli oyuncular için',
      'expert': 'Uzman',
      'expertDesc': 'En zorlu seviye',
      'newGame': 'Yeni Oyun',
      'continue': 'Devam Et',

      // Oyun
      'score': 'Puan',
      'errors': 'Hatalar',
      'combo': 'Kombo',
      'time': 'Süre',
      'yourTurn': 'SENİN SIRAN',
      'opponentTurn': 'RAKİBİN SIRASI',
      'timeUp': 'Süre doldu!',
      'notes': 'Notlar',

      // Arkadaşlar
      'friends': 'Arkadaşlar',
      'addFriend': 'Arkadaş Ekle',
      'friendRequests': 'Arkadaşlık İstekleri',
      'onlineFriends': 'Çevrimiçi',
      'offlineFriends': 'Çevrimdışı',
      'noOnlineFriends': 'Çevrimiçi arkadaş yok',
      'noFriendsYet': 'Henüz arkadaş yok',
      'addFriendsToPlay': 'Arkadaşlarını ekle ve birlikte oyna!',
      'enterFriendNickname': 'Arkadaşının kullanıcı adını gir',
      'nickname': 'Kullanıcı Adı',
      'sendRequest': 'İstek Gönder',
      'wantsToBeYourFriend': 'seninle arkadaş olmak istiyor',
      'addedAsFriend': 'arkadaş olarak eklendi!',
      'online': 'Çevrimiçi',
      'offline': 'Çevrimdışı',

      // Davetler
      'invite': 'Davet Et',
      'gameInvite': 'Oyun Daveti',
      'invitesYouToPlay': 'seni oyuna davet ediyor!',
      'difficulty': 'Zorluk',
      'accept': 'Kabul Et',
      'reject': 'Reddet',
      'inviteSentTo': 'Davet gönderildi:',
      'waitingFor': 'Bekleniyor:',
      'inviteRejected': 'Davet reddedildi',
      'inviteExpired': 'Davetin süresi doldu',

      // Eşleşme
      'searchingOpponent': 'Rakip aranıyor...',
      'matchFound': 'Eşleşme bulundu!',
      'preparingGame': 'Oyun hazırlanıyor...',
      'cancelSearch': 'Aramayı İptal Et',

      // Oyun Sonuçları
      'youWin': 'KAZANDIN!',
      'youLose': 'KAYBETTİN!',
      'draw': 'BERABERE!',
      'opponentLeft': 'Rakip oyunu terk etti',
      'youWonByDefault': 'Kazandın! Rakip oyunu terk etti.',
      'maxErrorsReached': 'Maksimum hata sayısına ulaşıldı!',
      'playAgain': 'Tekrar Oyna',
      'backToMenu': 'Menüye Dön',

      // Hatalar
      'userNotFound': 'Kullanıcı bulunamadı',
      'alreadyFriends': 'Zaten arkadaşsınız',
      'requestSent': 'İstek gönderildi!',
      'connectionError': 'Bağlantı hatası',

      // Liderlik
      'lbToday': 'Bugün',
      'lbThisWeek': 'Bu Hafta',
      'lbAllTime': 'Tüm Zamanlar',
      'noScoresYet': 'Henüz skor yok',
      'yourRank': 'Sıralaman',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
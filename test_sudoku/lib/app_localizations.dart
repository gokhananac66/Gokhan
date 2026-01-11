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
      'achievements': 'Achievements',
      'achievementsDesc': 'Unlock badges and rewards',
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
      'expertDesc': 'Very challenging',
      'master': 'Master',
      'masterDesc': 'Only for masters',
      'extreme': 'Extreme',
      'extremeDesc': 'Ultimate challenge',
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

      // Progression
      'win': 'win',
      'more': 'more',

      // Statistics
      'games': 'Games',
      'gamesStarted': 'Games Started',
      'gamesWon': 'Games Won',
      'winRate': 'Win Rate',
      'perfectWins': 'Perfect Wins',
      'bestScore': 'Best Score',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'allTime': 'All Time',
      'streaks': 'Streaks',
      'currentStreak': 'Current Streak',
      'bestStreak': 'Best Streak',
      'resetStats': 'Reset Statistics',
      'resetConfirm': 'Are you sure you want to reset all statistics?',
      'statsReset': 'Statistics have been reset',
      'reset': 'Reset',
      'fourDifficulties': 'Four Difficulty Levels',
      'notesSystem': 'Notes System',
      'hintSystem': 'Hint System',
      'noHintsLeft': 'No hints left!',
      'noHintAvailable': 'No hint available',
      'comboScoring': 'Combo Scoring System',
      'version': 'Version',
      'features': 'Features',
      'aboutDesc': 'A modern Sudoku game with online multiplayer features.',
      'dataReset': 'All data has been reset',

      // Profile
      'notSpecified': 'Not set yet',
      'personalInfo': 'Personal Information',
      'fullName': 'Full Name',
      'enterFullName': 'Enter your full name',
      'birthDate': 'Birth Date',
      'selectBirthDate': 'Select Birth Date',
      'age': 'Age',
      'yearsOld': 'years old',
      'country': 'Country',
      'selectCountry': 'Select Country',
      'signOut': 'Sign Out',
      'addNickname': 'Add Nickname',
      'enterNickname': 'Enter nickname',
      'nicknameSaved': 'Nickname saved!',
      'nameSaved': 'Name saved!',
      'nicknameEmpty': 'Nickname cannot be empty',
      'nicknameShort': 'Nickname must be at least 3 characters',
      'nicknameLong': 'Nickname must be maximum 15 characters',
      'nicknameChars': 'Nickname can only contain letters, numbers and underscore',
      'nicknameTaken': 'This nickname is already taken',
      'googlePhoto': 'Using Google profile photo',
      'guestUser': 'Guest User',
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
      'achievements': 'Başarımlar',
      'achievementsDesc': 'Rozet ve ödüllerin kilidini aç',
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
      'expertDesc': 'Çok zorlu',
      'master': 'Usta',
      'masterDesc': 'Sadece ustalar için',
      'extreme': 'Ekstrem',
      'extremeDesc': 'En zorlu seviye',
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

      // Progression
      'win': 'kazanma',
      'more': 'daha',

      // İstatistikler
      'games': 'Oyunlar',
      'gamesStarted': 'Başlatılan Oyunlar',
      'gamesWon': 'Kazanılan Oyunlar',
      'winRate': 'Kazanma Oranı',
      'perfectWins': 'Hatasız Kazanımlar',
      'bestScore': 'En İyi Skor',
      'today': 'Bugün',
      'thisWeek': 'Bu Hafta',
      'thisMonth': 'Bu Ay',
      'allTime': 'Tüm Zamanlar',
      'streaks': 'Seriler',
      'currentStreak': 'Mevcut Seri',
      'bestStreak': 'En İyi Seri',
      'resetStats': 'İstatistikleri Sıfırla',
      'resetConfirm': 'Tüm istatistikleri sıfırlamak istediğinizden emin misiniz?',
      'statsReset': 'İstatistikler sıfırlandı',
      'reset': 'Sıfırla',
      'fourDifficulties': 'Dört Zorluk Seviyesi',
      'notesSystem': 'Not Sistemi',
      'hintSystem': 'İpucu Sistemi',
      'noHintsLeft': 'İpucu kalmadı!',
      'noHintAvailable': 'Uygun ipucu yok',
      'comboScoring': 'Kombo Puanlama Sistemi',
      'version': 'Versiyon',
      'features': 'Özellikler',
      'aboutDesc': 'Online multiplayer özellikleri ile modern bir Sudoku oyunu.',
      'dataReset': 'Tüm veriler sıfırlandı',

      // Profil
      'notSpecified': 'Henüz belirlenmedi',
      'personalInfo': 'Kişisel Bilgiler',
      'fullName': 'İsim Soyisim',
      'enterFullName': 'İsim soyisminizi girin',
      'birthDate': 'Doğum Tarihi',
      'selectBirthDate': 'Doğum Tarihi Seç',
      'age': 'Yaş',
      'yearsOld': 'yaşında',
      'country': 'Ülke',
      'selectCountry': 'Ülke Seç',
      'signOut': 'Çıkış Yap',
      'addNickname': 'Kullanıcı Adı Ekle',
      'enterNickname': 'Kullanıcı adı girin',
      'nicknameSaved': 'Kullanıcı adı kaydedildi!',
      'nameSaved': 'İsim kaydedildi!',
      'nicknameEmpty': 'Kullanıcı adı boş olamaz',
      'nicknameShort': 'Kullanıcı adı en az 3 karakter olmalı',
      'nicknameLong': 'Kullanıcı adı en fazla 15 karakter olmalı',
      'nicknameChars': 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir',
      'nicknameTaken': 'Bu kullanıcı adı zaten kullanılıyor',
      'googlePhoto': 'Google profil fotoğrafı kullanılıyor',
      'guestUser': 'Misafir Kullanıcı',
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
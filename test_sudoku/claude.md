# SUDOKU CLASH - Proje Dokümantasyonu

**Proje Yolu:** `C:\Users\gamac\AndroidStudioProjects\Gokhan\test_sudoku\`

**Tarih:** 13 Ocak 2026

---

## İÇİNDEKİLER
1. [Proje Genel Bakış](#proje-genel-bakış)
2. [Proje Yapısı](#proje-yapısı)
3. [Ana Özellikler](#ana-özellikler)
4. [Mimari ve State Management](#mimari-ve-state-management)
5. [Firebase Entegrasyonu](#firebase-entegrasyonu)
6. [Ekranlar (20 Ekran)](#ekranlar)
7. [Servisler (22 Servis)](#servisler)
8. [Oyun Mantığı](#oyun-mantığı)
9. [Multiplayer Sistemi](#multiplayer-sistemi)
10. [Kritik Özellikler ve Uygulama Detayları](#kritik-özellikler)

---

## PROJE GENEL BAKIŞ

**Sudoku Clash**, Flutter ve Firebase kullanılarak geliştirilmiş profesyonel bir çevrimiçi çok oyunculu Sudoku oyunudur.

### Temel Özellikler
- ✅ Tek oyunculu mod (6 zorluk seviyesi)
- ✅ Çok oyunculu mod (Classic ve Race modları)
- ✅ Arkadaş sistemi ve davetler
- ✅ Günlük meydan okuma (deterministic puzzles)
- ✅ Lig sistemi (Bronze → Diamond)
- ✅ Başarımlar ve rozetler
- ✅ Liderlik tablosu
- ✅ Mağaza ve IAP entegrasyonu
- ✅ Tema sistemi (10 tema + dark mode)
- ✅ Çok dil desteği (TR/EN)
- ✅ Ses ve titreşim efektleri

### Teknoloji Stack
```yaml
Flutter: 3.5.0+
Dart: ^3.5.0
Firebase Auth + Realtime Database
Google Sign-In
Shared Preferences (local storage)
Audioplayers (ses)
FL Chart (grafikler)
```

---

## PROJE YAPISI

```
test_sudoku/
├── lib/
│   ├── main.dart                      # Uygulama giriş noktası
│   ├── app_localizations.dart         # i18n (TR/EN)
│   │
│   ├── models/                        # Data modelleri
│   │   ├── player_rank.dart           # Seviye ve lig sistemi
│   │   └── shop_item.dart             # Mağaza ürünleri
│   │
│   ├── screens/                       # 20 ekran
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── game_screen.dart           # TEK OYUNCULU
│   │   ├── online_game_screen.dart    # ÇOK OYUNCULU
│   │   ├── lobby_screen.dart          # Matchmaking
│   │   ├── friends_screen.dart
│   │   ├── daily_challenge_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── leaderboard_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── achievements_screen.dart
│   │   ├── shop_screen.dart
│   │   ├── coin_purchase_screen.dart
│   │   ├── coin_flip_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── services/                      # 22 servis (Singleton pattern)
│   │   ├── achievement_service.dart
│   │   ├── badge_service.dart
│   │   ├── currency_service.dart
│   │   ├── daily_challenge_service.dart
│   │   ├── friend_service.dart
│   │   ├── game_invite_service.dart
│   │   ├── matchmaking_service.dart
│   │   ├── multiplayer_game_service.dart
│   │   ├── leaderboard_service.dart
│   │   └── ... (22 toplam)
│   │
│   └── widgets/                       # 13 reusable widget
│       ├── global_invite_overlay.dart # GLOBAL DAVETİYE BANNER
│       ├── game_result_dialog.dart
│       ├── daily_reward_dialog.dart
│       └── ...
│
├── assets/
│   ├── images/                        # Logo, kupa, vb.
│   └── sounds/                        # Ses efektleri
│
├── android/                           # Android yapılandırması
├── ios/                               # iOS yapılandırması
├── database.rules.json                # Firebase güvenlik kuralları
└── pubspec.yaml                       # Bağımlılıklar
```

---

## ANA ÖZELLİKLER

### 1. TEK OYUNCULU MOD
**Dosya:** `lib/screens/game_screen.dart`

#### Zorluk Seviyeleri
| Zorluk | Boş Hücre | Max Hata |
|--------|-----------|----------|
| Kolay | 37 | 5 |
| Orta | 48 | 5 |
| Zor | 54 | 5 |
| Uzman | 58 | 5 |
| Usta | 61 | 3 |
| Ekstrem | 64 | 3 |

#### Özellikler
- Progressif kilit açma sistemi (örn: 2 Kolay kazanarak Orta açılır)
- Otomatik kaydetme ve devam etme
- Not alma sistemi
- İpucu sistemi
- Combo puanlama
- Zamanlayıcı (duraklatma ile)
- Ses ve titreşim feedback

---

### 2. ÇOK OYUNCULU MOD
**Dosya:** `lib/screens/online_game_screen.dart`

#### İki Oyun Modu

##### A) KLASİK MOD (⚔️)
- Sıra tabanlı oynanış
- 30 saniyelik tur zamanlayıcı
- Paylaşılan tahta
- Puan bazlı kazanan belirleme
- Yanlış hamle yapan oyuncu sırayı kaybeder

##### B) RACE MODU (🏁)
- Eş zamanlı oynanış
- Her oyuncu kendi tahtasında çözüm yapar
- İlk bitiren kazanır
- Gerçek zamanlı ilerleme takibi
- %70'e ulaşınca rakip uyarısı görünür
- İlerleme çubuğu ile görselleştirme

**Matchmaking Sistemi:**
- Lig bazlı eşleştirme (±1-2 lig genişleme)
- ±15 seviye farkı sınırı
- Aynı zorluk ve mod
- Atomik transaction kullanımı (race condition önleme)

---

### 3. GÜNLÜK MEYDAN OKUMA
**Dosya:** `lib/screens/daily_challenge_screen.dart`
**Servis:** `lib/services/daily_challenge_service.dart`

#### Deterministik Puzzle Sistemi
```dart
static int getTodaySeed() {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
}
```

**Özellikler:**
- Tüm oyuncular için aynı puzzle
- 4 günlük zorluk rotasyonu (Kolay → Orta → Zor → Uzman)
- Seri (streak) takibi
- Aylık takvim görünümü
- Ödül: 50 coin + 10 token

---

### 4. SOSYAL ÖZELLİKLER

#### Arkadaş Sistemi
**Dosya:** `lib/screens/friends_screen.dart`
**Servis:** `lib/services/friend_service.dart`

- Nickname ile arkadaş ekleme
- Arkadaşlık istekleri (kabul/red)
- Online/offline durum takibi
- Son görülme zamanı
- Gerçek zamanlı liste güncellemeleri
- Arkadaşları oyuna davet etme

#### Oyun Davetiyeleri
**Servis:** `lib/services/game_invite_service.dart`
**Widget:** `lib/widgets/global_invite_overlay.dart`

- Arkadaşlara davet gönderme
- Global davet banner (tüm ekranlarda görünür)
- 30 saniye timeout
- Revanche (rövanş) sistemi
- Mod seçimi (Classic/Race)

#### Son Oyuncular
**Servis:** `lib/services/recent_players_service.dart`

- Son karşılaşılan rakipler
- Hızlı rövanş
- Oyun sonuç geçmişi

---

### 5. LİG VE SEVİYE SİSTEMİ
**Model:** `lib/models/player_rank.dart`

#### 5 Lig
```
Bronze:   Seviye 1-20
Silver:   Seviye 21-40
Gold:     Seviye 41-60
Platinum: Seviye 61-80
Diamond:  Seviye 81-100
```

#### Seviye Değişim Algoritması
**25 oyunluk değerlendirme periyotları:**
- Kazanma oranı ≥75%: +2 seviye
- Kazanma oranı 60-74%: +1 seviye
- Kazanma oranı 40-59%: Değişim yok
- Kazanma oranı 25-39%: -1 seviye
- Kazanma oranı <25%: -2 seviye

---

### 6. BAŞARIMLAR VE ROZETLER
**Ekran:** `lib/screens/achievements_screen.dart`
**Servis:** `lib/services/achievement_service.dart`

#### Kategoriler
- 🎮 **Games:** İlk zafer, hızlı oyuncu, mükemmeliyetçi
- 🔥 **Streaks:** Sıcak seri, durdurulamaz, günlük rutin
- 🎯 **Challenges:** Meydan okuma ustası, uzman challenger
- 👥 **Social:** Arkadaş canlısı, rövanş kralı
- 📊 **Stats:** Yüzlük, veteran, şampiyon

#### Nadir Seviyeleri
`Common → Epic → Legendary`

**Ödül sistemi:** Her başarım coin verir

---

### 7. MAĞAZA SİSTEMİ
**Ekran:** `lib/screens/shop_screen.dart`
**Servis:** `lib/services/iap_service.dart`

#### Kategoriler
1. **Temalar** (10 adet + dark mode varyantları)
2. **Güç arttırıcılar** (power-ups)
3. **Coin paketleri** (IAP ile satın alma)

#### Tema Listesi
```
1. Default (Klasik Mavi)
2. Ocean (Soft Teal)
3. Sunset (Sıcak Coral)
4. Forest (Doğal Yeşil)
5. Galaxy (Derin Mor)
6. Midnight (Koyu Mavi)
7. Rose (Soft Pembe)
8. Lavender (Açık Mor)
9. Earth (Kahverengi/Taupe)
10. Mint (Taze Nane Yeşili)
```

**IAP Entegrasyonu:** `in_app_purchase: ^3.2.0`

---

## MİMARİ VE STATE MANAGEMENT

### 1. State Management Pattern
**Kullanılan Yaklaşım:** Provider-benzeri pattern + Manuel notifiers

```dart
// main.dart içinde
final themeNotifier = ThemeNotifier(); // ChangeNotifier
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
```

**Global State Yönetimi:**
- `ThemeNotifier` (dark/light mod)
- `GlobalInviteNotifier` (StreamController ile davet bildirimleri)
- Singleton servisler (business logic)

---

### 2. Singleton Pattern (22 Servis)

Tüm servisler Singleton pattern kullanır:

```dart
class GameInviteService {
  static final GameInviteService _instance = GameInviteService._internal();
  factory GameInviteService() => _instance;
  GameInviteService._internal();

  // Servis metodları...
}
```

**Servis Listesi:**
1. `achievement_service.dart` - Başarım takibi
2. `badge_service.dart` - Rozet yönetimi
3. `currency_service.dart` - Coin/token ekonomisi
4. `daily_challenge_service.dart` - Günlük puzzles
5. `daily_reward_service.dart` - Giriş ödülleri
6. `difficulty_calculator.dart` - Puzzle zorluğu
7. `friend_service.dart` - Sosyal bağlantılar
8. `game_invite_service.dart` - Çok oyunculu davetler
9. `haptic_service.dart` - Titreşim feedback
10. `hint_service.dart` - Oyun ipuçları
11. `iap_service.dart` - Uygulama içi satın almalar
12. `invite_cooldown_service.dart` - Spam önleme
13. `leaderboard_service.dart` - Sıralamalara ve istatistikler
14. `matchmaking_service.dart` - Rakip eşleştirme
15. `multiplayer_game_service.dart` - Oyun durumu yönetimi
16. `powerup_service.dart` - Güç arttırıcı sistemi
17. `progression_service.dart` - Seviye kilitleri
18. `recent_players_service.dart` - Oyuncu geçmişi
19. `sound_service.dart` - Ses oynatma
20. `theme_service.dart` - UI tema yönetimi
21. `user_status_service.dart` - Oyuncu durumu
22. `win_streak_service.dart` - Seri takibi

---

### 3. Firebase Entegrasyon Paterni

#### Gerçek Zamanlı Dinleyiciler
```dart
_gameSubscription = _database
  .child('games/$gameId')
  .onValue
  .listen((event) {
    // Gerçek zamanlı güncellemeleri işle
  });
```

#### Atomik İşlemler için Transaction Kullanımı
```dart
final transactionResult = await opponentRef.runTransaction((currentData) {
  // Race condition önleme
  if (data['matched'] == true) {
    return Transaction.abort();
  }
  data['matched'] = true;
  return Transaction.success(data);
});
```

---

## FİREBASE ENTEGRASYONU

### 1. Firebase Servisleri

**Firebase Authentication:**
```dart
FirebaseAuth.instance
- Google Sign-In (google_sign_in: ^6.2.2)
- Auth state değişiklikleri
```

**Firebase Realtime Database:**
```yaml
URL: https://multiplayer-sudoku-v1-default-rtdb.europe-west1.firebasedatabase.app
Region: Europe West 1
```

---

### 2. Veritabanı Yapısı

```
firebase_database/
├── users/{uid}/
│   ├── nickname                    # Kullanıcı adı
│   ├── profile/
│   │   ├── avatar
│   │   ├── selectedBadge
│   │   ├── currentTheme
│   │   └── coins, tokens
│   ├── rank/
│   │   ├── level                   # 1-100
│   │   ├── league                  # bronze/silver/gold/platinum/diamond
│   │   ├── gamesPlayed
│   │   ├── wins, losses
│   │   ├── winRate
│   │   ├── currentStreak, bestStreak
│   │   ├── periodGames             # 0-25
│   │   └── periodWins
│   ├── friends/{friendUid}/
│   ├── friendRequests/{requestId}/
│   ├── achievements/{achievementId}/
│   ├── stats/{gameMode}/
│   │   ├── gamesPlayed
│   │   ├── wins, losses
│   │   ├── averageTime
│   │   └── bestTime
│   ├── recent_players/{uid}/
│   ├── isOnline                    # boolean
│   └── lastSeen                    # timestamp
│
├── games/{gameId}/
│   ├── solution                    # 9x9 çözüm
│   ├── board                       # Classic mode
│   ├── player1Board, player2Board  # Race mode
│   ├── player1Uid, player2Uid
│   ├── player1Score, player2Score
│   ├── player1Errors, player2Errors
│   ├── player1Progress, player2Progress  # Race mode
│   ├── currentTurn                 # 1 veya 2 (Classic mode)
│   ├── status                      # active/finished
│   ├── gameMode                    # 'classic' veya 'race'
│   ├── difficulty
│   ├── createdAt, updatedAt
│   └── winner                      # uid
│
├── game_invites/{inviteId}/
│   ├── fromUid, toUid
│   ├── fromNickname, toNickname
│   ├── difficulty
│   ├── gameMode                    # 'classic' veya 'race'
│   ├── status                      # pending/accepted/rejected/expired
│   ├── gameId                      # Kabul edildikten sonra
│   ├── isRevanche                  # boolean
│   ├── timestamp
│   └── expiresAt                   # 30 saniye
│
├── matchmaking/{league}/{uid}/
│   ├── uid
│   ├── difficulty
│   ├── gameMode
│   ├── level
│   ├── matched                     # boolean
│   ├── gameId                      # Eşleşme sonrası
│   └── timestamp
│
├── leaderboard/
│   ├── multiplayer/{uid}/
│   │   ├── level
│   │   ├── league
│   │   ├── totalScore
│   │   ├── winRate
│   │   └── nickname
│   ├── daily/{date}/{uid}/
│   └── weekly/{week}/{uid}/
│
├── nicknames/{nickname} → uid      # Benzersiz nickname kontrolü
│
└── presence/{uid}/
    ├── isOnline
    └── lastSeen
```

---

### 3. Güvenlik Kuralları
**Dosya:** `database.rules.json`

#### Index Optimizasyonları
```json
{
  "matchmaking": {
    ".indexOn": ["difficulty", "timestamp", "matched", "gameMode", "level"]
  },
  "leaderboard": {
    ".indexOn": ["level", "totalScore", "winRate"]
  },
  "game_invites": {
    ".indexOn": ["fromUid", "toUid", "status"]
  }
}
```

**Güvenlik:**
- Auth zorunlu okuma/yazma
- Kullanıcılar sadece kendi verilerini düzenleyebilir
- Nickname benzersizliği zorunlu

---

### 4. Presence & Online Status

```dart
// Login'de online yap
await _ref.child('users/$uid').update({
  'isOnline': true,
  'lastSeen': ServerValue.timestamp,
});

// Disconnect handlers
_ref.child('users/$uid/isOnline').onDisconnect().set(false);
_ref.child('users/$uid/lastSeen').onDisconnect().set(ServerValue.timestamp);

// Periyodik heartbeat (30 saniyede bir)
_presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
  _ref.child('users/$uid/lastSeen').set(ServerValue.timestamp);
});
```

---

## EKRANLAR

### 20 Ekran Detayları

| # | Ekran | Dosya | Amaç |
|---|-------|-------|------|
| 1 | Splash | `splash_screen.dart` | Uygulama başlatma, Firebase init |
| 2 | Login | `login_screen.dart` | Google Sign-In |
| 3 | Home | `home_screen.dart` | Ana menü, mod seçimi |
| 4 | Game | `game_screen.dart` | **TEK OYUNCULU MOD** |
| 5 | Online Game | `online_game_screen.dart` | **ÇOK OYUNCULU MOD** |
| 6 | Lobby | `lobby_screen.dart` | Matchmaking, rakip arama |
| 7 | Friends | `friends_screen.dart` | Arkadaş listesi, davetler |
| 8 | Daily Challenge | `daily_challenge_screen.dart` | Günlük puzzle, takvim |
| 9 | Profile | `profile_screen.dart` | Kullanıcı profili, avatar, nickname |
| 10 | Leaderboard | `leaderboard_screen.dart` | Sıralamalar (günlük/haftalık/tüm zamanlar) |
| 11 | Statistics | `statistics_screen.dart` | Performans grafikleri |
| 12 | Achievements | `achievements_screen.dart` | Başarımlar, rozetler |
| 13 | Shop | `shop_screen.dart` | Mağaza (temalar, güç arttırıcılar) |
| 14 | Coin Purchase | `coin_purchase_screen.dart` | IAP coin paketleri |
| 15 | Coin Flip | `coin_flip_screen.dart` | Bonus coin mini oyunu |
| 16 | Settings | `settings_screen.dart` | Ayarlar menüsü |
| 17 | System Settings | `system_settings_screen.dart` | Ses, titreşim, dark mode |
| 18 | Theme Selector | `theme_selector_screen.dart` | Tema seçimi |
| 19 | Badge Selector | `badge_selector_screen.dart` | Rozet showcase |
| 20 | Help | *(varsa)* | Yardım ve SSS |

---

## SERVİSLER

### Servis Kategorileri

#### 1. Oyun Mekanik Servisleri
- `difficulty_calculator.dart` - Puzzle zorluğu hesaplama
- `hint_service.dart` - İpucu sistemi
- `powerup_service.dart` - Güç arttırıcılar
- `progression_service.dart` - Seviye kilitleri ve açma

#### 2. Çok Oyunculu Servisleri
- `matchmaking_service.dart` - Lig bazlı eşleştirme
- `multiplayer_game_service.dart` - Oyun durumu yönetimi
- `game_invite_service.dart` - Davet sistemi
- `friend_service.dart` - Arkadaş yönetimi
- `recent_players_service.dart` - Son oyuncular

#### 3. Progression & Ödüller
- `achievement_service.dart` - Başarım kilitleri
- `badge_service.dart` - Rozet sistemi
- `daily_challenge_service.dart` - Günlük puzzle
- `daily_reward_service.dart` - Giriş bonusları
- `win_streak_service.dart` - Seri takibi

#### 4. Ekonomi Servisleri
- `currency_service.dart` - Coin/token yönetimi
- `iap_service.dart` - Uygulama içi satın almalar

#### 5. UI & UX Servisleri
- `sound_service.dart` - Ses efektleri
- `haptic_service.dart` - Titreşim feedback
- `theme_service.dart` - Tema yönetimi

#### 6. Sosyal & İstatistik Servisleri
- `leaderboard_service.dart` - Sıralama sistemi
- `user_status_service.dart` - Online/offline durumu

#### 7. Yardımcı Servisler
- `invite_cooldown_service.dart` - Spam önleme

---

## OYUN MANTIĞI

### 1. Sudoku Puzzle Üretimi

**Algoritma:** Backtracking ile çözüm üretimi

```dart
void _initGame() {
  // 1. Tam çözümü oluştur (backtracking)
  _generateSolution(0, 0);

  // 2. Zorluğa göre hücreleri kaldır
  int cellsToRemove = _getEmptyCells(); // 37-64 arası

  // 3. Orijinal hücreleri işaretle (düzenlenemez)
  isOriginal[row][col] = board[row][col] != 0;

  // 4. Notlar grid'ini başlat
  notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
}

bool _generateSolution(int row, int col) {
  if (row == 9) return true;
  if (col == 9) return _generateSolution(row + 1, 0);

  List<int> numbers = [1,2,3,4,5,6,7,8,9]..shuffle(_puzzleRandom);
  for (int num in numbers) {
    if (_isValidPlacement(solution, row, col, num)) {
      solution[row][col] = num;
      if (_generateSolution(row, col + 1)) return true;
      solution[row][col] = 0;
    }
  }
  return false;
}
```

**Validasyon:**
```dart
bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
  // Satır kontrolü
  for (int i = 0; i < 9; i++) {
    if (grid[row][i] == num) return false;
  }

  // Sütun kontrolü
  for (int i = 0; i < 9; i++) {
    if (grid[i][col] == num) return false;
  }

  // 3x3 kutu kontrolü
  int boxRow = (row ~/ 3) * 3;
  int boxCol = (col ~/ 3) * 3;
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      if (grid[boxRow + i][boxCol + j] == num) return false;
    }
  }

  return true;
}
```

---

### 2. Puanlama Sistemi

#### Tek Oyunculu
```dart
int baseScore = 10; // Her doğru hamle

// Bonuslar
int firstMoveBonus = 10;       // İlk hamle bonusu
int speedBonus = 50;           // 10 saniyeden hızlı
int comboBonus = 5 * comboLevel; // 3+ ardışık doğru
int completionBonus = 50;      // Satır/sütun/kutu tamamlama
```

#### Çok Oyunculu
**Classic Mode:**
```dart
scoreGain = baseScore + (newCombo * comboMultiplier);
// Yanlış hamle yapan sırayı kaybeder
```

**Race Mode:**
```dart
// Kazanan = İlk bitiren
// Puan yok, sadece tamamlama yarışı
```

---

### 3. Günlük Meydan Okuma Algoritması

**Deterministik Seed:**
```dart
static int getTodaySeed() {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
}

// Örnek: 2026-01-13 → 20260113
```

**Zorluk Rotasyonu:**
```dart
static String getTodayDifficulty() {
  final dayOfYear = DateTime.now()
    .difference(DateTime(DateTime.now().year, 1, 1))
    .inDays;

  final difficulties = ['Kolay', 'Orta', 'Zor', 'Uzman'];
  return difficulties[dayOfYear % difficulties.length];
}
```

**Sonuç:** Tüm oyuncular aynı puzzle'ı çözer, sonuçlar karşılaştırılabilir.

---

## MULTIPLAYER SİSTEMİ

### 1. Matchmaking Süreci

**Dosya:** `lib/services/matchmaking_service.dart`

#### Adım 1: Kuyruğa Girme
```dart
await _ref.child('matchmaking/$_myLeague/$_myQueueKey').set({
  'uid': uid,
  'level': myLevel,
  'difficulty': difficulty,
  'gameMode': gameMode,
  'matched': false,
  'timestamp': ServerValue.timestamp,
});
```

#### Adım 2: Genişleyen Arama Yarıçapı
```
0-30 saniye:  Sadece kendi ligin
30-60 saniye: ±1 lig
60-90 saniye: ±2 lig
```

#### Adım 3: Atomik Eşleştirme
```dart
final transactionResult = await opponentRef.runTransaction((currentData) {
  if (data['matched'] == true) {
    return Transaction.abort(); // Başkası çoktan aldı
  }
  data['matched'] = true;
  return Transaction.success(data);
});
```

**Eşleşme Kriterleri:**
- Aynı zorluk seviyesi
- Aynı oyun modu (classic/race)
- ±15 seviye farkı
- Lig yakınlığı (bekleme süresiyle genişler)

---

### 2. Classic Mode (Sıra Tabanlı)

**Tur Yönetimi:**
```dart
// 30 saniyelik tur zamanlayıcı
_turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() => turnTimeRemaining--);
  if (turnTimeRemaining <= 0) {
    _handleTurnTimeout(); // Otomatik sıra geçişi
  }
});
```

**Sıra Değiştirme:**
```dart
// Yanlış hamle yapan sırayı kaybeder
if (!isCorrect && gameMode == 'classic') {
  updates['currentTurn'] = widget.isPlayer1 ? 2 : 1;
  await _database.child('games/${widget.gameId}').update(updates);
}
```

**Kazanan Belirleme:**
```dart
if (totalEmptyCells == 0) {
  String winner = player1Score > player2Score ? player1Uid : player2Uid;
  await _database.child('games/$gameId').update({
    'status': 'finished',
    'winner': winner,
  });
}
```

---

### 3. Race Mode (Eş Zamanlı)

**Ayrı Tahtalar:**
```dart
gameData['player1Board'] = puzzleData['board'];
gameData['player2Board'] = puzzleData['board'];
gameData['player1Progress'] = 0; // Dolu hücre sayısı
gameData['player2Progress'] = 0;
```

**İlerleme Takibi:**
```dart
// %70'e ulaşınca rakip uyarısı
int warningThreshold = (totalEmptyCells * 0.7).toInt();
if (opponentProgress >= warningThreshold && !_showOpponentWarning) {
  setState(() => _showOpponentWarning = true);
  _vibrateHeavy();
}
```

**İlerleme Çubuğu:**
```dart
LinearProgressIndicator(
  value: opponentProgress / totalEmptyCells,
  backgroundColor: Colors.grey[800],
  color: _showOpponentWarning ? Colors.red : Colors.blue,
)
```

**Kazanan Belirleme:**
```dart
if (myProgress >= totalEmptyCells) {
  await _database.child('games/$gameId').update({
    'status': 'finished',
    'winner': myUid,
  });
}
```

---

### 4. Gerçek Zamanlı Senkronizasyon

```dart
_gameSubscription = _database
  .child('games/${widget.gameId}')
  .onValue
  .listen((event) {
    final data = event.snapshot.value as Map?;
    if (data == null) return;

    setState(() {
      // Classic mode
      if (gameMode == 'classic') {
        board = List<List<int>>.from(
          (data['board'] as List).map((row) =>
            List<int>.from(row as List)
          )
        );
        currentTurn = data['currentTurn'] ?? 1;
      }

      // Race mode
      else {
        opponentProgress = data['player${widget.isPlayer1 ? 2 : 1}Progress'] ?? 0;
      }

      // Ortak
      player1Score = data['player1Score'] ?? 0;
      player2Score = data['player2Score'] ?? 0;
      status = data['status'] ?? 'active';
    });
  });
```

---

## KRİTİK ÖZELLİKLER

### 1. Global Davet Notification Sistemi

**Pattern:** Singleton StreamController + Overlay Widget

#### GlobalInviteNotifier
```dart
class GlobalInviteNotifier {
  static final GlobalInviteNotifier _instance = GlobalInviteNotifier._internal();
  factory GlobalInviteNotifier() => _instance;
  GlobalInviteNotifier._internal();

  final _inviteController = StreamController<GameInvite>.broadcast();
  Stream<GameInvite> get onInviteReceived => _inviteController.stream;

  void notify(GameInvite invite) {
    _inviteController.add(invite);
  }
}
```

#### Global Overlay (main.dart)
```dart
MaterialApp(
  navigatorKey: navigatorKey,
  home: GlobalInviteOverlay(
    onAccept: _handleInviteAccept,
    onReject: _handleInviteReject,
    child: SplashScreen(),
  ),
)
```

**Neden Önemli:**
- Kullanıcı hangi ekranda olursa olsun davet bildirimi görür
- Context'e ihtiyaç duymadan global erişim
- StreamController ile reaktif bildirimler

---

### 2. Progressif Kilit Açma Sistemi

**Dosya:** `lib/services/progression_service.dart`

```dart
static const Map<String, Map<String, dynamic>> UNLOCK_REQUIREMENTS = {
  'Orta': {'previousLevel': 'Kolay', 'requiredWins': 2},
  'Zor': {'previousLevel': 'Orta', 'requiredWins': 3},
  'Uzman': {'previousLevel': 'Zor', 'requiredWins': 5},
  'Usta': {'previousLevel': 'Uzman', 'requiredWins': 5},
  'Ekstrem': {'previousLevel': 'Usta', 'requiredWins': 5},
};

static Future<bool> isLocked(String difficulty) async {
  final unlockInfo = UNLOCK_REQUIREMENTS[difficulty];
  if (unlockInfo == null) return false; // Kolay her zaman açık

  final previousWins = await getWins(unlockInfo['previousLevel']);
  return previousWins < unlockInfo['requiredWins'];
}
```

**Kullanım:**
```dart
// Home screen'de
bool isLocked = await ProgressionService.isLocked('Uzman');
if (isLocked) {
  // Kilit simgesi göster
  // Tıklanınca gereksinim mesajı göster
}
```

---

### 3. Tema Sistemi

**Dosya:** `lib/services/theme_service.dart`

#### 10 Tema + Dark Mode Varyantları
Her tema için light ve dark varyant mevcut = **20 görsel stil**

```dart
static GameTheme getTheme(String id, bool isDark) {
  // Her tema hem light hem dark varyanta sahip
  final themes = {
    'default': isDark ? _defaultDark : _defaultLight,
    'ocean': isDark ? _oceanDark : _oceanLight,
    'sunset': isDark ? _sunsetDark : _sunsetLight,
    // ... 10 tema
  };
  return themes[id] ?? themes['default']!;
}
```

**GameTheme Yapısı:**
```dart
class GameTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color cellColor;
  final Color selectedCellColor;
  final Color fixedNumberColor;
  final Color userNumberColor;
  final Color errorColor;
  final Color highlightColor;
  final Color gridLineColor;
  final Color boxBorderColor;
}
```

---

### 4. Başarım Sistemi

**Dosya:** `lib/services/achievement_service.dart`

#### Başarım Yapısı
```dart
class Achievement {
  final String id;
  final String title;          // Başarım adı
  final String description;    // Açıklama
  final String category;       // Games/Streaks/Challenges/Social/Stats
  final String rarity;         // Common/Epic/Legendary
  final String icon;           // Emoji
  final int points;            // Coin ödülü
  final int progressMax;       // Hedef (örn: 10 oyun)
}
```

#### Otomatik Kilitleme
```dart
static Future<void> checkAndUnlock(String achievementId) async {
  final achievement = achievements.firstWhere((a) => a.id == achievementId);
  final prefs = await SharedPreferences.getInstance();

  int currentProgress = prefs.getInt('achievement_$achievementId') ?? 0;
  currentProgress++;
  await prefs.setInt('achievement_$achievementId', currentProgress);

  if (currentProgress >= achievement.progressMax) {
    // Kilidi aç
    await _unlockAchievement(achievementId);

    // Coin ödülü ver
    await CurrencyService().addCoins(achievement.points);

    // Bildirim göster
    _showAchievementDialog(achievement);
  }
}
```

---

### 5. Lokalizasyon (i18n)

**Dosya:** `lib/app_localizations.dart`

#### Desteklenen Diller
- 🇹🇷 Türkçe (varsayılan)
- 🇬🇧 İngilizce

#### Kullanım
```dart
// Kısa yol helper
String tr(String key) => AppLocalizations.get(key);

// Kullanım örnekleri
Text(tr('singlePlayer'))       // "Tek Oyunculu" / "Single Player"
Text(tr('multiPlayer'))        // "Çok Oyunculu" / "Multiplayer"
Text(tr('dailyChallenge'))     // "Günlük Meydan Okuma" / "Daily Challenge"
```

#### Dil Değiştirme
```dart
static Future<void> setLanguage(String langCode) async {
  _currentLanguage = langCode; // 'tr' veya 'en'
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', langCode);
}
```

**Çeviri Sözlüğü:** 100+ key-value çifti içerir

---

### 6. Ses ve Titreşim Sistemi

#### Sound Service
**Dosya:** `lib/services/sound_service.dart`

```dart
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  void playButtonClick() => _play('assets/sounds/button_click.mp3');
  void playMove() => _play('assets/sounds/move.mp3');
  void playWin() => _play('assets/sounds/win.mp3');
  void playError() => _play('assets/sounds/error.mp3');
  void playLose() => _play('assets/sounds/lose.mp3');
}
```

#### Haptic Service
**Dosya:** `lib/services/haptic_service.dart`

```dart
class HapticService {
  bool _enabled = true;

  void lightImpact() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    if (_enabled) HapticFeedback.heavyImpact();
  }
}
```

**Kullanım Senaryoları:**
- `lightImpact()`: Buton tıklamaları
- `mediumImpact()`: Doğru hamle
- `heavyImpact()`: Hata, uyarı, oyun sonu

---

### 7. Presence & Online Status

**Dosya:** `lib/services/user_status_service.dart`

#### Online Durumu
```dart
Future<void> setOnline(String uid) async {
  await _ref.child('users/$uid').update({
    'isOnline': true,
    'lastSeen': ServerValue.timestamp,
  });

  // Disconnect handlers (kullanıcı uygulamayı kapatırsa)
  _ref.child('users/$uid/isOnline').onDisconnect().set(false);
  _ref.child('users/$uid/lastSeen').onDisconnect().set(ServerValue.timestamp);
}
```

#### Periyodik Heartbeat
```dart
// 30 saniyede bir lastSeen güncelle
_presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
  _ref.child('users/$uid/lastSeen').set(ServerValue.timestamp);
});
```

#### Arkadaş Listesinde Görüntüleme
```dart
// friends_screen.dart içinde
Text(
  friend['isOnline'] == true
    ? '🟢 Çevrimiçi'
    : '⚫ ${_formatLastSeen(friend['lastSeen'])}'
)
```

---

### 8. IAP (In-App Purchase) Sistemi

**Dosya:** `lib/services/iap_service.dart`

#### Ürün Tanımları
```dart
static const List<String> _productIds = [
  'coins_100',     // 100 Coin - $0.99
  'coins_500',     // 500 Coin - $3.99
  'coins_1200',    // 1200 Coin - $7.99
  'coins_2500',    // 2500 Coin - $14.99
  'coins_6000',    // 6000 Coin - $29.99
];
```

#### Satın Alma Akışı
```dart
Future<bool> buyProduct(String productId) async {
  final ProductDetailsResponse response =
    await _iap.queryProductDetails(_productIds.toSet());

  final product = response.productDetails
    .firstWhere((p) => p.id == productId);

  final PurchaseParam purchaseParam = PurchaseParam(
    productDetails: product,
  );

  return await _iap.buyConsumable(
    purchaseParam: purchaseParam,
  );
}
```

#### Satın Alma Doğrulama
```dart
void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
  for (var purchaseDetails in purchaseDetailsList) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      _deliverProduct(purchaseDetails);
    }
  }
}
```

---

## ÖNEMLİ NOTLAR

### 1. Güvenlik
- ✅ Firebase güvenlik kuralları yapılandırılmış
- ✅ Auth zorunlu okuma/yazma
- ✅ Kullanıcılar sadece kendi verilerini düzenleyebilir
- ✅ Transaction kullanımı ile race condition önleme
- ⚠️ IAP server-side doğrulaması eksik (production için gerekli)

### 2. Performance
- ✅ Firebase indexleme yapılandırılmış
- ✅ Veritabanı sorgularında limit kullanımı
- ✅ Gereksiz listener'lar temizleniyor (`_gameSubscription?.cancel()`)
- ⚠️ Büyük liste renderlamaları için ListView.builder kullanılmalı

### 3. Code Quality
- ✅ Clean architecture (screens/services/models ayrımı)
- ✅ Singleton pattern tutarlı kullanımı
- ✅ Kod tekrarı minimal
- ⚠️ Bazı dosyalarda uzun fonksiyonlar var (refactor edilebilir)

### 4. Gelecek Geliştirmeler

- [ ] Server-side IAP doğrulaması
- [ ] Profil resmi yükleme (Firebase Storage)
- [ ] Turnuva sistemi
- [ ] Arkadaş chat sistemi
- [ ] Push notification entegrasyonu
- [ ] Analytics (Firebase Analytics)

---

## ÖZET

**Sudoku Clash**, production-ready seviyesinde bir multiplayer Sudoku oyunudur.

### Güçlü Yönler
✅ Kapsamlı multiplayer (Classic ve Race modları)
✅ Sosyal özellikler (arkadaşlar, davetler)
✅ Progression sistemleri (seviyeler, ligler, başarımlar)
✅ Günlük meydan okuma (deterministik puzzles)
✅ Monetization hazır (IAP, mağaza, currency)
✅ Cilalı UX (dark mode, 10 tema, ses/titreşim, i18n)
✅ Sağlam matchmaking (lig bazlı, atomik transactions)
✅ İnovatif global notification sistemi

### Teknik Stack
- Flutter 3.5.0+
- Firebase (Auth, Realtime Database)
- Dart service-based architecture
- Singleton pattern
- Real-time multiplayer

### Kod Kalitesi
- Clean architecture
- Proper error handling
- Extensive logging
- Security rules configured
- Internationalization support

**Bu proje, enterprise-level mimari ve kapsamlı feature set'e sahip production-ready bir oyundur.**

---

*Son Güncelleme: 13 Ocak 2026*

# 🚀 SUDOKU CLASH - DEPLOYMENT GUIDE

**Version:** 1.0.0
**Last Updated:** 2026-01-11
**Status:** Production Ready ✅

---

## 📋 TABLE OF CONTENTS

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Firebase Configuration](#firebase-configuration)
4. [Google Play Console Setup](#google-play-console-setup)
5. [Apple App Store Setup](#apple-app-store-setup)
6. [In-App Purchase Configuration](#in-app-purchase-configuration)
7. [Building for Production](#building-for-production)
8. [Testing Checklist](#testing-checklist)
9. [Post-Launch Tasks](#post-launch-tasks)
10. [Troubleshooting](#troubleshooting)

---

## 🎮 PROJECT OVERVIEW

**Sudoku Clash** is a competitive multiplayer Sudoku game with:

### Core Features:
- ✅ **Multiplayer System** - Real-time matchmaking & gameplay
- ✅ **Game Modes** - Classic, Race, Time Attack
- ✅ **Progression System** - XP, levels, achievements
- ✅ **Social Features** - Friends, recent players, leaderboards
- ✅ **Shop System** - Themes, avatars, power-ups, badges
- ✅ **In-App Purchases** - Coin packages (4 tiers)
- ✅ **Daily Engagement** - Daily rewards, challenges, win streaks
- ✅ **Achievements** - 13 unique achievements with rewards
- ✅ **Power-ups** - 2x Score, Auto-Check, Time Freeze
- ✅ **Customization** - 6 themes, 21 avatars, 4 badges

### Tech Stack:
- **Framework:** Flutter 3.5+
- **Backend:** Firebase Realtime Database + Firebase Auth
- **Authentication:** Google Sign-In, Guest Login
- **Payments:** Google Play Billing + Apple StoreKit
- **Languages:** Turkish (primary), English

---

## 📦 PREREQUISITES

### Development Environment:
```bash
# Check Flutter installation
flutter doctor

# Required:
✅ Flutter SDK 3.5.0+
✅ Dart SDK 3.5.0+
✅ Android Studio / VS Code
✅ Xcode (for iOS)
✅ CocoaPods (for iOS)
```

### Required Accounts:
- ✅ Firebase Project (already configured)
- ⏳ Google Play Console Developer Account ($25 one-time)
- ⏳ Apple Developer Program ($99/year) - for iOS
- ⏳ Google Cloud Project (for IAP verification)

### Dependencies Check:
```bash
cd test_sudoku
flutter pub get
flutter pub outdated  # Check for updates
```

---

## 🔥 FIREBASE CONFIGURATION

### Current Status: ✅ CONFIGURED

Firebase is already set up with:
- Firebase Auth (Google Sign-In + Anonymous)
- Firebase Realtime Database
- Security rules implemented

### Verify Firebase Setup:
```bash
# Check Firebase files
ls android/app/google-services.json  # ✅ Should exist
ls ios/Runner/GoogleService-Info.plist  # ✅ Should exist (iOS)

# Verify Firebase rules
cat database.rules.json
```

### Firebase Console Checklist:
1. **Authentication**
   - ✅ Enable Google Sign-In provider
   - ✅ Enable Anonymous Sign-In
   - ✅ Add SHA-1 fingerprint for Android

2. **Realtime Database**
   - ✅ Deploy security rules from `database.rules.json`
   - ✅ Set up backup schedule (recommended)
   - ✅ Monitor usage quotas

3. **Get SHA-1 Fingerprint:**
```bash
cd android
./gradlew signingReport

# For release build:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 🤖 GOOGLE PLAY CONSOLE SETUP

### Step 1: Create App Listing

1. **Go to:** https://play.google.com/console
2. **Create New App:**
   - App Name: **Sudoku Clash**
   - Default Language: Turkish
   - App/Game: Game
   - Free/Paid: Free (with IAP)

3. **Store Listing:**
   ```
   Short Description (80 chars):
   Rekabetçi çok oyunculu Sudoku! Arkadaşlarınla yarış, skor kazan! 🎮

   Full Description:
   🎮 SUDOKU CLASH - Yeni Nesil Sudoku Oyunu!

   Sudoku'yu daha önce hiç böyle oynamadın! Dünya çapında oyuncularla
   gerçek zamanlı karşılaşmalarda yarış, arkadaşlarını davet et,
   liderlik tablosunda zirveye tırman!

   🏆 ÖZELLİKLER:
   ✅ Çok Oyunculu Modu - Gerçek zamanlı karşılaşmalar
   ✅ 3 Oyun Modu - Klasik, Yarış, Zaman Saldırısı
   ✅ Günlük Ödüller - Her gün giriş yap, jeton kazan
   ✅ Başarımlar - 13 benzersiz başarım
   ✅ Temalar - 6 farklı görsel tema
   ✅ Liderlik Tablosu - Dünya sıralaması
   ✅ Arkadaş Sistemi - Arkadaşlarını ekle, davet et
   ✅ Güç Artırıcılar - Oyun içi avantajlar

   Şimdi indir, sudoku deneyimini yeniden keşfet! 🚀
   ```

4. **Screenshots Required:**
   - Phone: 2-8 screenshots (1080x1920 or 1080x2340)
   - 7-inch Tablet: Optional
   - 10-inch Tablet: Optional
   - Feature Graphic: 1024x500 (required)
   - App Icon: 512x512 (already in project)

### Step 2: App Content

1. **Content Rating:**
   - Fill questionnaire
   - Expected: PEGI 3, ESRB Everyone

2. **Target Audience:**
   - Age: 13+ (recommended for multiplayer)

3. **Privacy Policy:**
   - Required (provide URL or upload)
   - Template provided below

4. **Data Safety:**
   - Declare: User accounts, gameplay data, in-app purchases
   - Data encryption: Yes (Firebase)
   - Data deletion: Contact developer

### Step 3: App Signing

**Use Google Play App Signing (Recommended):**
```bash
# Generate upload key
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000

# Create key.properties
echo "storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks" > android/key.properties
```

**Update `android/app/build.gradle.kts`:**
```kotlin
// Add before android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

// Inside android block
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

---

## 🍎 APPLE APP STORE SETUP

### Step 1: App Store Connect

1. **Create App:**
   - Name: Sudoku Clash
   - Bundle ID: com.sudokuclash.app (update in Xcode)
   - Primary Language: Turkish

2. **App Information:**
   - Subtitle: Rekabetçi Çok Oyunculu Sudoku
   - Category: Games > Puzzle

3. **Pricing:**
   - Free with In-App Purchases

### Step 2: Xcode Configuration

```bash
cd ios
open Runner.xcworkspace

# In Xcode:
# 1. Select Runner target
# 2. General > Identity
#    - Display Name: Sudoku Clash
#    - Bundle Identifier: com.sudokuclash.app
#    - Version: 1.0.0
#    - Build: 1
# 3. Signing & Capabilities
#    - Team: Select your Apple Developer team
#    - Automatically manage signing: ✅
```

### Step 3: Required Assets

- App Icon: 1024x1024 (place in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- Screenshots: iPhone 6.7", 6.5", 5.5" (required)
- Optional: iPad Pro 12.9", 12.9" 2nd gen

---

## 💰 IN-APP PURCHASE CONFIGURATION

### Product IDs (Already in Code):
```dart
// lib/services/iap_service.dart
1. sudoku_clash_coins_100   →  100 coins  → ₺9.99
2. sudoku_clash_coins_500   →  500 coins  → ₺39.99
3. sudoku_clash_coins_1200  → 1200 coins  → ₺69.99
4. sudoku_clash_coins_3000  → 3000 coins  → ₺149.99
```

### Google Play Console - In-App Products

1. **Navigate to:** Monetize > In-app products
2. **Create Managed Product** for each:

**Product 1:**
- Product ID: `sudoku_clash_coins_100`
- Name: 💎 Küçük Jeton Paketi
- Description: 100 Jeton - Temel güç artırıcılar ve temalar için!
- Price: ₺9.99 (adjust for all countries)
- Status: Active

**Product 2:**
- Product ID: `sudoku_clash_coins_500`
- Name: 💎 Orta Jeton Paketi
- Description: 500 Jeton (+20% bonus!) - Premium avatarlar ve daha fazlası!
- Price: ₺39.99
- Status: Active

**Product 3:**
- Product ID: `sudoku_clash_coins_1200`
- Name: 💎 Büyük Jeton Paketi
- Description: 1200 Jeton (+40% bonus!) - Tüm premium içeriklere erişim!
- Price: ₺69.99
- Status: Active

**Product 4:**
- Product ID: `sudoku_clash_coins_3000`
- Name: 💎 Dev Jeton Paketi
- Description: 3000 Jeton (+100% bonus!) - En iyi değer!
- Price: ₺149.99
- Status: Active

### App Store Connect - In-App Purchases

1. **Navigate to:** Features > In-App Purchases
2. **Create Consumable** for each (same IDs as Google Play)
3. **Pricing:** Match Google Play prices in TRY
4. **Metadata:** Same names/descriptions (Turkish)

### Testing IAP

**Android (Google Play):**
```bash
# 1. Add test accounts in Google Play Console
# 2. Build release APK
flutter build apk --release

# 3. Upload to Internal Testing track
# 4. Test with test account
```

**iOS (App Store):**
```bash
# 1. Add Sandbox testers in App Store Connect
# 2. Build for TestFlight
flutter build ios --release

# 3. Archive in Xcode
# 4. Upload to App Store Connect
# 5. Test via TestFlight
```

---

## 🏗️ BUILDING FOR PRODUCTION

### Android APK/AAB

```bash
# Clean build
flutter clean
flutter pub get

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# Build APK (for direct distribution)
flutter build apk --release --split-per-abi

# Outputs:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM - most common)
# - app-x86_64-release.apk (64-bit x86)
```

**Upload to Google Play:**
1. Go to Release > Production
2. Create new release
3. Upload AAB file
4. Fill release notes
5. Submit for review

### iOS IPA

```bash
# Clean build
flutter clean
cd ios && pod install && cd ..
flutter pub get

# Build iOS release
flutter build ios --release

# Archive in Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Product > Archive
# 3. Window > Organizer
# 4. Distribute App > App Store Connect
# 5. Upload
```

**Submit for Review:**
1. App Store Connect > TestFlight (optional testing)
2. App Store Connect > App Store > Submit for Review
3. Fill review information
4. Submit

---

## ✅ TESTING CHECKLIST

### Pre-Launch Testing

#### Authentication:
- [ ] Google Sign-In works
- [ ] Guest login works
- [ ] Profile data saves correctly
- [ ] Logout and re-login preserves data

#### Core Gameplay:
- [ ] Single player mode works
- [ ] Multiplayer matchmaking finds opponents
- [ ] Race mode timer works correctly
- [ ] Game completion awards points
- [ ] Leaderboard updates correctly

#### Shop & IAP:
- [ ] Shop displays all items correctly
- [ ] Coin purchase screen loads products
- [ ] Test purchase works (sandbox)
- [ ] Coins added to account after purchase
- [ ] Purchased items unlock correctly

#### Social Features:
- [ ] Friend requests send/accept
- [ ] Recent players list populates
- [ ] Leaderboard loads all players
- [ ] Badges display in leaderboard

#### Daily Features:
- [ ] Daily reward shows on first login
- [ ] Daily challenge updates daily
- [ ] Win streak tracks correctly
- [ ] Achievements unlock properly

#### Power-ups:
- [ ] 2x Score multiplier works
- [ ] Auto-Check finds errors
- [ ] Time Freeze pauses timer (Race mode)

#### UI/UX:
- [ ] All themes apply correctly
- [ ] Avatar selection saves
- [ ] Badge selection saves
- [ ] Settings toggles work (sound, vibration)
- [ ] Localization works (TR/EN)

#### Performance:
- [ ] App launches < 3 seconds
- [ ] No crashes during 30-min gameplay
- [ ] Memory usage stable
- [ ] Battery usage acceptable

---

## 📱 POST-LAUNCH TASKS

### Week 1:
- [ ] Monitor crash reports (Firebase Crashlytics recommended)
- [ ] Check IAP conversion rate
- [ ] Review user feedback
- [ ] Fix critical bugs (hotfix if needed)

### Week 2-4:
- [ ] Analyze retention metrics (Day 1, Day 7, Day 30)
- [ ] A/B test IAP pricing (if low conversion)
- [ ] Plan feature updates based on feedback
- [ ] Engage with community (reviews, social media)

### Monthly:
- [ ] Review Firebase costs
- [ ] Check leaderboard for cheaters
- [ ] Update content (new themes, avatars)
- [ ] Seasonal events (e.g., holiday themes)

---

## 🛠️ TROUBLESHOOTING

### Build Errors

**"Execution failed for task ':app:processReleaseGoogleServices'"**
- Solution: Check `google-services.json` exists in `android/app/`

**"CocoaPods not installed"**
```bash
sudo gem install cocoapods
cd ios && pod install
```

**"Flutter SDK not found"**
```bash
flutter doctor
flutter upgrade
```

### Runtime Errors

**"Firebase auth failed"**
- Check SHA-1 fingerprint in Firebase Console
- Verify `google-services.json` is up to date

**"IAP products not loading"**
- Wait 2-4 hours after creating products
- Check product IDs match exactly
- Test with signed release build, not debug

**"Matchmaking timeout"**
- Check Firebase Realtime Database rules
- Verify network connection
- Check Firebase usage quotas

### App Store Rejection Reasons

**"Missing privacy policy"**
- Add privacy policy URL in app listing

**"Kids Category - requires privacy policy"**
- Change age rating to 13+ or add policy

**"IAP testing required"**
- Provide test account credentials in review notes

---

## 📊 FIREBASE USAGE ESTIMATES

### Free Tier Limits (Spark Plan):
- Realtime Database: 1GB storage, 10GB/month download
- Authentication: Unlimited
- Estimated Users Supported: **~5,000 daily active users**

### Upgrade to Blaze (Pay-as-you-go):
- Cost: ~$0.10-0.50/day for 10K DAU
- Recommended when: >3,000 DAU consistently

---

## 🔒 SECURITY CHECKLIST

- [x] Firebase security rules implemented
- [ ] IAP server-side verification (optional but recommended)
- [x] User data encrypted in transit (HTTPS)
- [x] No API keys hardcoded in client
- [x] Rate limiting on sensitive operations

---

## 📞 SUPPORT & CONTACT

**Developer:** Gokhan
**Email:** [Your email]
**Firebase Project:** [Project ID]
**Repository:** Private

---

## 📝 PRIVACY POLICY (Template)

```markdown
# Sudoku Clash - Gizlilik Politikası

Son Güncelleme: 11 Ocak 2026

## Topladığımız Veriler
- Google hesap bilgisi (e-posta, isim, profil fotoğrafı)
- Oyun istatistikleri (skor, seviye, başarımlar)
- Cihaz bilgisi (model, işletim sistemi versiyonu)
- Satın alma geçmişi (anonim)

## Veri Kullanımı
Verileriniz sadece:
- Oyun deneyiminizi iyileştirmek
- Liderlik tablosunu güncellemek
- Teknik destek sağlamak
için kullanılır.

## Veri Paylaşımı
Verileriniz üçüncü taraflarla paylaşılmaz.
Firebase (Google) altyapısı kullanılarak güvenli şekilde saklanır.

## Veri Silme
Verilerinizi silmek için: [email]

## İletişim
Sorularınız için: [email]
```

---

## ✅ FINAL CHECKLIST BEFORE LAUNCH

- [ ] All features tested on real devices (Android + iOS)
- [ ] IAP tested with sandbox accounts
- [ ] Privacy policy uploaded
- [ ] Screenshots prepared (2 platforms, multiple sizes)
- [ ] App descriptions finalized (TR + EN)
- [ ] Firebase quotas checked
- [ ] Release notes written
- [ ] Support email configured
- [ ] App Store listings complete
- [ ] Promotional materials ready (optional)

---

**🎉 Tebrikler! Sudoku Clash'i yayınlamaya hazırsın!**

Good luck with your launch! 🚀

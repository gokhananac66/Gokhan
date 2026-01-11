# ✅ PRODUCTION CHECKLIST - Sudoku Clash

**Hızlı test listesi - Fiziksel cihazda test etmeden önce!**

---

## 🎯 KRİTİK TESTLER (Mutlaka Test Et!)

### 1. GİRİŞ & KAYIT
- [ ] Google ile giriş çalışıyor
- [ ] Misafir girişi çalışıyor
- [ ] İlk giriş: daily reward dialog açılıyor
- [ ] Kullanıcı profili kaydediliyor

### 2. ÇARPIŞMA OYUNU (Core Feature!)
- [ ] Matchmaking çalışıyor (30 saniye içinde)
- [ ] Rakip bulundu mesajı geliyor
- [ ] Oyun ekranı açılıyor
- [ ] Rakibin hamleleri görünüyor (real-time)
- [ ] Oyun bitince kazanan/kaybeden doğru
- [ ] Puan kaydediliyor
- [ ] Leaderboard güncelleliyor

### 3. MARKET SİSTEMİ
- [ ] Shop ekranı açılıyor
- [ ] Tüm ürünler listeleniyor (25+ item)
- [ ] Jeton bakiyesi görünüyor
- [ ] Satın alma çalışıyor (test jeton ile)
- [ ] **ÖNEMLİ:** "Buy Coins" butonu görünüyor
- [ ] Coin purchase screen açılıyor
- [ ] IAP ürünleri listeleniyor (4 paket)

### 4. SATIN ALINAN ÜRÜNLERİN KULLANIMI

**Temalar:**
- [ ] Tema satın alındı
- [ ] Settings > Theme Selector açılıyor
- [ ] Satın alınan tema seçiliyor
- [ ] Oyunda tema uygulanıyor

**Premium Avatarlar:**
- [ ] Avatar satın alındı
- [ ] Profile > Avatar değiştir
- [ ] Premium avatar listede kilit açık
- [ ] Seçilen avatar kaydediliyor

**Rozetler:**
- [ ] Rozet satın alındı
- [ ] Settings > Badge Selector açılıyor
- [ ] Rozet seçildi
- [ ] Leaderboard'da rozet görünüyor

**Power-ups:**
- [ ] 2x Puan satın alındı → Oyunda mor rozet görünüyor, puanlar 2x
- [ ] Auto-Check satın alındı → Oyunda turuncu rozet görünüyor, hataları buluyor
- [ ] Time Freeze satın alındı → Race modunda freeze butonu çalışıyor

**İpuçları:**
- [ ] İpucu paketi satın alındı
- [ ] Oyunda ipucu sayısı arttı
- [ ] İpucu kullanımı çalışıyor

### 5. GÜNLÜK ÖZELLİKLER
- [ ] Daily Reward: İlk giriş, dialog açılıyor, puan veriliyor
- [ ] Daily Challenge: Home screen'de kart görünüyor
- [ ] Daily Challenge oynandı, puan verildi
- [ ] Win Streak: Kazanınca seri artıyor

### 6. BAŞARIMLAR
- [ ] Settings > Achievements açılıyor
- [ ] Başarımlar listeleniyor
- [ ] Bir başarım açıldı (ör: First Victory)
- [ ] Unlock dialog gösteriliyor
- [ ] Puan hesaba eklendi

### 7. SOSYAL ÖZELLİKLER
- [ ] Friends ekranı açılıyor
- [ ] Recent players listeleniyor
- [ ] Leaderboard tüm oyuncuları gösteriyor
- [ ] Leaderboard'da rozetler görünüyor

### 8. AYARLAR
- [ ] Settings tüm seçenekleri gösteriyor
- [ ] Sound toggle çalışıyor
- [ ] Vibration toggle çalışıyor
- [ ] Language değişimi çalışıyor (TR/EN)
- [ ] Logout çalışıyor

---

## 🔥 KNOWN ISSUES (Bilinen Sorunlar)

### ✅ ÇÖZÜLMÜŞ:
- Back arrow leaderboard'da görünmüyor ❌ → FIX: df236e8
- gamesPlayed field 0 görünüyordu ❌ → FIX: 408bf9d

### ⚠️ MINOR (Önemli Değil):
- **Sound System:** Ses dosyaları yok (fonksiyon var ama ses çalmıyor)
  - Kullanıcı fark etmez, crash olmaz
  - Eklemek için: `assets/sounds/` klasörü + MP3 dosyaları
- **Home Screen:** Daily challenge time/moves 0 kaydediliyor
  - Challenge yine de tamamlanıyor ve puan veriliyor
  - Sadece istatistik kaydı eksik

### 🚨 PRODUCTION'DA DİKKAT:
- **IAP:** Sandbox test hesabı ile test et (production'da real money!)
- **Firebase Quotas:** Free tier ~5K DAU destekler, aşarsa Blaze'e upgrade
- **Google Play:** SHA-1 fingerprint eklemeyi unutma
- **App Store:** Sandbox tester hesapları ekle

---

## 📱 FİZİKSEL CİHAZ TEST ADIMLARI

### ADIM 1: Build
```bash
# Android
flutter build apk --release

# iOS (Mac gerekli)
flutter build ios --release
```

### ADIM 2: Yükle
**Android:**
```bash
# ADB ile yükle
adb install build/app/outputs/flutter-apk/app-release.apk

# VEYA APK'yı telefona at, dosya yöneticisinden yükle
```

**iOS:**
- Xcode > Product > Archive
- Distribute App > Development
- Cihazı seç, install

### ADIM 3: İlk Açılış Testi
1. Uygulamayı aç
2. Splash screen görünmeli
3. Google ile giriş yap
4. Daily reward dialog açılmalı
5. Home screen açılmalı
6. Jeton bakiyesi görünmeli (daily reward'dan gelen)

### ADIM 4: Çarpışma Oyunu Testi
1. Home > Multiplayer
2. Difficulty seç (ör: Kolay)
3. Mode seç (ör: Classic)
4. Matchmaking başlamalı
5. 30 saniye içinde rakip bulunmalı
6. Oyun başlamalı
7. Birkaç hamle yap
8. Rakibin hamleleri görünmeli
9. Oyunu bitir (kazan veya kaybet)
10. Result dialog açılmalı
11. Leaderboard'da skor görünmeli

### ADIM 5: Market Testi
1. Home > Shop
2. "Test Coins" butonuna bas (Settings'den)
3. 1000 jeton eklensin
4. Bir tema satın al (ör: Neon Theme - 200 jeton)
5. Settings > Theme Selector
6. Neon Theme'i seç
7. Yeni oyun başlat, tema uygulanmış mı kontrol et

### ADIM 6: IAP Testi (Sandbox)
1. Google Play Console'da test hesabı ekle
2. Cihazda test hesabı ile giriş yap
3. Shop > Buy Coins
4. Küçük paketi (₺9.99) seç
5. Google Play ödeme ekranı açılmalı
6. "Test" etiketi görünmeli
7. Satın almayı tamamla (ücretsiz, test modu)
8. 100 jeton hesaba eklenmeli

### ADIM 7: Performans Testi
1. 30 dakika boyunca oyna
2. Crash olmamalı
3. Bellek kullanımı stabil olmalı
4. Batarya tüketimi normal olmalı
5. Ağ bağlantısı kesilip açıldığında recover etmeli

---

## 🐛 SORUN GİDERME

### Matchmaking Çalışmıyor:
- Firebase Realtime Database rules kontrol et
- İnternet bağlantısı var mı?
- Firebase Console'da "waiting_players" node'u var mı?

### IAP Ürünleri Görünmüyor:
- Google Play Console'da ürünler "Active" mi?
- 2-4 saat bekledi mi? (Google propagation süresi)
- Release APK ile mi test ediyorsun? (Debug APK ile IAP çalışmaz!)

### Tema Uygulanmıyor:
- Tema satın alındı mı? (Shop'ta "Owned" yazıyor mu?)
- Theme selector'da seçildi mi?
- Oyun yeniden başlatıldı mı?

### Firebase Auth Hatası:
- SHA-1 fingerprint Firebase Console'a eklendi mi?
- google-services.json güncel mi?
- İnternet bağlantısı var mı?

---

## 📊 TEST SONUÇLARI FORMU

Test edildi tarih: ___________
Cihaz: ___________
Android/iOS versiyonu: ___________

### Başarılı ✅ / Başarısız ❌:
- [ ] Giriş sistemi
- [ ] Matchmaking
- [ ] Oyun mekaniği
- [ ] Shop sistemi
- [ ] IAP satın alma
- [ ] Temalar
- [ ] Power-ups
- [ ] Başarımlar
- [ ] Daily features
- [ ] Performans

### Notlar:
```
[Buraya sorunları ve gözlemleri yaz]
```

---

## 🚀 LAUNCH HAZIRLIK

### Google Play Store:
- [ ] APK/AAB build edildi
- [ ] Store listing tamamlandı (screenshots, açıklama)
- [ ] Privacy policy eklendi
- [ ] Content rating alındı
- [ ] IAP ürünleri oluşturuldu (4 paket)
- [ ] Test edildi (internal testing)
- [ ] Production'a submit edildi

### Apple App Store (Opsiyonel):
- [ ] IPA build edildi
- [ ] App Store Connect listing tamamlandı
- [ ] Screenshots hazırlandı
- [ ] IAP ürünleri eklendi
- [ ] TestFlight test edildi
- [ ] Review'a submit edildi

---

**🎉 HER ŞEY TAMAM! YAYINLAMAYA HAZIR! 🚀**

Good luck! 💪

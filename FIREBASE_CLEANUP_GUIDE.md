# 🧹 FIREBASE TEST VERİLERİNİ TEMİZLEME REHBERİ

**Süre:** 2 dakika ⏱️
**Zorluk:** Çok kolay! 😊

---

## 📱 ADIM ADIM SİLME İŞLEMİ

### 1️⃣ Firebase Console'a Gir
```
🌐 https://console.firebase.google.com
```
- Google hesabınla giriş yap
- **Sudoku Clash** projesini seç

### 2️⃣ Realtime Database'e Git
- Sol menüden **"Realtime Database"** tıkla
- Üstteki **"Data"** sekmesine tıkla

### 3️⃣ Root'u Gör
Ana ekranda şöyle bir yapı göreceksin:
```
/ (root)
├── users
├── games
├── game_invites
├── matchmaking
├── leaderboard
├── friends
├── friendRequests
├── profiles
├── nicknames
├── presence
└── invite_blocks
```

---

## 🗑️ SİLİNECEK HER ŞEY

### YÖNTEM A: TEK TEK SİL (ÖNERİLEN)
Her node'un üzerine gel ve sil:

#### 1. **users** → Sil
- İki test kullanıcının tüm verileri
- Coins, points, achievements, daily challenges, vb.

#### 2. **games** → Sil
- Oynanmış oyun kayıtları
- Matchmaking geçmişi

#### 3. **game_invites** → Sil
- Oyun davetleri

#### 4. **matchmaking** → Sil
- Matchmaking queue

#### 5. **leaderboard** → Sil
- Tüm leaderboard verileri
  - multiplayer
  - daily
  - weekly

#### 6. **friends** → Sil
- Arkadaş listeleri

#### 7. **friendRequests** → Sil
- Arkadaşlık istekleri

#### 8. **profiles** → Sil
- Profil bilgileri

#### 9. **nicknames** → Sil
- Nickname eşleştirmeleri

#### 10. **presence** → Sil
- Online/offline durumları

#### 11. **invite_blocks** → Sil
- Davet engelleme kayıtları

---

## 💡 SİLME NASIL YAPILIR?

### Her Node İçin:
1. Node'a **tıkla** (örn: `users`)
2. Sağ tarafta üç nokta **⋮** görünecek
3. Üç noktaya tıkla
4. **"Delete"** seç
5. Onay ver ✅

**VEYA:**

1. Node'a **sağ tıkla**
2. **"Delete"** seç
3. Onay ver ✅

---

## 🚀 YÖNTEM B: TOPLU SİLME (HIZLI)

Eğer hepsini tek seferde silmek istersen:

1. **Root `/` node'una tıkla**
2. Sağ tarafta **⋮** → **Export JSON**
3. Bir backup al (ihtiyacın olursa)
4. Sonra root `/` node'una tekrar tıkla
5. **⋮** → **Delete**
6. **TÜM DATABASE SİLİNİR!** ⚠️

**UYARI:** Bu tüm veritabanını siler! Sadece test ediyorsan sorun yok.

---

## ✅ SONUÇ KONTROLÜ

Silme işlemi bittikten sonra:

```
/ (root)
  (boş - hiçbir node yok)
```

Veya sadece bazı node'ları sildiysen:
- Sildiğin node'lar artık görünmemeli
- Firebase Console'da "No data available" yazmalı

---

## 🔄 YENİ TEST İÇİN

Database temizlendikten sonra:

1. **Uygulamayı aç** (APK)
2. **İlk kez giriş yap** (Google Sign-In)
3. **Profil oluştur** (nickname, avatar)
4. **İlk oyunu oyna**

Tüm data sıfırdan oluşacak! ✨

---

## 🛡️ GÜVENLİK NOTU

Firebase'de **Security Rules** korundu, sadece **data** silindi.

Rules hala aktif:
- ✅ Authentication gerekli
- ✅ User sadece kendi verisini değiştirebilir
- ✅ Leaderboard okuma açık

---

## 🎯 HIZLI ÖZETİ

```bash
1. Firebase Console aç
2. Realtime Database → Data
3. Her node'u sil (users, games, leaderboard, vb.)
4. Onay ver
5. Bitti! 🎉
```

**Süre:** 1-2 dakika ⚡

---

## ❓ SORUN ÇIKARSA

### "Delete" butonu yok!
- **Çözüm:** Node'u seçtiğinden emin ol, sağ taraftaki ⋮ menüye bak

### Silme işlemi çok uzun sürüyor
- **Çözüm:** Çok fazla veri varsa, root'u silmek daha hızlı

### Silme sonrası uygulama hata veriyor
- **Normal!** İlk girişte data yok, yeni hesap oluştur

### Yanlışlıkla hepsini sildim!
- **Sorun yok!** Bu test ortamı, uygulama yeni veri oluşturacak

---

**🎊 Eve gidince 2 dakikada halledirsin! Kolay gelsin! 💪**

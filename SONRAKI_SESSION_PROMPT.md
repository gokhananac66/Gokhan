# 🎮 SONRAKİ SESSION İÇİN PROMPT

Kopyala yapıştır yap, direkt başla:

---

Bu session'da Sudoku Clash Flutter projesinin UI iyileştirmelerine devam ediyoruz.

**Önceki session'da yapılanlar:**
- ✅ 3 kritik bug fix (wrong moves, leaderboard nickname, race highlight)
- ✅ Home screen yeni logo
- ✅ Number buttons redesign (mavi arka plan yok)
- ✅ "Revanche" → "Rövanş" çevirisi
- ✅ Firebase rules talimatı hazırlandı

**Branch:** `claude/sudoku-clash-continuation-8VIyI`

**Detaylı özet:** `SESSION_SUMMARY_2026-01-12.md` dosyasını oku

---

## 🚀 BU SESSION'DA YAPILACAKLAR (Öncelik Sırasıyla):

### 1️⃣ ÖNCE TEST ET VE KONTROL:
```bash
# Uygulamayı çalıştır ve test et:
# - Wrong moves siliniyor mu?
# - Leaderboard nicknames doğru mu?
# - Race mode her iki kart vurgulu mu?
# - Logo görünüyor mu?
# - Sesler çalışıyor mu?
```

### 2️⃣ BÜYÜK UI DEĞİŞİKLİKLERİ:

**A) Dialog Başlıkları - Gradient Kaldır:**
Şu ekranların başlıklarındaki gradient'i kaldır, SADECE 3D bırak:
- Tek Oyunculu, Online Multiplayer, Rastgele Rakip ekranları
- Profil, İstatistikler, Başarımlar, Liderlik, Ayarlar, Mağaza

Dosyalar: `lib/screens/*_screen.dart`

**B) Oyun Tahtası Major Redesign:**
Referans görseller: `/home/user/Gokhan/Oyun Tahtası 1.jpg`, `Oyun Tahtası 2.jpg`

Değişiklikler:
- Tahta daha kompakt, yukarıya hizalı
- Kareler TAM KARE (şu an dikdörtgen)
- Hata rengi KIRMIZI (sarı değil!)
- Action buttons mesafesi artır
- Multiplayer'da da aynı tasarım

Dosyalar:
- `lib/screens/game_screen.dart`
- `lib/screens/online_game_screen.dart`
- `lib/services/theme_service.dart`

**C) Daily Challenge Takvim Redesign:**
Referans görsel: `/home/user/Gokhan/Yeni Takvim Modeli.jpg`

Üstte altın kupa, altta sade takvim

Dosyalar:
- `lib/screens/daily_challenge_screen.dart`
- `lib/widgets/daily_challenge_card.dart`

**D) Kazanma/Kaybetme Ekranı Fix:**
Referans görsel: `/home/user/Gokhan/KAZANDINIZ, KAYBETTİNİZ EKRANI.jpg`

Süre/hamle/isabet/hata göstergeleri ekrana sığmıyor, düzelt

Dosyalar:
- `lib/widgets/post_game_stats_dialog.dart`
- `lib/widgets/game_result_dialog.dart`

**E) Lobby Arka Plan:**
- Race modu: Mor gradient (aynı kalsın)
- Klasik mod: MAVİ gradient

Dosya: `lib/screens/waiting_for_opponent_screen.dart` (veya lobby)

**F) Rastgele Rakip Mod İkonları:**
İkon boyutlarını küçült, beyaz çerçeve ekrana taşmasın

---

### 3️⃣ SİSTEM SORUNLARI:

**A) Sesler:**
- Kontrol: `test_sudoku/assets/sounds/*.mp3` mevcut
- `pubspec.yaml` kontrol
- Ses servislerini debug et

**B) Temalar:**
- Multiplayer'da da çalışmalı
- `lib/services/theme_service.dart` ve `online_game_screen.dart`

**C) Google Sign-In:**
- Test et, hata varsa debug et
- `lib/screens/login_screen.dart`

**D) IAP Paketleri:**
- "Jeton Al" butonlarını aktif et
- Google Play ödemeye yönlendir
- `lib/screens/shop_screen.dart`

---

## 📋 ÇALIŞMA PLANI:

1. **ÖNCELİKLE** görselleri oku (Read tool ile):
   - `/home/user/Gokhan/Oyun Tahtası 1.jpg`
   - `/home/user/Gokhan/Oyun Tahtası 2.jpg`
   - `/home/user/Gokhan/Yeni Takvim Modeli.jpg`
   - `/home/user/Gokhan/KAZANDINIZ, KAYBETTİNİZ EKRANI.jpg`

2. **SONRA** dosyaları tek tek düzelt

3. **HER MAJOR DEĞİŞİKLİKTEN SONRA** commit/push yap

4. **TAMAMLANINCA** test talimatı ver

---

## 💡 ÖNEMLI:

- MAX Plan kullanıcısı - Soru sorma, direkt yap!
- Görsellere dikkat et, birebir uygulamalısın
- Her commit'te detaylı açıklama yaz
- Firebase rules kullanıcı güncelleyecek (sen yapma)

**HEMEN BAŞLA!**

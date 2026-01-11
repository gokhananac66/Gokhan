# 🚀 SONRAKİ OTURUM İÇİN GÖREVLER

## 1️⃣ MARKET SİSTEMİNİ TAM ÇALIŞIR HALE GETİR

### ✅ ŞU AN ÇALIŞAN:
- Jeton kazanma (başarımlar, daily challenge)
- Mağaza arayüzü
- Satın alma mekanikleri
- İpucu paketleri

### ❌ YAPILACAKLAR (ÖNCELİKLİ):

#### A) TEMALARI UYGULA
- [ ] Satın alınan temaları game_screen.dart'a entegre et
- [ ] Tema seçim sistemi oluştur (settings veya profile'da)
- [ ] Her tema için renk paletleri tanımla:
  - Neon Tema (pembe, mor, sarı tonları)
  - Okyanus Teması (mavi, turkuaz tonları)
  - Gün Batımı Teması (turuncu, kırmızı tonları)
  - Orman Teması (yeşil tonları)
  - Galaksi Teması (mor, lacivert tonları)
- [ ] Seçilen temayı Firebase'e kaydet
- [ ] Oyun tahtasında seçilen temayı uygula

#### B) PREMIUM AVATARLARI EKLE
- [ ] Profile screen'de satın alınan avatarları göster
- [ ] Avatar picker'da premium avatarları unlock sistemi ekle
- [ ] Satın alınmamış avatarlar için kilit ikonu
- [ ] Premium avatar seçildiğinde kullan
- [ ] Avatar listesini genişlet (16 default + 5 premium = 21 avatar)

#### C) POWER-UP'LARI ÇALIŞIR HALE GETİR
- [ ] **2x Puan Çarpanı:**
  - Oyun başlamadan önce aktif etme seçeneği
  - Oyun boyunca tüm puanları 2x yap
  - Oyun bitince power-up'ı tüket
- [ ] **Otomatik Hata Bulma:**
  - Hatalı hücreleri otomatik kırmızı göster
  - Her 30 saniyede bir kontrol et
  - Oyun boyunca çalışsın
- [ ] **Zaman Dondurma (Race Modu):**
  - Race modunda buton ekle
  - 1 dakika süreyi durdur
  - Visual feedback ver

#### D) ROZETLER/ÜNVANLAR SİSTEMİ
- [ ] Profil ekranında rozet gösterme alanı ekle
- [ ] Satın alınan rozetleri listele
- [ ] Aktif rozet seçme sistemi
- [ ] Nickname'in yanında rozet göster
- [ ] Leaderboard'da rozetleri göster

#### E) İPUCU PAKETLERİNİ BİTİR
- [ ] Satın alınan ipuçlarını kullanıcıya ekle
- [ ] Mevcut ipucu sayısını göster
- [ ] İpucu limiti kaldır (satın aldıysa)

## 2️⃣ HOME SCREEN REVİZE

- [ ] Home screen tasarımını güncelle
- [ ] ??? (Kullanıcı detay vermedi, sonra soracak)

---

## 📝 NOTLAR:

**Market Altyapısı:**
- ✅ CurrencyService - Coin yönetimi
- ✅ ShopScreen - Mağaza arayüzü
- ✅ ShopItems - 25+ ürün tanımı
- ✅ Firebase sync + SharedPreferences fallback
- ✅ Satın alma geçmişi takibi
- ✅ Test butonu (Ayarlar'da 1000 jeton ekle)

**Ürünler (25+ item):**
- 5 Premium Avatar
- 3 İpucu Paketi
- 5 Tema
- 3 Power-up
- 4 Rozet/Ünvan

**Jeton Kazanma:**
- Başarımlar → Achievement puanı = Jeton
- Daily Challenge → 20-50 jeton (zorluk göre)

---

## 🎯 HEDEF:
Tüm mağaza ürünlerini fonksiyonel hale getir. Oyuncular satın aldıkları her şeyi kullanabilsin!

**Son Güncelleme:** 2026-01-11
**Hazırlayan:** Claude (Token bitti, oturum kapandı 😅)

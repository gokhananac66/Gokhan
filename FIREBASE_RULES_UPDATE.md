# Firebase Realtime Database Rules Güncelleme

## Problem
Liderlik tablosu güncellenmiyor çünkü Firebase'de `.indexOn` tanımlı değil.

## Hata Mesajı
```
Index not defined, add ".indexOn": "level", for path "/leaderboard/multiplayer"
Index not defined, add ".indexOn": "level", for path "/leaderboard/daily/2026-01-07"
```

## Çözüm: Firebase Console'da Rules Güncelleme

### Adım 1: Firebase Console'a Git
1. https://console.firebase.google.com/ adresine git
2. Projenizi seçin (Sudoku Clash)
3. Sol menüden **Realtime Database** seçin
4. Üst menüden **Rules** sekmesine tıklayın

### Adım 2: Aşağıdaki Rules'ı Ekle

Mevcut rules'ınızı şu şekilde güncelle:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "games": {
      "$gameId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "matchmaking": {
      "$league": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["difficulty", "timestamp", "matched"]
      }
    },
    "leaderboard": {
      "multiplayer": {
        ".read": "auth != null",
        ".write": "auth != null",
        ".indexOn": ["level", "totalScore", "winRate"]
      },
      "daily": {
        "$date": {
          ".read": "auth != null",
          ".write": "auth != null",
          ".indexOn": ["level", "totalScore"]
        }
      },
      "weekly": {
        "$week": {
          ".read": "auth != null",
          ".write": "auth != null",
          ".indexOn": ["level", "totalScore"]
        }
      }
    },
    "friends": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "friendRequests": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "profiles": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

### Adım 3: Publish Et
Rules'ı güncelledikten sonra **"Publish"** butonuna tıkla.

### Önemli Notlar

1. **`.indexOn` nedir?**
   - Firebase'de `.orderByChild('level')` gibi sorgular yapmak için index gerekir
   - Index olmadan query çalışmaz ve hata verir

2. **Hangi indexler eklendi?**
   - `leaderboard/multiplayer`: ["level", "totalScore", "winRate"]
   - `leaderboard/daily/$date`: ["level", "totalScore"]
   - `leaderboard/weekly/$week`: ["level", "totalScore"]
   - `matchmaking/$league`: ["difficulty", "timestamp", "matched"]

3. **Güvenlik**
   - Tüm path'ler `auth != null` ile korunuyor
   - Kullanıcılar sadece kendi verilerini değiştirebiliyor

### Test Et
Rules'ı güncelledikten sonra:
1. Uygulamayı yeniden başlat
2. Bir multiplayer oyun oyna
3. Oyun bitince leaderboard'ı kontrol et
4. Terminalden hata mesajlarının kaybolduğunu kontrol et

---

**ÖNEMLİ:** Rules'ı güncellemeden önce mevcut rules'ınızı yedekle!

# FIREBASE RULES GÜNCELLEMESİ (KRİTİK!)

## Sorunlar:
1. **Arkadaş ekleme hatası**: permission-denied
2. **Recent players hatası**: index not defined on "timestamp"

## Çözüm - Firebase Console'dan yapılacak:

### 1. Firebase Console'a git:
https://console.firebase.google.com

### 2. Projeyi seç: Sudoku Clash

### 3. Sol menüden: **Realtime Database** → **Rules** sekmesi

### 4. Şu kuralları EKLE:

```json
{
  "rules": {
    "users": {
      "$userId": {
        "friends": {
          ".read": "auth != null",
          ".write": "auth.uid == $userId"
        },
        "friendRequests": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "recent_players": {
          ".read": "auth.uid == $userId",
          ".write": "auth.uid == $userId",
          ".indexOn": ["timestamp"]
        }
      }
    },
    "friendRequests": {
      ".read": "auth != null",
      "$requestId": {
        ".write": "auth != null"
      }
    }
  }
}
```

### 5. **Publish** butonuna bas

## Test Et:
- Arkadaş ekleme çalışmalı
- Rövanş daveti gönderme çalışmalı


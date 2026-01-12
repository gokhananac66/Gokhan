1- UI DEĞİŞİKLER
a) Home Screen'de bulunan SUDOKU CLASH ve eğlen yarış kazan yazılarının tasarımı değişecek. çok kötü görünüyor. 3D tamam ama o kadar gradient renkli olmasına gerek yok.
   Ben bunun için bir görsel hazırladım. Üst tarafta bulunan Sudoku Clash, eğlen yarış kazan ve üstte bulunan sudoku logosunu kaldırıp yerine bu logoyu koyacaksın. Dosyaların içine koyuyorum, adı SUDOKU CLASH YENİ LOGO.png
b) Tek Oyunculu modunun açılış ekranında bulunan ve üst kısımda yer alan, Tek Oyunculu, Zorluk Seç, yazılarının fontu da yine sadece 3D olacak, gradient istemiyorum.
c) Online Multiplayer modunun açılış ekranında bulunan ve üst kısımda yer alan, Online Multiplayer, Oyun Modu Seç yazıları da sadece 3D olacak, gradient istemiyorum.
d) Rastgele rakip modunun açılış ekranında bulunan ve üst kısımda yer alan, Rastgele Rakip, Oyun Modu Seç yazıları da sadece 3D olacak, gradient istemiyorum.
e) Rastgele Rakip modunun açılış ekranında bulunan, klasik ve race modu ikonlarının boyutlarını biraz daha küçültmemiz gerekiyor. Kenarlarına eklediğin beyaz çerçeveler ekranın
   dışına taşıyor ve bu çok kötü bir görüntüye sebebiyet veriyor.
f) Rakip aranıyor ekranının arka planı mor gradient bir kaplama ile görüntüleniyor. Bunu özelliştirmek istiyorum. Race modu aynı kalsın. Klasik mod ekranının arka planı mavi gradient 
   olsun. Böylece UI geliştirmesi yapmış olacağız.
g) Aşağıya yazmış olduğum, Ayarlar altındaki tüm menü başlıklarının ( yani mesela profile tıkladım, üstteki profil yazısı) yazı tipi aynı, renkleri de aynı olacak şekilde, sadece 3D olarak yazacaksın. Gradient istemiyorum.
   Profil, İstatistikler, Başarımlar, Oyun Temaları, Rozetler, Liderlik Tablosu, Sistem Ayarlar.
   Ayrıca Mağaza başlığı.
h) En önemli konu! Oyun tahtamız hala rezil rüsva halde. Sana bu oyunu yaparken ilham aldığım oyunun tahtasını tekrar yükleyeceğim.  Bak Dikkat edersen bu adamın oyun tahtasında bulunan 3x3 tahta daha ufak. büyük karelerin içinde bulunan diğer karelerde ufak ve gerçekten kare, bizimki dikdörtgen duruyor. ekranın üst bölümüne hizalamış. üzerinde bulunan yazılar ne kadar soft ve tatlı duruyor. aynı şekilde alttaki geri al sil notlar ve ipucu kısımlarıyla tahta arasında da mesafe var. Ayrıca harfler de biraz daha yukarda ve daha tatlı görünüyor. bizim de buna dönmemiz lazım. Tahtaya tıklayınca oluşan mavi renkte çok hoş. Ayrıca hatalar da kırmızı renkle gösteriliyor. Temaları oluşturmuşsun ama öyle bir hata rengi koymmuşsun ki sarı ne alaka yani. Bunları kesinlikle değiştirmen gerekiyor. Multiplayer ekranını da bu tasarımla birebir aynı yapmamız lazım. Şu an mesela multiplayer kare yapısı çok daha güzel duruyor. Bunu düzelttikten sonra multiplayer yapısını da klasik modla aynı çalışacak şekilde ayarlaman lazım. Görsel Adları: Oyun Tahtası 1.jpg, Oyun Tahtası 2.jpg
ı) Daily Challenge mücadelesi için oluşturduğun takvim de rezalet ötesi. sana yine ilham aldığım oyunun takvim görselin ekliyorum. bak adam ne kadar sade ve güzel yapmış aq. Sen de buna benzer bir tasarım yap. üst tarafa altın logolu bir kupa altına da takvimi ve bizim yazıları ekle gitsin aw bu kadar zor mu. Görsel İsmi, Yeni Takvim Modeli.jpg
i) Kaybeden oyuncunun " Revanche" yazısını değiştir. Türkçe " Rövanş " olsun.
j) Kazanan ve kaybeden ekranlarında, süre, hamle,isabet vve hata kısımlarında, sağ tarafta kalan göstergeler ekrana sığmıyor. bunları oturtmamız lazım ben sana görsel olarakta yükleyeceğim. Dosya ismi KAZANDINIZ, KAYBETTİNİZ EKRANI.jpg


2- Sistem 
a) İlk giriş yapmak istediğimde Google hesabı ile giriş yapmayı denedim ama hata verdi. Bunun sebebini bir araştır. Sorunu düzelt.
b) Jeton paketlerimiz çok güzel görünüyor. Jeton al butonlarımızı aktif hale getirelim, paketi seçtiğinde google ya da appstore ödemeye yönlendirsin ve paket alımı yapsın. eğer zaten yaptıysan sadece kontrol edersin.
c) Multiplayer modunda konfeti efektinin çalışmadığı gördüm. Kazanınca konfeti efekti mutlaka çıksın.
d) Sistem sesleri dosyasını hem bilgisayara hem de git'e koydum ama sesler çalışmıyor. Kontrol etmen lazım.
e) Temaları seçtiğimiz zaman, hem klasik hem de multiplayer modlarının tamamında çalışacak şekilde ayarlaman lazım. Gördüğüm kadarıyla sadece klasik modda çalışıyor. bu durumu da kontrol et eğer bir hata varsa düzelt.
f) Arkadaş ekleme fonksiyonu çalışmıyor. İstek gönder dediğimde hata oluştu diyor. Hata kodunu yazıyorum : I/flutter (30230): ❌ Error sending friend request: [firebase_database/permission-denied] Client doesn't have permission to access the desired data.
g) Rastgele oyna modunda, rövanş butonuna bastığında davet karşı tarafa ulaşmıyor. Kodları yazıyorum : E/firebase_database(30230): Caused by: java.lang.Exception: Index not defined, add ".indexOn": "timestamp", for path "/users/5ReR2eq7muQ9F0Vl5Epx9lHgj5Y2/recent_players", to the rules
E/firebase_database(30230):     at com.google.firebase.database.connection.PersistentConnectionImpl.lambda$get$0(PersistentConnectionImpl.java:424)
E/firebase_database(30230):     at com.google.firebase.database.connection.PersistentConnectionImpl$$ExternalSyntheticLambda1.onResponse(D8$$SyntheticClass:0)
E/firebase_database(30230):     at com.google.firebase.database.connection.PersistentConnectionImpl$6.onResponse(PersistentConnectionImpl.java:1291)
E/firebase_database(30230):     at com.google.firebase.database.connection.PersistentConnectionImpl.onDataMessage(PersistentConnectionImpl.java:495)
E/firebase_database(30230):     at com.google.firebase.database.connection.Connection.onDataMessage(Connection.java:167)
E/firebase_database(30230):     at com.google.firebase.database.connection.Connection.onMessage(Connection.java:131)
E/firebase_database(30230):     at com.google.firebase.database.connection.WebsocketConnection.appendFrame(WebsocketConnection.java:259)
E/firebase_database(30230):     at com.google.firebase.database.connection.WebsocketConnection.handleIncomingFrame(WebsocketConnection.java:306)
E/firebase_database(30230):     at com.google.firebase.database.connection.WebsocketConnection.access$500(WebsocketConnection.java:34)
E/firebase_database(30230):     at com.google.firebase.database.connection.WebsocketConnection$WSClientTubesock$2.run(WebsocketConnection.java:86)
E/firebase_database(30230):     at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:463)
E/firebase_database(30230):     at java.util.concurrent.FutureTask.run(FutureTask.java:264)
E/firebase_database(30230):     at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:307)
E/firebase_database(30230):     ... 3 more
I/flutter (30230): ❌ [RecentPlayersService] Error cleaning up old players: [firebase_database/index-not-defined] Index not defined, add ".indexOn": "timestamp", for path "/users/5ReR2eq7muQ9F0Vl5Epx9lHgj5Y2/recent_players", to the rules
I/flutter (30230): ✅ Recent player recorded: gokhanbey (loss)
D/EGL_emulation(30230): app_time_stats: avg=57.65ms min=11.65ms max=674.96ms count=26
D/EGL_emulation(30230): app_time_stats: avg=257.85ms min=11.41ms max=1668.80ms count=7
D/EGL_emulation(30230): app_time_stats: avg=2412.27ms min=2412.27ms max=2412.27ms count=1
I/flutter (30230): 🎮 [INVITE] Sending REVANCHE invite to gokhanbey (mode: race, difficulty: Kolay)
I/flutter (30230): 🔍 [INVITE] Getting my nickname for uid: 5ReR2eq7muQ9F0Vl5Epx9lHgj5Y2
I/flutter (30230): 🔍 Getting nickname for UID: 5ReR2eq7muQ9F0Vl5Epx9lHgj5Y2
I/flutter (30230): ✅ Found nickname in users/5ReR2eq7muQ9F0Vl5Epx9lHgj5Y2/nickname: gkhnamac66
I/flutter (30230): ✅ [INVITE] My nickname: gkhnamac66
I/flutter (30230): 🎲 [INVITE] Creating game...
I/flutter (30230): 🆔 [INVITE] Game ID: -Oim1XVbLDYDVejOOjgC
I/flutter (30230): 📨 [INVITE] Sending invite to Firebase...
I/flutter (30230): ✅ [INVITE] Invite sent! Invite ID: -Oim1XX0QXlJKcJ5fqjo
I/flutter (30230): ✅ Status updated: idle







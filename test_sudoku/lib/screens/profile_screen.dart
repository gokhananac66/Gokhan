import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_localizations.dart';
import '../services/friend_service.dart';
import '../services/leaderboard_service.dart';
import '../services/currency_service.dart';
import 'shop_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController();

  User? _user;
  String _nickname = '';
  String _fullName = '';
  DateTime? _birthDate;
  String _country = '';
  bool _isEditingNickname = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedAvatar = 0;

  // Mode-based statistics
  Map<String, dynamic>? _classicStats;
  Map<String, dynamic>? _raceStats;

  static const List<Map<String, dynamic>> _avatars = [
    // Free avatars (0-15)
    {'icon': Icons.person, 'color': 0xFF9C27B0, 'premium': false},
    {'icon': Icons.face, 'color': 0xFF2196F3, 'premium': false},
    {'icon': Icons.sentiment_very_satisfied, 'color': 0xFF4CAF50, 'premium': false},
    {'icon': Icons.psychology, 'color': 0xFFFF9800, 'premium': false},
    {'icon': Icons.rocket_launch, 'color': 0xFFE91E63, 'premium': false},
    {'icon': Icons.sports_esports, 'color': 0xFF00BCD4, 'premium': false},
    {'icon': Icons.local_fire_department, 'color': 0xFFF44336, 'premium': false},
    {'icon': Icons.bolt, 'color': 0xFFFFEB3B, 'premium': false},
    {'icon': Icons.star, 'color': 0xFF673AB7, 'premium': false},
    {'icon': Icons.diamond, 'color': 0xFF3F51B5, 'premium': false},
    {'icon': Icons.pets, 'color': 0xFF795548, 'premium': false},
    {'icon': Icons.cruelty_free, 'color': 0xFFE91E63, 'premium': false},
    {'icon': Icons.catching_pokemon, 'color': 0xFFFF5722, 'premium': false},
    {'icon': Icons.nightlife, 'color': 0xFF9C27B0, 'premium': false},
    {'icon': Icons.music_note, 'color': 0xFF00BCD4, 'premium': false},
    {'icon': Icons.emoji_nature, 'color': 0xFF8BC34A, 'premium': false},

    // Premium avatars (16-20) - require shop purchase
    {'icon': Icons.auto_fix_high, 'color': 0xFF9C27B0, 'premium': true, 'shopId': 'avatar_wizard'}, // Wizard
    {'icon': Icons.smart_toy, 'color': 0xFF607D8B, 'premium': true, 'shopId': 'avatar_robot'}, // Robot
    {'icon': Icons.sensors, 'color': 0xFF4CAF50, 'premium': true, 'shopId': 'avatar_alien'}, // Alien
    {'icon': Icons.visibility_off, 'color': 0xFF212121, 'premium': true, 'shopId': 'avatar_ninja'}, // Ninja
    {'icon': Icons.workspace_premium, 'color': 0xFFFFD700, 'premium': true, 'shopId': 'avatar_crown'}, // Crown
  ];

  static const List<String> _countries = [
    'Türkiye 🇹🇷',
    'ABD 🇺🇸',
    'Almanya 🇩🇪',
    'İngiltere 🇬🇧',
    'Fransa 🇫🇷',
    'İtalya 🇮🇹',
    'İspanya 🇪🇸',
    'Hollanda 🇳🇱',
    'Belçika 🇧🇪',
    'İsviçre 🇨🇭',
    'Avusturya 🇦🇹',
    'Kanada 🇨🇦',
    'Avustralya 🇦🇺',
    'Japonya 🇯🇵',
    'Güney Kore 🇰🇷',
    'Brezilya 🇧🇷',
    'Meksika 🇲🇽',
    'Rusya 🇷🇺',
    'Diğer 🌍',
  ];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
    _loadModeStats();
  }

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Firebase'den oku
      final snapshot = await _database.child('users/$userId/profile').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _nickname = data['nickname'] ?? '';
          _nicknameController.text = _nickname;
          _fullName = data['fullName'] ?? '';
          _nameController.text = _fullName;
          _selectedAvatar = data['selectedAvatar'] ?? 0;
          _country = data['country'] ?? '';

          if (data['birthDate'] != null) {
            _birthDate = DateTime.tryParse(data['birthDate']);
          }
        });
      } else {
        // Firebase'de yoksa SharedPreferences'ten yükle (eski kullanıcılar için)
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _nickname = prefs.getString('nickname') ?? '';
          _nicknameController.text = _nickname;
          _fullName = prefs.getString('fullName') ?? '';
          _nameController.text = _fullName;
          _selectedAvatar = prefs.getInt('selectedAvatar') ?? 0;
          _country = prefs.getString('country') ?? '';

          final birthDateStr = prefs.getString('birthDate');
          if (birthDateStr != null) {
            _birthDate = DateTime.tryParse(birthDateStr);
          }
        });

        // İlk kez Firebase'e kaydet
        if (_fullName.isNotEmpty || _country.isNotEmpty || _birthDate != null) {
          await _syncToFirebase();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Hata varsa SharedPreferences'ten yükle
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nickname = prefs.getString('nickname') ?? '';
        _nicknameController.text = _nickname;
        _fullName = prefs.getString('fullName') ?? '';
        _nameController.text = _fullName;
        _selectedAvatar = prefs.getInt('selectedAvatar') ?? 0;
        _country = prefs.getString('country') ?? '';

        final birthDateStr = prefs.getString('birthDate');
        if (birthDateStr != null) {
          _birthDate = DateTime.tryParse(birthDateStr);
        }
      });
    }
  }

  Future<void> _syncToFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _database.child('users/$userId/profile').set({
        'nickname': _nickname,
        'fullName': _fullName,
        'birthDate': _birthDate?.toIso8601String(),
        'country': _country,
        'selectedAvatar': _selectedAvatar,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }

  Future<void> _loadModeStats() async {
    try {
      final classicStats = await LeaderboardService.getUserModeStats('classic');
      final raceStats = await LeaderboardService.getUserModeStats('race');
      setState(() {
        _classicStats = classicStats;
        _raceStats = raceStats;
      });
    } catch (e) {
      // Stats yüklenemedi, boş bırak
    }
  }

  int _calculateAge() {
    if (_birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    if (AppLocalizations.currentLanguage == 'en') {
      const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } else {
      const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Future<bool> _isNicknameAvailable(String nickname) async {
    final snapshot = await _database
        .child('nicknames')
        .orderByValue()
        .equalTo(nickname.toLowerCase())
        .get();

    if (!snapshot.exists) return true;

    final data = snapshot.value as Map?;
    if (data != null) {
      final userId = _auth.currentUser?.uid;
      if (data.containsKey(userId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveNickname() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty) {
      setState(() => _errorMessage = tr('nicknameEmpty'));
      return;
    }
    if (newNickname.length < 3) {
      setState(() => _errorMessage = tr('nicknameShort'));
      return;
    }
    if (newNickname.length > 15) {
      setState(() => _errorMessage = tr('nicknameLong'));
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newNickname)) {
      setState(() => _errorMessage = tr('nicknameChars'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final normalizedNickname = newNickname.toLowerCase();

      // Nickname kullanılıyor mu kontrol et
      final existingSnapshot = await _database.child('nicknames/$normalizedNickname').get();

      if (existingSnapshot.exists) {
        final existingUid = existingSnapshot.value as String;
        if (existingUid != _auth.currentUser?.uid) {
          setState(() {
            _isLoading = false;
            _errorMessage = tr('nicknameTaken');
          });
          return;
        }
      }

      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Eski nickname'i sil
        if (_nickname.isNotEmpty && _nickname.toLowerCase() != normalizedNickname) {
          await _database.child('nicknames/${_nickname.toLowerCase()}').remove();
        }

        // Yeni nickname mapping kaydet
        await _database.child('nicknames/$normalizedNickname').set(userId);

        // User profile'a da kaydet (FIXED: users/$userId/profile path kullan)
        await _database.child('users/$userId/profile').update({
          'nickname': newNickname,
          'nicknameLower': normalizedNickname,
        });

        // FriendService ile de kaydet (arkadaş sistemi için)
        await FriendService().saveNicknameMapping(newNickname);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', newNickname);

      setState(() {
        _nickname = newNickname;
        _isEditingNickname = false;
        _isLoading = false;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('nicknameSaved')), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    setState(() => _fullName = newName);

    // Firebase'e kaydet
    await _syncToFirebase();

    // SharedPreferences'e de kaydet (fallback)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', newName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('nameSaved')), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: tr('selectBirthDate'),
      cancelText: tr('cancel'),
      confirmText: tr('ok'),
    );

    if (picked != null) {
      setState(() => _birthDate = picked);

      // Firebase'e kaydet
      await _syncToFirebase();

      // SharedPreferences'e de kaydet (fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birthDate', picked.toIso8601String());
    }
  }

  void _selectCountry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr('selectCountry'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final isSelected = _country == country;
                    return ListTile(
                      title: Text(country),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                      onTap: () async {
                        setState(() => _country = country);

                        // Firebase'e kaydet
                        await _syncToFirebase();

                        // SharedPreferences'e de kaydet (fallback)
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('country', country);

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarPicker() {
    if (_user?.photoURL != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('googlePhoto')), backgroundColor: Colors.orange),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<List<String>>(
            future: CurrencyService().getPurchasedItems(),
            builder: (context, snapshot) {
              final purchasedItems = snapshot.data ?? [];

              // Separate free and premium avatars
              final freeAvatars = _avatars.where((a) => a['premium'] != true).toList();
              final premiumAvatars = _avatars.where((a) => a['premium'] == true).toList();
              final unlockedPremiumAvatars = premiumAvatars.where((a) => purchasedItems.contains(a['shopId'])).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text(tr('selectAvatar'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 20),

                    // Two column layout: Free (left) and Premium (right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT: Free Avatars
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.currentLanguage == 'tr' ? 'Ücretsiz' : 'Free',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: freeAvatars.length,
                                itemBuilder: (context, index) {
                                  final avatar = freeAvatars[index];
                                  final avatarIndex = _avatars.indexOf(avatar);
                                  final isSelected = _selectedAvatar == avatarIndex;

                                  return GestureDetector(
                                    onTap: () async {
                                      setState(() => _selectedAvatar = avatarIndex);
                                      await _syncToFirebase();
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setInt('selectedAvatar', avatarIndex);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(tr('avatarChanged')), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(avatar['color']).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: isSelected ? Border.all(color: Color(avatar['color']), width: 3) : null,
                                      ),
                                      child: Center(
                                        child: Icon(avatar['icon'], size: 28, color: Color(avatar['color'])),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // RIGHT: Premium Avatars
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.currentLanguage == 'tr' ? 'Premium' : 'Premium',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Show unlocked premium avatars
                              if (unlockedPremiumAvatars.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: unlockedPremiumAvatars.length,
                                  itemBuilder: (context, index) {
                                    final avatar = unlockedPremiumAvatars[index];
                                    final avatarIndex = _avatars.indexOf(avatar);
                                    final isSelected = _selectedAvatar == avatarIndex;

                                    return GestureDetector(
                                      onTap: () async {
                                        setState(() => _selectedAvatar = avatarIndex);
                                        await _syncToFirebase();
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setInt('selectedAvatar', avatarIndex);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(tr('avatarChanged')), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(avatar['color']).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: isSelected ? Border.all(color: Color(avatar['color']), width: 3) : null,
                                        ),
                                        child: Center(
                                          child: Icon(avatar['icon'], size: 28, color: Color(avatar['color'])),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // "Buy New Avatar" button if no premium avatars
                              if (unlockedPremiumAvatars.isEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Navigate to shop screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ShopScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange.shade300, Colors.orange.shade600],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.shopping_cart, color: Colors.white, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.currentLanguage == 'tr' ? 'Yeni Avatar Al' : 'Buy Avatar',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('signOut')),
        content: Text(tr('signOutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _auth.signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(tr('signOut'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // İlk onay dialogu
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('deleteAccount'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('deleteAccountWarning'), style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('willBeDeleted')}:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  const SizedBox(height: 8),
                  _buildDeleteItem('Email ve hesap bilgileri'),
                  _buildDeleteItem('Profil ve kullanıcı adı'),
                  _buildDeleteItem('Tüm oyun istatistikleri'),
                  _buildDeleteItem('Liderlik tablosu kayıtları'),
                  _buildDeleteItem('Arkadaş listesi'),
                  _buildDeleteItem('Başarımlar ve rozetler'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Son onay dialogu
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('areYouSure')),
        content: Text(tr('deleteAccountFinal')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('deleteAccountConfirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (finalConfirmed != true) return;

    // Hesabı sil
    try {
      final uid = user.uid;

      // 1. Firebase Realtime Database verilerini sil
      await _database.child('users/$uid').remove();
      await _database.child('leaderboard/multiplayer/$uid').remove();

      // Nickname mapping'i sil
      if (_nickname.isNotEmpty) {
        await _database.child('nicknames/${_nickname.toLowerCase()}').remove();
      }

      // 2. SharedPreferences temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Firebase Auth hesabını sil
      await user.delete();

      // Login ekranına yönlendir
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(tr('accountDeleted')),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Yeniden giriş gerekli
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(tr('reAuthRequired')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${tr('error')}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${tr('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 14, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
        ],
      ),
    );
  }

  String _getAccountType() {
    if (_user == null) return tr('guest');
    if (_user!.isAnonymous) return tr('guest');
    if (_user!.providerData.any((p) => p.providerId == 'google.com')) return 'Google';
    return 'Email';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAvatar = _avatars[_selectedAvatar];
    final bool hasGooglePhoto = _user?.photoURL != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [const Color(0xFF1A237E), const Color(0xFF121212), const Color(0xFF121212)]
            : [const Color(0xFF90CAF9), const Color(0xFFE3F2FD), const Color(0xFFF5F5F5)],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Custom Header
                Row(
                  children: [
                    // Geri Butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Başlık
                    Text(
                      '👤 ${tr('profile')}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Placeholder for symmetry
                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 20),
                // Avatar ve Temel Bilgiler - Premium Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(
                          children: [
                            // Gradient Ring
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: hasGooglePhoto
                                      ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(_user!.photoURL!))
                                      : CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Color(currentAvatar['color']).withOpacity(0.2),
                                          child: Icon(currentAvatar['icon'], size: 40, color: Color(currentAvatar['color'])),
                                        ),
                                ),
                              ),
                            ),
                            // Edit badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.edit, size: 16, color: const Color(0xFF9C27B0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _user?.email ?? tr('guestUser'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nickname
                      if (_isEditingNickname)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nicknameController,
                                  maxLength: 15,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: tr('enterNickname'),
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    errorText: _errorMessage,
                                    errorStyle: const TextStyle(color: Colors.yellow),
                                  ),
                                  onChanged: (_) => _errorMessage != null ? setState(() => _errorMessage = null) : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _isLoading ? null : _saveNickname,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check, color: Colors.greenAccent),
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _isEditingNickname = false;
                                  _nicknameController.text = _nickname;
                                  _errorMessage = null;
                                }),
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => setState(() => _isEditingNickname = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_nickname.isNotEmpty)
                                Text(
                                  '@$_nickname',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    tr('addNickname'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.9),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, size: 18, color: Colors.white.withOpacity(0.8)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Kişisel Bilgiler - Premium Section Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFf7971e).withOpacity(0.9),
                        const Color(0xFFffd200).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf7971e).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📋', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tr('personalInfo'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Kişisel Bilgiler Content
                Column(
                  children: [

                  // Isim
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: tr('fullName'),
                    value: _fullName.isEmpty ? tr('notSpecified') : _fullName,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(tr('fullName')),
                          content: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: tr('enterFullName'),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
                            TextButton(
                              onPressed: () {
                                _saveName();
                                Navigator.pop(context);
                              },
                              child: Text(tr('save')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Dogum Tarihi
                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: tr('birthDate'),
                    value: _birthDate == null ? tr('notSpecified') : _formatDate(_birthDate!),
                    onTap: _selectBirthDate,
                  ),

                  // Yas
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: tr('age'),
                    value: _birthDate == null ? '-' : '${_calculateAge()} ${tr('yearsOld')}',
                    onTap: null,
                  ),

                    // Ulke
                    _buildInfoRow(
                      icon: Icons.flag_outlined,
                      label: tr('country'),
                      value: _country.isEmpty ? tr('notSpecified') : _country,
                      onTap: _selectCountry,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Mode-based Statistics
                if (_classicStats != null || _raceStats != null) ...[
                  // Section Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4facfe).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('📊', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Oyun Modu İstatistikleri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Classic Mode Stats
                  if (_classicStats != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('⚔️', style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Klasik Mod',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatChip('Oyun', '${_classicStats!['gamesPlayed'] ?? 0}', Colors.white),
                              _buildStatChip('Galibiyet', '${_classicStats!['wins'] ?? 0}', Colors.white),
                              _buildStatChip('Win %', '${_classicStats!['winRate'] ?? '0.0'}', Colors.white),
                              _buildStatChip('Skor', '${_classicStats!['totalScore'] ?? 0}', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Race Mode Stats
                  if (_raceStats != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('🏁', style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Race Mod',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatChip('Oyun', '${_raceStats!['gamesPlayed'] ?? 0}', Colors.white),
                              _buildStatChip('Galibiyet', '${_raceStats!['wins'] ?? 0}', Colors.white),
                              _buildStatChip('Win %', '${_raceStats!['winRate'] ?? '0.0'}', Colors.white),
                              if (_raceStats!['fastestWin'] != null)
                                _buildStatChip('En Hızlı', _formatTime(_raceStats!['fastestWin']), Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                // Cikis Butonu
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _signOut,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.logout, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tr('signOut'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Hesabımı Sil Butonu
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _deleteAccount,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              tr('deleteAccount'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Her bilgi türü için farklı gradient renk
    LinearGradient gradient;
    Color iconColor;

    switch (label) {
      case 'İsim Soyisim':
      case 'Full Name':
        gradient = const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
      case 'Doğum Tarihi':
      case 'Birth Date':
        gradient = const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
      case 'Yaş':
      case 'Age':
        gradient = const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
      case 'Ülke':
      case 'Country':
        gradient = const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
        break;
      default:
        gradient = const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF9E9E9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 26, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
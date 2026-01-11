import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_localizations.dart';
import '../services/friend_service.dart';
import '../services/leaderboard_service.dart';

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
    {'icon': Icons.person, 'color': 0xFF9C27B0},
    {'icon': Icons.face, 'color': 0xFF2196F3},
    {'icon': Icons.sentiment_very_satisfied, 'color': 0xFF4CAF50},
    {'icon': Icons.psychology, 'color': 0xFFFF9800},
    {'icon': Icons.rocket_launch, 'color': 0xFFE91E63},
    {'icon': Icons.sports_esports, 'color': 0xFF00BCD4},
    {'icon': Icons.local_fire_department, 'color': 0xFFF44336},
    {'icon': Icons.bolt, 'color': 0xFFFFEB3B},
    {'icon': Icons.star, 'color': 0xFF673AB7},
    {'icon': Icons.diamond, 'color': 0xFF3F51B5},
    {'icon': Icons.pets, 'color': 0xFF795548},
    {'icon': Icons.cruelty_free, 'color': 0xFFE91E63},
    {'icon': Icons.catching_pokemon, 'color': 0xFFFF5722},
    {'icon': Icons.nightlife, 'color': 0xFF9C27B0},
    {'icon': Icons.music_note, 'color': 0xFF00BCD4},
    {'icon': Icons.emoji_nature, 'color': 0xFF8BC34A},
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

        // User profile'a da kaydet
        await _database.child('users/$userId').update({
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _nameController.text.trim());
    setState(() => _fullName = _nameController.text.trim());
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birthDate', picked.toIso8601String());
      setState(() => _birthDate = picked);
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
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('country', country);
                        setState(() => _country = country);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(tr('selectAvatar'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = _selectedAvatar == index;
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('selectedAvatar', index);
                      setState(() => _selectedAvatar = index);
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
                      child: Center(child: Icon(avatar['icon'], size: 32, color: Color(avatar['color']))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('signOut')),
        content: Text(tr('signOutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(tr('signOut'), style: const TextStyle(color: Colors.red)),
          ),
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(tr('profile')),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _signOut),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar ve Temel Bilgiler
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9C27B0).withOpacity(isDark ? 0.3 : 0.1),
                    Color(0xFFE91E63).withOpacity(isDark ? 0.2 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFF9C27B0).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C27B0).withOpacity(0.3),
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
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF9C27B0).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              ),
                              child: hasGooglePhoto
                                  ? CircleAvatar(radius: 30, backgroundImage: NetworkImage(_user!.photoURL!))
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color(currentAvatar['color']).withOpacity(0.2),
                                      child: Icon(currentAvatar['icon'], size: 30, color: Color(currentAvatar['color'])),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Text(_user?.email ?? tr('guestUser'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),

                  // Nickname
                  if (_isEditingNickname)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nicknameController,
                            maxLength: 15,
                            decoration: InputDecoration(
                              hintText: tr('enterNickname'),
                              counterText: '',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              errorText: _errorMessage,
                            ),
                            onChanged: (_) => _errorMessage != null ? setState(() => _errorMessage = null) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : _saveNickname,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _isEditingNickname = false;
                            _nicknameController.text = _nickname;
                            _errorMessage = null;
                          }),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _isEditingNickname = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _nickname.isEmpty ? tr('addNickname') : '@$_nickname',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _nickname.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kişisel Bilgiler
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('personalInfo'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),

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
            ),

            const SizedBox(height: 16),

            // Mode-based Statistics
            if (_classicStats != null || _raceStats != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Oyun Modu İstatistikleri',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Classic Mode Stats
                    if (_classicStats != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sports_esports, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('⚔️ Klasik Mod', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatChip('Oyun', '${_classicStats!['gamesPlayed'] ?? 0}', Colors.white.withOpacity(0.9)),
                                _buildStatChip('Galibiyet', '${_classicStats!['wins'] ?? 0}', Colors.white.withOpacity(0.9)),
                                _buildStatChip('Win %', '${_classicStats!['winRate'] ?? '0.0'}', Colors.white.withOpacity(0.9)),
                                _buildStatChip('Skor', '${_classicStats!['totalScore'] ?? 0}', Colors.white.withOpacity(0.9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Race Mode Stats
                    if (_raceStats != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.speed, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('🏁 Race Mod', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatChip('Oyun', '${_raceStats!['gamesPlayed'] ?? 0}', Colors.white.withOpacity(0.9)),
                                _buildStatChip('Galibiyet', '${_raceStats!['wins'] ?? 0}', Colors.white.withOpacity(0.9)),
                                _buildStatChip('Win %', '${_raceStats!['winRate'] ?? '0.0'}', Colors.white.withOpacity(0.9)),
                                if (_raceStats!['fastestWin'] != null)
                                  _buildStatChip('En Hızlı', _formatTime(_raceStats!['fastestWin']), Colors.white.withOpacity(0.9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Cikis Butonu
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          tr('signOut'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
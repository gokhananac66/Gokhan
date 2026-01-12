import 'package:flutter/material.dart';
import '../services/badge_service.dart';
import '../app_localizations.dart';

class BadgeSelectorScreen extends StatefulWidget {
  const BadgeSelectorScreen({super.key});

  @override
  State<BadgeSelectorScreen> createState() => _BadgeSelectorScreenState();
}

class _BadgeSelectorScreenState extends State<BadgeSelectorScreen> {
  String? _selectedBadge;
  List<BadgeType> _ownedBadges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final selected = await BadgeService().getSelectedBadge();
    final owned = await BadgeService().getOwnedBadges();

    setState(() {
      _selectedBadge = selected;
      _ownedBadges = owned;
      _loading = false;
    });
  }

  Future<void> _selectBadge(String? badgeId) async {
    await BadgeService().setSelectedBadge(badgeId);
    setState(() => _selectedBadge = badgeId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(badgeId == null
              ? (AppLocalizations.currentLanguage == 'tr'
                  ? 'Rozet kaldırıldı'
                  : 'Badge removed')
              : (AppLocalizations.currentLanguage == 'tr'
                  ? 'Rozet değiştirildi!'
                  : 'Badge changed!')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = AppLocalizations.currentLanguage;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          locale == 'tr' ? 'Rozetler' : 'Badges',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
            shadows: const [
              Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black26),
              Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Colors.white70),
            ],
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ownedBadges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        locale == 'tr'
                            ? 'Henüz rozet satın almadınız'
                            : 'You haven\'t purchased any badges yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locale == 'tr'
                            ? 'Mağazadan rozet satın alabilirsiniz'
                            : 'Purchase badges from the shop',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // No badge option
                    GestureDetector(
                      onTap: () => _selectBadge(null),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedBadge == null
                                ? Colors.blue
                                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                            width: _selectedBadge == null ? 3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                locale == 'tr' ? 'Rozet Yok' : 'No Badge',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (_selectedBadge == null)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 32,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Owned badges
                    ..._ownedBadges.map((badge) {
                      final isSelected = _selectedBadge == badge.id;

                      return GestureDetector(
                        onTap: () => _selectBadge(badge.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    badge.icon,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      badge.getName(locale),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      locale == 'tr' ? 'Sahip' : 'Owned',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }
}

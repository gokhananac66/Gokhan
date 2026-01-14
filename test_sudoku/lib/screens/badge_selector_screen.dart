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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 12),

                    // Custom Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
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
                            '🎖️ ${locale == 'tr' ? 'Rozetler' : 'Badges'}',
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
                    ),

                    const SizedBox(height: 16),

                    // İçerik
                    Expanded(
                      child: _ownedBadges.isEmpty
                          ? _buildEmptyState(isDark, locale)
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // Section Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [const Color(0xFF56ab2f).withOpacity(0.9), const Color(0xFFa8e063).withOpacity(0.9)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF56ab2f).withOpacity(0.4),
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
                                          child: const Text('✨', style: TextStyle(fontSize: 20)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          locale == 'tr' ? 'Rozetini Seç' : 'Select Your Badge',
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

                                  const SizedBox(height: 16),

                                  // No badge option
                                  _buildBadgeCard(
                                    icon: '👤',
                                    name: locale == 'tr' ? 'Rozet Yok' : 'No Badge',
                                    subtitle: locale == 'tr' ? 'Varsayılan görünüm' : 'Default appearance',
                                    isSelected: _selectedBadge == null,
                                    onTap: () => _selectBadge(null),
                                    isDark: isDark,
                                    gradientColors: [Colors.grey.shade600, Colors.grey.shade400],
                                  ),

                                  // Owned badges
                                  ..._ownedBadges.map((badge) {
                                    final isSelected = _selectedBadge == badge.id;

                                    return _buildBadgeCard(
                                      icon: badge.icon,
                                      name: badge.getName(locale),
                                      subtitle: locale == 'tr' ? 'Sahip ✓' : 'Owned ✓',
                                      isSelected: isSelected,
                                      onTap: () => _selectBadge(badge.id),
                                      isDark: isDark,
                                      gradientColors: [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
                                    );
                                  }),

                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String locale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                  : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                locale == 'tr'
                    ? 'Henüz rozet satın almadınız'
                    : 'You haven\'t purchased any badges yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                locale == 'tr'
                    ? 'Mağazadan rozet satın alabilirsiniz'
                    : 'Purchase badges from the shop',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard({
    required String icon,
    required String name,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                      : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // Check Icon
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

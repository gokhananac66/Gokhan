import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/currency_service.dart';
import '../app_localizations.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  String _selectedTheme = 'default';
  List<String> _unlockedThemes = [];
  bool _loading = true;

  final Map<String, String> _themeNames = {
    'default': 'Varsayılan',
    'ocean': '🌊 Okyanus',
    'sunset': '🌅 Gün Batımı',
    'forest': '🌲 Orman',
    'galaxy': '🌌 Galaksi',
    'midnight': '🌙 Gece Yarısı',
    'rose': '🌹 Gül',
    'lavender': '💜 Lavanta',
    'earth': '🏔️ Toprak',
    'mint': '🍃 Nane',
  };

  final Map<String, String> _themeNamesEn = {
    'default': 'Default',
    'ocean': '🌊 Ocean',
    'sunset': '🌅 Sunset',
    'forest': '🌲 Forest',
    'galaxy': '🌌 Galaxy',
    'midnight': '🌙 Midnight',
    'rose': '🌹 Rose',
    'lavender': '💜 Lavender',
    'earth': '🏔️ Earth',
    'mint': '🍃 Mint',
  };

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    final selected = await ThemeService().getSelectedTheme();
    final purchased = await CurrencyService().getPurchasedItems();

    // Default is always unlocked
    final unlocked = ['default'];

    // Check purchased themes
    for (final themeId in GameTheme.getAllThemeIds()) {
      if (themeId == 'default') continue;
      final shopItemId = 'theme_$themeId';
      if (purchased.contains(shopItemId)) {
        unlocked.add(themeId);
      }
    }

    setState(() {
      _selectedTheme = selected;
      _unlockedThemes = unlocked;
      _loading = false;
    });
  }

  Future<void> _selectTheme(String themeId) async {
    await ThemeService().setSelectedTheme(themeId);
    setState(() => _selectedTheme = themeId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('themeChanged')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // Return to previous screen so changes take effect
      Navigator.pop(context, true); // true indicates theme changed
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
                            '🎨 ${locale == 'tr' ? 'Oyun Temaları' : 'Game Themes'}',
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
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Section Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFF4facfe).withOpacity(0.9), const Color(0xFF00f2fe).withOpacity(0.9)],
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
                                    child: const Text('🎯', style: TextStyle(fontSize: 20)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    locale == 'tr' ? 'Temanı Seç' : 'Choose Your Theme',
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

                            // Theme List
                            ...GameTheme.getAllThemeIds().map((themeId) {
                              final isUnlocked = _unlockedThemes.contains(themeId);
                              final isSelected = _selectedTheme == themeId;
                              final themeName = locale == 'tr'
                                  ? _themeNames[themeId]!
                                  : _themeNamesEn[themeId]!;
                              final themePreview = GameTheme.getTheme(themeId, isDark);

                              return _buildThemeCard(
                                themeId: themeId,
                                themeName: themeName,
                                themePreview: themePreview,
                                isUnlocked: isUnlocked,
                                isSelected: isSelected,
                                isDark: isDark,
                                locale: locale,
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

  Widget _buildThemeCard({
    required String themeId,
    required String themeName,
    required GameTheme themePreview,
    required bool isUnlocked,
    required bool isSelected,
    required bool isDark,
    required String locale,
  }) {
    // Determine gradient colors based on theme
    List<Color> getThemeGradient() {
      switch (themeId) {
        case 'default':
          return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
        case 'ocean':
          return [const Color(0xFF00BCD4), const Color(0xFF0097A7)];
        case 'sunset':
          return [const Color(0xFFFF7043), const Color(0xFFE64A19)];
        case 'forest':
          return [const Color(0xFF4CAF50), const Color(0xFF388E3C)];
        case 'galaxy':
          return [const Color(0xFF7C4DFF), const Color(0xFF651FFF)];
        case 'midnight':
          return [const Color(0xFF3F51B5), const Color(0xFF303F9F)];
        case 'rose':
          return [const Color(0xFFE91E63), const Color(0xFFC2185B)];
        case 'lavender':
          return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
        case 'earth':
          return [const Color(0xFF795548), const Color(0xFF5D4037)];
        case 'mint':
          return [const Color(0xFF26A69A), const Color(0xFF00897B)];
        default:
          return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      }
    }

    final gradientColors = getThemeGradient();

    return GestureDetector(
      onTap: isUnlocked
          ? () => _selectTheme(themeId)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(locale == 'tr'
                      ? 'Bu temayı kullanmak için mağazadan satın almalısınız'
                      : 'Purchase this theme from the shop to use it'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
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
              // Theme preview
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.5)
                        : themePreview.thickGridLineColor,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: Container(color: themePreview.selectedCell)),
                            Expanded(child: Container(color: themePreview.highlightedCell)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: Container(color: themePreview.completedCell)),
                            Expanded(child: Container(color: themePreview.wrongCell)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Theme info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeName,
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
                      isUnlocked
                          ? (locale == 'tr' ? 'Sahip ✓' : 'Owned ✓')
                          : (locale == 'tr' ? 'Mağazadan satın alın' : 'Purchase from shop'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : (isUnlocked ? Colors.green : Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              // Status icon
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
                )
              else if (!isUnlocked)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
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

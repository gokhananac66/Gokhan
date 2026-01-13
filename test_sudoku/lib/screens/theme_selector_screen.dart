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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          locale == 'tr' ? 'Oyun Temaları' : 'Game Themes',
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: GameTheme.getAllThemeIds().length,
              itemBuilder: (context, index) {
                final themeId = GameTheme.getAllThemeIds()[index];
                final isUnlocked = _unlockedThemes.contains(themeId);
                final isSelected = _selectedTheme == themeId;
                final themeName = locale == 'tr'
                    ? _themeNames[themeId]!
                    : _themeNamesEn[themeId]!;

                // Get theme preview colors
                final themePreview = GameTheme.getTheme(themeId, isDark);

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
                        // Theme preview
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themePreview.thickGridLineColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: themePreview.selectedCell,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: themePreview.highlightedCell,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: themePreview.completedCell,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: themePreview.wrongCell,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isUnlocked
                                    ? (locale == 'tr' ? 'Sahip' : 'Owned')
                                    : (locale == 'tr'
                                        ? 'Mağazadan satın alın'
                                        : 'Purchase from shop'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUnlocked
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status icon
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 32,
                          )
                        else if (!isUnlocked)
                          Icon(
                            Icons.lock,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

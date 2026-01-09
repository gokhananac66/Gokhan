import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../app_localizations.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool timerEnabled = true;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      timerEnabled = prefs.getBool('timerEnabled') ?? true;
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.teal),
            const SizedBox(width: 10),
            Text(tr('language')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('tr', '🇹🇷 Türkçe'),
            const SizedBox(height: 8),
            _buildLanguageOption('en', '🇬🇧 English'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    bool isSelected = AppLocalizations.currentLanguage == code;

    return InkWell(
      onTap: () async {
        await AppLocalizations.setLanguage(code);
        setState(() {});
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('languageChanged')),
            backgroundColor: Colors.green,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(name, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(tr('systemSettings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SES EFEKTLERİ
          _buildSettingSwitch(
            icon: Icons.volume_up_rounded,
            title: tr('soundEffects'),
            subtitle: tr('soundEffectsDesc'),
            colors: [Colors.green.shade500, Colors.green.shade700],
            value: soundEnabled,
            onChanged: (v) async {
              setState(() => soundEnabled = v);
              _saveSetting('soundEnabled', v);
              // Update sound service
              await SoundService().toggleSound(v);
              // Play test sound if enabled
              if (v) {
                await SoundService().playButtonClick();
              }
            },
          ),

          const SizedBox(height: 10),

          // TİTREŞİM
          _buildSettingSwitch(
            icon: Icons.vibration_rounded,
            title: tr('vibration'),
            subtitle: tr('vibrationDesc'),
            colors: [Colors.purple.shade500, Colors.purple.shade700],
            value: vibrationEnabled,
            onChanged: (v) async {
              setState(() => vibrationEnabled = v);
              _saveSetting('vibrationEnabled', v);
              // Update haptic service
              await HapticService().toggleHaptic(v);
              // Test vibration if enabled
              if (v) {
                await HapticService().mediumImpact();
              }
            },
          ),

          const SizedBox(height: 10),

          // ZAMANLAYICI
          _buildSettingSwitch(
            icon: Icons.timer_rounded,
            title: tr('timer'),
            subtitle: tr('timerDesc'),
            colors: [Colors.blue.shade500, Colors.blue.shade700],
            value: timerEnabled,
            onChanged: (v) {
              setState(() => timerEnabled = v);
              _saveSetting('timerEnabled', v);
            },
          ),

          const SizedBox(height: 10),

          // KARANLIK TEMA
          _buildSettingSwitch(
            icon: Icons.dark_mode_rounded,
            title: tr('darkTheme'),
            subtitle: tr('darkThemeDesc'),
            colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade900],
            value: darkMode,
            onChanged: (v) {
              setState(() => darkMode = v);
              _saveSetting('darkMode', v);
              themeNotifier.toggleTheme(v);
            },
          ),

          const SizedBox(height: 10),

          // DİL
          _buildSettingButton(
            icon: Icons.language_rounded,
            title: tr('language'),
            subtitle: tr('languageDesc'),
            trailing: AppLocalizations.currentLanguage == 'tr' ? '🇹🇷 Türkçe' : '🇬🇧 English',
            colors: [Colors.teal.shade500, Colors.teal.shade700],
            onTap: _showLanguageDialog,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.4),
            inactiveThumbColor: Colors.white.withOpacity(0.8),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              Text(trailing, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
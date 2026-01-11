import 'package:flutter/material.dart';

enum ShopCategory {
  avatars,
  hints,
  themes,
  powerups,
  badges,
}

extension ShopCategoryExtension on ShopCategory {
  String getName(String locale) {
    switch (this) {
      case ShopCategory.avatars:
        return locale == 'tr' ? 'Avatarlar' : 'Avatars';
      case ShopCategory.hints:
        return locale == 'tr' ? 'İpuçları' : 'Hints';
      case ShopCategory.themes:
        return locale == 'tr' ? 'Temalar' : 'Themes';
      case ShopCategory.powerups:
        return locale == 'tr' ? 'Güçlendirmeler' : 'Power-ups';
      case ShopCategory.badges:
        return locale == 'tr' ? 'Rozetler' : 'Badges';
    }
  }

  String getIcon() {
    switch (this) {
      case ShopCategory.avatars:
        return '🎭';
      case ShopCategory.hints:
        return '💡';
      case ShopCategory.themes:
        return '🎨';
      case ShopCategory.powerups:
        return '⚡';
      case ShopCategory.badges:
        return '🏆';
    }
  }
}

class ShopItem {
  final String id;
  final ShopCategory category;
  final String nameEn;
  final String nameTr;
  final String descriptionEn;
  final String descriptionTr;
  final String icon;
  final int price;
  final Color? color;
  final dynamic data; // Extra data (avatar index, theme colors, etc.)

  const ShopItem({
    required this.id,
    required this.category,
    required this.nameEn,
    required this.nameTr,
    required this.descriptionEn,
    required this.descriptionTr,
    required this.icon,
    required this.price,
    this.color,
    this.data,
  });

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;
  String getDescription(String locale) => locale == 'tr' ? descriptionTr : descriptionEn;
}

// All available shop items
class ShopItems {
  static final List<ShopItem> all = [
    // === PREMIUM AVATARS ===
    ShopItem(
      id: 'avatar_wizard',
      category: ShopCategory.avatars,
      nameEn: 'Wizard',
      nameTr: 'Büyücü',
      descriptionEn: 'Mystical wizard avatar',
      descriptionTr: 'Gizemli büyücü avatarı',
      icon: '🧙',
      price: 150,
      color: Color(0xFF9C27B0),
      data: {'icon': Icons.auto_fix_high, 'color': 0xFF9C27B0},
    ),
    ShopItem(
      id: 'avatar_robot',
      category: ShopCategory.avatars,
      nameEn: 'Robot',
      nameTr: 'Robot',
      descriptionEn: 'Futuristic robot avatar',
      descriptionTr: 'Fütüristik robot avatarı',
      icon: '🤖',
      price: 150,
      color: Color(0xFF607D8B),
      data: {'icon': Icons.smart_toy, 'color': 0xFF607D8B},
    ),
    ShopItem(
      id: 'avatar_alien',
      category: ShopCategory.avatars,
      nameEn: 'Alien',
      nameTr: 'Uzaylı',
      descriptionEn: 'Mysterious alien avatar',
      descriptionTr: 'Gizemli uzaylı avatarı',
      icon: '👽',
      price: 150,
      color: Color(0xFF4CAF50),
      data: {'icon': Icons.sensors, 'color': 0xFF4CAF50},
    ),
    ShopItem(
      id: 'avatar_ninja',
      category: ShopCategory.avatars,
      nameEn: 'Ninja',
      nameTr: 'Ninja',
      descriptionEn: 'Stealthy ninja avatar',
      descriptionTr: 'Gizli ninja avatarı',
      icon: '🥷',
      price: 150,
      color: Color(0xFF212121),
      data: {'icon': Icons.visibility_off, 'color': 0xFF212121},
    ),
    ShopItem(
      id: 'avatar_crown',
      category: ShopCategory.avatars,
      nameEn: 'Crown',
      nameTr: 'Taç',
      descriptionEn: 'Royal crown avatar',
      descriptionTr: 'Kraliyet tacı avatarı',
      icon: '👑',
      price: 150,
      color: Color(0xFFFFD700),
      data: {'icon': Icons.workspace_premium, 'color': 0xFFFFD700},
    ),

    // === HINT PACKAGES ===
    ShopItem(
      id: 'hints_3',
      category: ShopCategory.hints,
      nameEn: '3 Hints',
      nameTr: '3 İpucu',
      descriptionEn: 'Get 3 extra hints',
      descriptionTr: '3 ekstra ipucu kazan',
      icon: '💡',
      price: 50,
      data: {'amount': 3},
    ),
    ShopItem(
      id: 'hints_10',
      category: ShopCategory.hints,
      nameEn: '10 Hints',
      nameTr: '10 İpucu',
      descriptionEn: 'Get 10 extra hints',
      descriptionTr: '10 ekstra ipucu kazan',
      icon: '💡💡',
      price: 150,
      data: {'amount': 10},
    ),
    ShopItem(
      id: 'hints_25',
      category: ShopCategory.hints,
      nameEn: '25 Hints',
      nameTr: '25 İpucu',
      descriptionEn: 'Get 25 extra hints',
      descriptionTr: '25 ekstra ipucu kazan',
      icon: '💡💡💡',
      price: 300,
      data: {'amount': 25},
    ),

    // === THEMES ===
    ShopItem(
      id: 'theme_neon',
      category: ShopCategory.themes,
      nameEn: 'Neon Theme',
      nameTr: 'Neon Tema',
      descriptionEn: 'Vibrant neon colors',
      descriptionTr: 'Canlı neon renkler',
      icon: '🌈',
      price: 300,
      color: Color(0xFFFF1493),
    ),
    ShopItem(
      id: 'theme_ocean',
      category: ShopCategory.themes,
      nameEn: 'Ocean Theme',
      nameTr: 'Okyanus Teması',
      descriptionEn: 'Calming ocean colors',
      descriptionTr: 'Sakinleştirici okyanus renkleri',
      icon: '🌊',
      price: 300,
      color: Color(0xFF00BCD4),
    ),
    ShopItem(
      id: 'theme_sunset',
      category: ShopCategory.themes,
      nameEn: 'Sunset Theme',
      nameTr: 'Gün Batımı Teması',
      descriptionEn: 'Warm sunset gradients',
      descriptionTr: 'Sıcak gün batımı tonları',
      icon: '🌅',
      price: 300,
      color: Color(0xFFFF6B35),
    ),
    ShopItem(
      id: 'theme_forest',
      category: ShopCategory.themes,
      nameEn: 'Forest Theme',
      nameTr: 'Orman Teması',
      descriptionEn: 'Natural forest greens',
      descriptionTr: 'Doğal orman yeşillikleri',
      icon: '🌲',
      price: 300,
      color: Color(0xFF4CAF50),
    ),
    ShopItem(
      id: 'theme_galaxy',
      category: ShopCategory.themes,
      nameEn: 'Galaxy Theme',
      nameTr: 'Galaksi Teması',
      descriptionEn: 'Cosmic galaxy colors',
      descriptionTr: 'Kozmik galaksi renkleri',
      icon: '🌌',
      price: 300,
      color: Color(0xFF673AB7),
    ),

    // === POWER-UPS ===
    ShopItem(
      id: 'powerup_2x_score',
      category: ShopCategory.powerups,
      nameEn: '2x Score',
      nameTr: '2x Puan',
      descriptionEn: 'Double all points permanently',
      descriptionTr: 'Tüm puanları kalıcı olarak ikiye katla',
      icon: '⚡',
      price: 500,
      color: Color(0xFFFFEB3B),
    ),
    ShopItem(
      id: 'powerup_auto_check',
      category: ShopCategory.powerups,
      nameEn: 'Auto Check',
      nameTr: 'Otomatik Kontrol',
      descriptionEn: 'Automatically find errors every 30s',
      descriptionTr: 'Her 30 saniyede hataları otomatik bul',
      icon: '🔍',
      price: 500,
      color: Color(0xFF2196F3),
    ),
    ShopItem(
      id: 'powerup_time_freeze',
      category: ShopCategory.powerups,
      nameEn: 'Time Freeze',
      nameTr: 'Zaman Dondur',
      descriptionEn: 'Freeze timer for 60s (Race mode)',
      descriptionTr: 'Süreyi 60 saniye dondur (Race modu)',
      icon: '⏸️',
      price: 500,
      color: Color(0xFF00BCD4),
    ),

    // === BADGES/TITLES ===
    ShopItem(
      id: 'badge_master',
      category: ShopCategory.badges,
      nameEn: 'Sudoku Master',
      nameTr: 'Sudoku Ustası',
      descriptionEn: 'Legendary title badge',
      descriptionTr: 'Efsanevi ünvan rozeti',
      icon: '🎖️',
      price: 400,
      color: Color(0xFFFFD700),
    ),
    ShopItem(
      id: 'badge_speedster',
      category: ShopCategory.badges,
      nameEn: 'Speed Demon',
      nameTr: 'Hız Şeytanı',
      descriptionEn: 'Race mode champion badge',
      descriptionTr: 'Race modu şampiyonu rozeti',
      icon: '🏎️',
      price: 400,
      color: Color(0xFFE91E63),
    ),
    ShopItem(
      id: 'badge_genius',
      category: ShopCategory.badges,
      nameEn: 'Puzzle Genius',
      nameTr: 'Bulmaca Dehası',
      descriptionEn: 'Genius level badge',
      descriptionTr: 'Deha seviyesi rozeti',
      icon: '🧠',
      price: 400,
      color: Color(0xFF9C27B0),
    ),
    ShopItem(
      id: 'badge_champion',
      category: ShopCategory.badges,
      nameEn: 'Champion',
      nameTr: 'Şampiyon',
      descriptionEn: 'Ultimate champion badge',
      descriptionTr: 'Nihai şampiyon rozeti',
      icon: '🏆',
      price: 400,
      color: Color(0xFFFFD700),
    ),
  ];

  static List<ShopItem> getByCategory(ShopCategory category) {
    return all.where((item) => item.category == category).toList();
  }
}

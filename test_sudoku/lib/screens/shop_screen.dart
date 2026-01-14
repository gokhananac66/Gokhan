import 'package:flutter/material.dart';
import '../models/shop_item.dart';
import '../services/currency_service.dart';
import '../services/hint_service.dart';
import '../app_localizations.dart';
import 'coin_purchase_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CurrencyService _currencyService = CurrencyService();
  int _coins = 0;
  List<String> _purchasedItems = [];
  bool _loading = true;
  ShopCategory _selectedCategory = ShopCategory.avatars;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final coins = await _currencyService.getCoins();
    final purchased = await _currencyService.getPurchasedItems();
    setState(() {
      _coins = coins;
      _purchasedItems = purchased;
      _loading = false;
    });
  }

  Future<void> _purchaseItem(ShopItem item) async {
    // Check if already purchased
    if (_purchasedItems.contains(item.id)) {
      _showMessage(tr('alreadyPurchased'), isError: true);
      return;
    }

    // Check if enough coins
    if (_coins < item.price) {
      _showMessage(tr('notEnoughCoins'), isError: true);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(tr('confirmPurchase')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.getName(AppLocalizations.currentLanguage)}\n',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              Text(
                item.getDescription(AppLocalizations.currentLanguage),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '${item.price}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(tr('buy')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Process purchase
    final success = await _currencyService.spendCoins(item.price);
    if (!success) {
      _showMessage(tr('purchaseFailed'), isError: true);
      return;
    }

    await _currencyService.markAsPurchased(item.id);

    // Handle different item types
    await _applyPurchase(item);

    // Reload data
    await _loadData();

    _showMessage('${tr('purchaseSuccess')} ${item.getName(AppLocalizations.currentLanguage)}!', isError: false);
  }

  Future<void> _applyPurchase(ShopItem item) async {
    // Handle different item types
    switch (item.category) {
      case ShopCategory.hints:
        // Add hints to user's account
        final amount = item.data['amount'] as int;
        await HintService().addHints(amount);
        print('✅ Added $amount hints to user inventory');
        break;
      case ShopCategory.avatars:
      case ShopCategory.themes:
      case ShopCategory.powerups:
      case ShopCategory.badges:
        // These are cosmetic/unlockable items
        // Just marking as purchased is enough
        break;
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
                            '🛒 ${locale == 'tr' ? 'Mağaza' : 'Shop'}',
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

                    // Coin Balance Card - Premium Style
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Coin Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text('💰', style: TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Balance Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale == 'tr' ? 'Bakiye' : 'Balance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$_coins',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Buy Button
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CoinPurchaseScreen(),
                                  ),
                                );
                                _loadData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add, color: const Color(0xFFFF8C00), size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      locale == 'tr' ? 'Satın Al' : 'Buy',
                                      style: const TextStyle(
                                        color: Color(0xFFFF8C00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category tabs - Premium Style
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: ShopCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = category),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          _getCategoryColor(category),
                                          _getCategoryColor(category).withOpacity(0.7),
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _getCategoryColor(category).withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category.getIcon(),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.getName(locale),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                      shadows: isSelected
                                          ? [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Items grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: ShopItems.getByCategory(_selectedCategory).length,
                        itemBuilder: (context, index) {
                          final item = ShopItems.getByCategory(_selectedCategory)[index];
                          final isPurchased = _purchasedItems.contains(item.id);
                          final canAfford = _coins >= item.price;

                          return _buildShopItemCard(item, isPurchased, canAfford, isDark, locale);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ShopCategory category) {
    switch (category) {
      case ShopCategory.avatars:
        return const Color(0xFFFF6B6B);
      case ShopCategory.themes:
        return const Color(0xFF4facfe);
      case ShopCategory.powerups:
        return const Color(0xFF56ab2f);
      case ShopCategory.hints:
        return const Color(0xFFf7971e);
      case ShopCategory.badges:
        return const Color(0xFFa18cd1);
    }
  }

  Widget _buildShopItemCard(ShopItem item, bool isPurchased, bool canAfford, bool isDark, String locale) {
    final itemColor = item.color ?? _getCategoryColor(_selectedCategory);

    return GestureDetector(
      onTap: isPurchased ? null : () => _purchaseItem(item),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPurchased
                ? [const Color(0xFF56ab2f), const Color(0xFFa8e063)]
                : (canAfford
                    ? [itemColor, itemColor.withOpacity(0.7)]
                    : [Colors.grey.shade600, Colors.grey.shade400]),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPurchased ? const Color(0xFF56ab2f) : itemColor).withOpacity(canAfford ? 0.4 : 0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    item.getName(locale),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    item.getDescription(locale),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Price or purchased badge
                  if (isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            locale == 'tr' ? 'Sahip' : 'Owned',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                ],
              ),
            ),

            // "Not enough coins" overlay
            if (!isPurchased && !canAfford)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

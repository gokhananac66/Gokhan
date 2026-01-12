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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          locale == 'tr' ? 'Mağaza' : 'Shop',
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
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Coin balance header (compact)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Balance info (compact)
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale == 'tr' ? 'Bakiye' : 'Balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                '$_coins',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Buy Coins Button (compact)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CoinPurchaseScreen(),
                            ),
                          );
                          _loadData();
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text(
                          locale == 'tr' ? 'Satın Al' : 'Buy',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFFA500),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category tabs
                Container(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: ShopCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.getIcon(),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                // 3D Gradient Text for selected category
                                if (isSelected)
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Color(0xFFF3E5F5),
                                        Colors.white,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      category.getName(locale),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    category.getName(locale),
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Items grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildShopItemCard(ShopItem item, bool isPurchased, bool canAfford, bool isDark, String locale) {
    return GestureDetector(
      onTap: isPurchased ? null : () => _purchaseItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPurchased
                ? Colors.green.withOpacity(0.5)
                : (item.color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPurchased
                  ? Colors.green.withOpacity(0.2)
                  : (item.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1)),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Text(
                    item.icon,
                    style: TextStyle(
                      fontSize: 48,
                      color: isPurchased ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    item.getName(locale),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isPurchased
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    item.getDescription(locale),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Price or purchased badge
                  if (isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            locale == 'tr' ? 'Sahip' : 'Owned',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? (item.color?.withOpacity(0.2) ?? Colors.purple.withOpacity(0.2))
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              color: canAfford ? (item.color ?? Colors.purple) : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

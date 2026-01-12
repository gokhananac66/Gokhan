import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../services/currency_service.dart';
import '../app_localizations.dart';

class CoinPurchaseScreen extends StatefulWidget {
  const CoinPurchaseScreen({super.key});

  @override
  State<CoinPurchaseScreen> createState() => _CoinPurchaseScreenState();
}

class _CoinPurchaseScreenState extends State<CoinPurchaseScreen> {
  final IAPService _iapService = IAPService();
  final CurrencyService _currencyService = CurrencyService();

  int _currentCoins = 0;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
    _loadCurrentCoins();
  }

  Future<void> _initializeIAP() async {
    await _iapService.initialize();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadCurrentCoins() async {
    final coins = await _currencyService.getCoins();
    if (mounted) {
      setState(() {
        _currentCoins = coins;
      });
    }
  }

  Future<void> _purchasePackage(CoinPackage package) async {
    if (_purchasing) return;

    // Check if IAP is available
    if (!_iapService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.currentLanguage == 'tr'
                  ? 'Satın alma servisi bu cihazda kullanılamıyor. Lütfen Google Play Store yüklü bir cihazda deneyin.'
                  : 'Purchase service is not available on this device. Please try on a device with Google Play Store.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      final success = await _iapService.purchasePackage(package.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.currentLanguage == 'tr'
                  ? 'Satın alma işlemi başlatıldı...'
                  : 'Purchase initiated...',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.currentLanguage == 'tr'
                  ? 'Satın alma başarısız: $e'
                  : 'Purchase failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
        // Reload coins after purchase
        await Future.delayed(const Duration(seconds: 2));
        _loadCurrentCoins();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = AppLocalizations.currentLanguage;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text(locale == 'tr' ? 'Jeton Satın Al' : 'Buy Coins'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          // Current coin balance
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_currentCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildPackageList(locale, isDark),
    );
  }

  Widget _buildNotAvailable(String locale, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              locale == 'tr'
                  ? 'Satın Alma Kullanılamıyor'
                  : 'Purchases Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              locale == 'tr'
                  ? 'Bu cihazda uygulama içi satın almalar desteklenmiyor.'
                  : 'In-app purchases are not supported on this device.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageList(String locale, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.monetization_on, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                locale == 'tr' ? 'Jeton Paketleri' : 'Coin Packages',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale == 'tr'
                    ? 'Premium avatarlar, temalar ve özellikler için jeton satın alın'
                    : 'Buy coins for premium avatars, themes, and features',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Packages
        ...IAPService.packages.map((package) => _buildPackageCard(package, locale, isDark)),

        const SizedBox(height: 20),

        // Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locale == 'tr'
                      ? 'Jetonlar kalıcıdır ve asla kaybolmaz. Daha büyük paketler daha fazla bonus içerir!'
                      : 'Coins are permanent and never expire. Larger packages include more bonus coins!',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(CoinPackage package, String locale, bool isDark) {
    final isPopular = package.id == 'sudoku_clash_coins_500';
    final isBestValue = package.id == 'sudoku_clash_coins_3000';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestValue
              ? Colors.purple
              : isPopular
                  ? Colors.orange
                  : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: isBestValue || isPopular ? 2 : 1,
        ),
        boxShadow: isBestValue || isPopular
            ? [
                BoxShadow(
                  color: (isBestValue ? Colors.purple : Colors.orange).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isBestValue
                          ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                          : isPopular
                              ? [const Color(0xFFFF6B35), const Color(0xFFF7931E)]
                              : [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monetization_on, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.getName(locale),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${package.coins} ${locale == 'tr' ? 'Jeton' : 'Coins'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (package.bonus != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                package.bonus!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Purchase button
                ElevatedButton(
                  onPressed: _purchasing ? null : () => _purchasePackage(package),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBestValue
                        ? Colors.purple
                        : isPopular
                            ? Colors.orange
                            : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _purchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          package.price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Badge
          if (isBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  locale == 'tr' ? 'EN İYİ DEĞER' : 'BEST VALUE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isPopular && !isBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  locale == 'tr' ? 'POPÜLER' : 'POPULAR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

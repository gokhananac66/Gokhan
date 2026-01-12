import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../app_localizations.dart';
import '../widgets/text_3d.dart';

class TokenShopScreen extends StatefulWidget {
  const TokenShopScreen({super.key});

  @override
  State<TokenShopScreen> createState() => _TokenShopScreenState();
}

class _TokenShopScreenState extends State<TokenShopScreen> {
  final TokenService _tokenService = TokenService();
  int _currentTokens = 0;
  bool _isLoading = true;
  List<TokenPackage> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _tokenService.init();

    final tokens = await _tokenService.getTokens();

    setState(() {
      _currentTokens = tokens;
      _packages = _tokenService.products.isEmpty
          ? getDefaultTokenPackages()
          : _tokenService.products.map((p) => TokenPackage(
              id: p.id,
              tokens: _getTokensFromId(p.id),
              price: p.price,
            )).toList();
      _isLoading = false;
    });

    // Jeton güncellemelerini dinle
    _tokenService.onTokensUpdated = (newTokens) {
      setState(() => _currentTokens = newTokens);
    };
  }

  int _getTokensFromId(String id) {
    switch (id) {
      case 'token_pack_100':
        return 100;
      case 'token_pack_500':
        return 500;
      case 'token_pack_1000':
        return 1000;
      default:
        return 0;
    }
  }

  Future<void> _purchasePackage(TokenPackage package) async {
    // Gerçek ürün varsa satın al
    final product = _tokenService.products.firstWhere(
      (p) => p.id == package.id,
      orElse: () => throw Exception('Ürün bulunamadı'),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _tokenService.purchaseTokens(product);
      Navigator.pop(context); // Loading dialog'u kapat

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma işlemi başlatılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text3D(
          text: 'Jeton Mağazası',
          fontSize: 20,
          color: isDark ? Colors.white : Colors.black87,
          shadowColor: isDark ? Colors.black : Colors.grey,
        ),
        actions: [
          // Mevcut jeton göstergesi
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.amber.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_currentTokens',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade300, Colors.amber.shade500],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Jeton Paketleri',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jetonlarla özel temalar ve güçlendirmeler satın al!',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Jeton paketleri
                  ..._packages.map((package) => _buildPackageCard(package, isDark)),

                  const SizedBox(height: 20),

                  // Bilgi metni
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Satın almalar Google Play veya App Store üzerinden işlenir. Tüm satın almalar geri iade edilemez.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(TokenPackage package, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: package.isBestValue
              ? [Colors.purple.shade400, Colors.purple.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (package.isBestValue ? Colors.purple : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Best Value badge
          if (package.isBestValue)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text(
                  'EN İYİ FİYAT',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Jeton ikonu ve miktar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${package.tokens}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Detaylar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${package.tokens} Jeton',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package.bonus.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            package.bonus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Fiyat ve satın al butonu
                ElevatedButton(
                  onPressed: _tokenService.products.isNotEmpty
                      ? () => _purchasePackage(package)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: package.isBestValue ? Colors.purple : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
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
        ],
      ),
    );
  }
}

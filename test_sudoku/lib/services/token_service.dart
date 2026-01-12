import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

/// Jeton (token) yönetim servisi - Singleton
class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  // In-App Purchase instance
  final InAppPurchase _iap = InAppPurchase.instance;

  // Ürün ID'leri (Google Play Console ve App Store Connect'te tanımlanmalı)
  static const String _tokenPack100 = 'token_pack_100';
  static const String _tokenPack500 = 'token_pack_500';
  static const String _tokenPack1000 = 'token_pack_1000';

  // Satın alınabilir ürünler
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Satın alma stream
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Jeton callback'i
  Function(int)? onTokensUpdated;

  /// Servisi başlat
  Future<void> init() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      print('🔴 In-App Purchase mevcut değil');
      return;
    }

    // Satın alma stream'ini dinle
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('🔴 Purchase stream error: $error'),
    );

    // Ürünleri yükle
    await _loadProducts();
  }

  /// Ürünleri yükle
  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      _tokenPack100,
      _tokenPack500,
      _tokenPack1000,
    };

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('🟡 Bulunamayan ürün ID\'leri: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('✅ ${_products.length} ürün yüklendi');
    } catch (e) {
      print('🔴 Ürün yükleme hatası: $e');
    }
  }

  /// Satın alma güncellemelerini işle
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Satın alma başarılı - jeton ekle
        final tokensToAdd = _getTokensForProduct(purchase.productID);
        await addTokens(tokensToAdd);

        // Satın almayı tamamlandı olarak işaretle
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        print('🔴 Satın alma hatası: ${purchase.error}');
      }
    }
  }

  /// Ürün ID'sine göre jeton miktarını döndür
  int _getTokensForProduct(String productId) {
    switch (productId) {
      case _tokenPack100:
        return 100;
      case _tokenPack500:
        return 500;
      case _tokenPack1000:
        return 1000;
      default:
        return 0;
    }
  }

  /// Jeton satın al
  Future<bool> purchaseTokens(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('🔴 Satın alma başlatma hatası: $e');
      return false;
    }
  }

  /// Önceki satın almaları geri yükle
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('🔴 Satın alma geri yükleme hatası: $e');
    }
  }

  // ============= JETON İŞLEMLERİ =============

  /// Mevcut jeton miktarını al
  Future<int> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userTokens') ?? 0;
  }

  /// Jeton ekle
  Future<void> addTokens(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('userTokens') ?? 0;
    final newAmount = current + amount;
    await prefs.setInt('userTokens', newAmount);
    onTokensUpdated?.call(newAmount);
    print('💰 $amount jeton eklendi. Toplam: $newAmount');
  }

  /// Jeton harca
  Future<bool> spendTokens(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('userTokens') ?? 0;

    if (current < amount) {
      print('❌ Yetersiz jeton. Mevcut: $current, Gerekli: $amount');
      return false;
    }

    final newAmount = current - amount;
    await prefs.setInt('userTokens', newAmount);
    onTokensUpdated?.call(newAmount);
    print('💸 $amount jeton harcandı. Kalan: $newAmount');
    return true;
  }

  /// Yeterli jeton var mı kontrol et
  Future<bool> hasEnoughTokens(int amount) async {
    final current = await getTokens();
    return current >= amount;
  }

  /// Kaynakları temizle
  void dispose() {
    _subscription?.cancel();
  }
}

/// Jeton paketleri (UI için)
class TokenPackage {
  final String id;
  final int tokens;
  final String price;
  final String bonus;
  final bool isBestValue;

  TokenPackage({
    required this.id,
    required this.tokens,
    required this.price,
    this.bonus = '',
    this.isBestValue = false,
  });
}

/// Varsayılan jeton paketleri (ürünler yüklenemezse)
List<TokenPackage> getDefaultTokenPackages() {
  return [
    TokenPackage(
      id: 'token_pack_100',
      tokens: 100,
      price: '₺19.99',
    ),
    TokenPackage(
      id: 'token_pack_500',
      tokens: 500,
      price: '₺79.99',
      bonus: '+50 Bonus',
    ),
    TokenPackage(
      id: 'token_pack_1000',
      tokens: 1000,
      price: '₺149.99',
      bonus: '+200 Bonus',
      isBestValue: true,
    ),
  ];
}

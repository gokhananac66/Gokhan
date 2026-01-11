import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'currency_service.dart';

/// Coin packages available for purchase
class CoinPackage {
  final String id;
  final String nameEn;
  final String nameTr;
  final int coins;
  final String price;
  final String? bonus;

  const CoinPackage({
    required this.id,
    required this.nameEn,
    required this.nameTr,
    required this.coins,
    required this.price,
    this.bonus,
  });

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;
}

/// Service for managing in-app purchases
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _available = false;
  List<ProductDetails> _products = [];
  bool _loading = true;

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;
  bool get isLoading => _loading;

  // Product IDs for both platforms
  static const List<String> _productIds = [
    'sudoku_clash_coins_100',   // 100 coins - ₺9.99
    'sudoku_clash_coins_500',   // 500 coins - ₺39.99
    'sudoku_clash_coins_1200',  // 1200 coins - ₺69.99
    'sudoku_clash_coins_3000',  // 3000 coins - ₺149.99
  ];

  // Coin packages info
  static const List<CoinPackage> packages = [
    CoinPackage(
      id: 'sudoku_clash_coins_100',
      nameEn: 'Small Pack',
      nameTr: 'Küçük Paket',
      coins: 100,
      price: '₺9.99',
    ),
    CoinPackage(
      id: 'sudoku_clash_coins_500',
      nameEn: 'Medium Pack',
      nameTr: 'Orta Paket',
      coins: 500,
      price: '₺39.99',
      bonus: '+20%',
    ),
    CoinPackage(
      id: 'sudoku_clash_coins_1200',
      nameEn: 'Large Pack',
      nameTr: 'Büyük Paket',
      coins: 1200,
      price: '₺69.99',
      bonus: '+40%',
    ),
    CoinPackage(
      id: 'sudoku_clash_coins_3000',
      nameEn: 'Mega Pack',
      nameTr: 'Mega Paket',
      coins: 3000,
      price: '₺149.99',
      bonus: '+100%',
    ),
  ];

  /// Initialize IAP service
  Future<void> initialize() async {
    _available = await _iap.isAvailable();

    if (!_available) {
      print('❌ [IAP] In-app purchases not available on this device');
      _loading = false;
      return;
    }

    print('✅ [IAP] In-app purchases available');

    // Platform-specific setup
    // NOTE: iOS delegate setup commented out (optional feature)
    /*
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosAddition = _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosAddition.setDelegate(ExamplePaymentQueueDelegate());
    }
    */

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        print('❌ [IAP] Purchase stream error: $error');
      },
    );

    // Load products
    await loadProducts();
  }

  /// Load available products from store
  Future<void> loadProducts() async {
    if (!_available) {
      _loading = false;
      return;
    }

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds.toSet());

      if (response.error != null) {
        print('❌ [IAP] Error loading products: ${response.error}');
        _loading = false;
        return;
      }

      if (response.productDetails.isEmpty) {
        print('⚠️ [IAP] No products found. Make sure product IDs are configured in Google Play Console / App Store Connect');
      }

      _products = response.productDetails;
      _loading = false;

      print('✅ [IAP] Loaded ${_products.length} products');
      for (var product in _products) {
        print('   - ${product.id}: ${product.title} (${product.price})');
      }
    } catch (e) {
      print('❌ [IAP] Exception loading products: $e');
      _loading = false;
    }
  }

  /// Purchase a coin package
  Future<bool> purchasePackage(String productId) async {
    if (!_available) {
      print('❌ [IAP] Purchases not available');
      return false;
    }

    final ProductDetails? product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      print('❌ [IAP] Product not found: $productId');
      return false;
    }

    print('🛒 [IAP] Initiating purchase: ${product.id}');

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      final bool success = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );

      if (!success) {
        print('❌ [IAP] Purchase failed to initiate');
      }

      return success;
    } catch (e) {
      print('❌ [IAP] Purchase exception: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('📦 [IAP] Purchase update: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('⏳ [IAP] Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('❌ [IAP] Purchase error: ${purchaseDetails.error}');
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {

        print('✅ [IAP] Purchase successful: ${purchaseDetails.productID}');

        // Verify purchase (in production, verify with backend)
        final bool valid = await _verifyPurchase(purchaseDetails);

        if (valid) {
          // Deliver coins to user
          await _deliverCoins(purchaseDetails.productID);
        } else {
          print('❌ [IAP] Purchase verification failed');
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Verify purchase (placeholder - implement server-side verification in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Implement server-side verification
    // For now, trust the purchase
    return true;
  }

  /// Deliver coins to user after successful purchase
  Future<void> _deliverCoins(String productId) async {
    final package = packages.where((p) => p.id == productId).firstOrNull;

    if (package == null) {
      print('❌ [IAP] Unknown product: $productId');
      return;
    }

    print('💰 [IAP] Delivering ${package.coins} coins to user');

    try {
      await CurrencyService().addCoins(package.coins);
      print('✅ [IAP] Coins delivered successfully!');
    } catch (e) {
      print('❌ [IAP] Error delivering coins: $e');
    }
  }

  /// Handle purchase errors
  void _handleError(IAPError error) {
    print('❌ [IAP] Error code: ${error.code}');
    print('❌ [IAP] Error details: ${error.details}');
    print('❌ [IAP] Error message: ${error.message}');
  }

  /// Restore purchases (for iOS)
  Future<void> restorePurchases() async {
    if (!_available) {
      print('❌ [IAP] Purchases not available');
      return;
    }

    try {
      print('🔄 [IAP] Restoring purchases...');
      await _iap.restorePurchases();
      print('✅ [IAP] Restore complete');
    } catch (e) {
      print('❌ [IAP] Error restoring purchases: $e');
    }
  }

  /// Dispose service
  void dispose() {
    _subscription.cancel();
  }
}

/// iOS payment queue delegate
/// NOTE: Commented out because wrapper types are not exported from in_app_purchase_storekit
/// This is an optional iOS feature for payment queue management
/*
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
*/

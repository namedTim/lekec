import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Wraps Google Play Billing (and App Store IAP on iOS) for one-shot
/// "buy me a coffee"-style consumable tips.
///
/// SKUs must be created in Google Play Console → Monetize → In-app products,
/// each as a **consumable**. The four IDs below should match exactly.
class TipService {
  TipService._();
  static final TipService instance = TipService._();

  /// Product IDs configured in Play Console / App Store Connect.
  /// Prices and titles are managed in the store dashboards (per-locale).
  static const Set<String> productIds = {
    'tip_tier_1',
    'tip_tier_2',
    'tip_tier_3',
    'tip_tier_4',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _initialized = false;
  List<ProductDetails> _products = const [];
  String? _initError;

  /// Latest fetched list of products, sorted by price ascending.
  List<ProductDetails> get products => _products;

  /// Human-readable error from the last `initialize()` call, or null.
  String? get initError => _initError;

  /// Whether the storefront is reachable on this device.
  bool get isAvailable => _initialized && _initError == null;

  void Function(ProductDetails product)? _onSuccess;
  void Function(String message)? _onError;
  void Function()? _onPending;
  void Function()? _onCanceled;

  /// Connects to the billing client, queries products, and starts listening
  /// for purchase updates. Safe to call multiple times — subsequent calls
  /// just re-attach the callbacks.
  Future<void> initialize({
    void Function(ProductDetails product)? onSuccess,
    void Function(String message)? onError,
    void Function()? onPending,
    void Function()? onCanceled,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;
    _onPending = onPending;
    _onCanceled = onCanceled;

    if (_initialized) return;

    final available = await _iap.isAvailable();
    if (!available) {
      _initError = 'Trgovina ni na voljo.';
      _initialized = true;
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        developer.log('Purchase stream error', error: e, stackTrace: st, name: 'TipService');
        _onError?.call(e.toString());
      },
    );

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      _initError = response.error!.message;
      developer.log(
        'queryProductDetails error: ${response.error}',
        name: 'TipService',
      );
    } else {
      // Sort by raw amount when available, falling back to price string.
      final list = [...response.productDetails];
      list.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _products = list;
      if (response.notFoundIDs.isNotEmpty) {
        developer.log(
          'IAP product IDs not found: ${response.notFoundIDs}. '
          'Have they been published as active in Play Console?',
          name: 'TipService',
        );
      }
    }

    _initialized = true;
  }

  /// Kick off the buy flow for the given consumable product.
  /// Returns false if the platform refused the launch (already owned,
  /// invalid sig, etc.).
  Future<bool> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _onPending?.call();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final product = _products
              .where((pd) => pd.id == p.productID)
              .cast<ProductDetails?>()
              .firstWhere((_) => true, orElse: () => null);
          if (product != null) _onSuccess?.call(product);
          // Explicitly consume on Android so the user can tip again later.
          if (Platform.isAndroid) {
            final android = _iap.getPlatformAddition<
                InAppPurchaseAndroidPlatformAddition>();
            await android.consumePurchase(p);
          }
          break;
        case PurchaseStatus.error:
          _onError?.call(p.error?.message ?? 'Neznana napaka.');
          break;
        case PurchaseStatus.canceled:
          _onCanceled?.call();
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// Tear down stream subscription. Call from app shutdown if needed.
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }
}

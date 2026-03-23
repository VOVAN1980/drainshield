import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'pro_service.dart';

enum BillingStatus { loading, ready, error, processing }

class BillingService extends ChangeNotifier {
  static final BillingService instance = BillingService._();
  BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  BillingStatus _status = BillingStatus.loading;
  BillingStatus get status => _status;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  final List<PurchaseDetails> _activePurchases = [];
  List<PurchaseDetails> get activePurchases => _activePurchases;

  final Set<String> _productIds = {'pro_monthly', 'pro_yearly'};

  Future<void> init() async {
    debugPrint("[BillingService] Initializing (kIsWeb=$kIsWeb, review=${ProService.isReviewBuild})...");
    
    if (ProService.isReviewBuild) {
      debugPrint("[BillingService] Review build detected, skipping billing init.");
      _status = BillingStatus.ready;
      notifyListeners();
      return;
    }

    // Web does not support in_app_purchase usually, and it's a common hang point
    if (kIsWeb) {
      debugPrint("[BillingService] Web detected, skipping billing init.");
      _status = BillingStatus.ready;
      notifyListeners();
      return;
    }

    try {
      final bool available = await _iap.isAvailable().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint("[BillingService] isAvailable() timed out after 5s.");
          return false;
        },
      );

      debugPrint("[BillingService] IAP available: $available");
      if (!available) {
        _status = BillingStatus.error;
        notifyListeners();
        return;
      }

      final purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () {
          debugPrint("[BillingService] stream done.");
          _subscription.cancel();
        },
        onError: (error) => debugPrint("[BillingService] stream error: $error"),
      );

      await loadProducts().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("[BillingService] loadProducts() timed out after 10s.");
        },
      );
      
      debugPrint("[BillingService] Initialization complete.");
    } catch (e) {
      debugPrint("[BillingService] CRITICAL Error during init: $e");
      _status = BillingStatus.error;
    } finally {
      if (_status == BillingStatus.loading) {
        _status = BillingStatus.ready; // Ensure we don't hang UI
      }
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    debugPrint("[BillingService] loadProducts() started...");
    _status = BillingStatus.loading;
    notifyListeners();

    try {
      final response = await _iap.queryProductDetails(_productIds).timeout(
        const Duration(seconds: 7),
      );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("[BillingService] Products not found: ${response.notFoundIDs}");
      }
      _products = response.productDetails;
      _status = BillingStatus.ready;
      debugPrint("[BillingService] Products loaded: ${_products.length}");
    } catch (e) {
      debugPrint("[BillingService] Failed to load products: $e");
      _status = BillingStatus.error;
    }
    notifyListeners();
  }

  Future<void> buyMonthly() async {
    final product = _products.firstWhere(
      (p) => p.id == 'pro_monthly',
      orElse: () => throw Exception("Monthly product not found"),
    );
    await _buy(product);
  }

  Future<void> buyYearly() async {
    final product = _products.firstWhere(
      (p) => p.id == 'pro_yearly',
      orElse: () => throw Exception("Yearly product not found"),
    );
    await _buy(product);
  }

  Future<void> _buy(ProductDetails product) async {
    _status = BillingStatus.processing;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _status = BillingStatus.ready;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    _status = BillingStatus.processing;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("Restore error: $e");
    } finally {
      _status = BillingStatus.ready;
      notifyListeners();
    }
  }

  Future<void> manageSubscription() async {
    // In a real app, this would open the Play Store / App Store subscription management page.
    // For now, it's a placeholder.
    debugPrint("Opening subscription management...");
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    bool hasNewPurchases = false;

    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _status = BillingStatus.processing;
      } else if (purchase.status == PurchaseStatus.error) {
        _status = BillingStatus.ready;
        debugPrint("Purchase error: ${purchase.error}");
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _status = BillingStatus.ready;

        // Update active purchases
        final index = _activePurchases
            .indexWhere((p) => p.productID == purchase.productID);
        if (index != -1) {
          _activePurchases[index] = purchase;
        } else {
          _activePurchases.add(purchase);
        }
        hasNewPurchases = true;

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _activePurchases.removeWhere((p) => p.productID == purchase.productID);
        hasNewPurchases = true;
        _status = BillingStatus.ready;
      }
    }

    if (hasNewPurchases) {
      notifyListeners();
    } else {
      // If we got a list but nothing is purchased/restored/pending,
      // we might need to notify anyway if we are expecting a sync.
      notifyListeners();
    }
  }

  bool hasActiveEntitlement(String productId) {
    return _activePurchases.any((p) =>
        p.productID == productId &&
        (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
    final bool available = await _iap.isAvailable();
    if (!available) {
      _status = BillingStatus.error;
      notifyListeners();
      return;
    }

    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("Billing error: $error"),
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    _status = BillingStatus.loading;
    notifyListeners();

    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Products not found: ${response.notFoundIDs}");
      }
      _products = response.productDetails;
      _status = BillingStatus.ready;
    } catch (e) {
      debugPrint("Failed to load products: $e");
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

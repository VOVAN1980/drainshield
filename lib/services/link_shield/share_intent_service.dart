import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles incoming shared URLs from Android Share Intent.
///
/// Supports two flows:
/// 1. Cold start — app launched via share, URL extracted from initial intent.
/// 2. Warm start — app already running, URL received via onNewIntent.
class ShareIntentService extends ChangeNotifier {
  static final ShareIntentService instance = ShareIntentService._internal();
  ShareIntentService._internal();

  static const _channel = MethodChannel('app.drainshield.guard/share');

  String? _pendingUrl;

  /// Whether there is a shared URL waiting to be processed.
  bool get hasPendingUrl => _pendingUrl != null;

  /// The pending shared URL, if any.
  String? get pendingUrl => _pendingUrl;

  /// Initialize the service: check for initial shared URL and listen for new ones.
  Future<void> init() async {
    // Listen for warm-start shares (app already running)
    _channel.setMethodCallHandler(_handleMethodCall);

    // Check for cold-start share (app launched via share)
    try {
      final initialUrl =
          await _channel.invokeMethod<String>('getInitialSharedUrl');
      if (initialUrl != null && initialUrl.isNotEmpty) {
        _pendingUrl = initialUrl;
        debugPrint('[ShareIntent] Cold start URL: $initialUrl');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ShareIntent] No initial shared URL: $e');
    }
  }

  /// Handle method calls from native side (warm start).
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSharedUrl') {
      final url = call.arguments as String?;
      if (url != null && url.isNotEmpty) {
        _pendingUrl = url;
        debugPrint('[ShareIntent] Warm start URL: $url');
        notifyListeners();
      }
    }
  }

  /// Consume and clear the pending URL. Returns null if no URL pending.
  String? consumePendingUrl() {
    final url = _pendingUrl;
    _pendingUrl = null;
    return url;
  }
}

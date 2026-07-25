package app.drainshield.guard

import android.content.Intent
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "app.drainshield.guard/share"
    }

    private var initialSharedUrl: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // Capture URL from cold-start share intent
        initialSharedUrl = extractUrl(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedUrl" -> {
                        result.success(initialSharedUrl)
                        initialSharedUrl = null // consume once
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val url = extractUrl(intent) ?: return
        // Send to Flutter via MethodChannel (warm start)
        flutterEngine?.dartExecutor?.let {
            MethodChannel(it.binaryMessenger, CHANNEL)
                .invokeMethod("onSharedUrl", url)
        }
    }

    /**
     * Extracts a URL from an ACTION_SEND intent.
     * Handles cases where the shared text contains a URL surrounded by other text
     * (e.g. Telegram shares "Check this out: https://example.com via @user").
     */
    private fun extractUrl(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type != "text/plain") return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
        val urlRegex = Regex("https?://[^\\s]+")
        return urlRegex.find(text)?.value
    }
}

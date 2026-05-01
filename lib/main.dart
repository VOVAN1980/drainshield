import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:reown_appkit/reown_appkit.dart";
import "services/localization_service.dart";
import "services/spender_intelligence_service.dart";
import "services/update_service.dart";
import "screens/boot_screen.dart";
import "screens/settings/update_screen.dart";
import "package:workmanager/workmanager.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize what's needed for the background task
      // Note: background tasks are isolated, so services need to be ready
      await UpdateService.instance.initBackground();
      return Future.value(true);
    } catch (e) {
      debugPrint('[Workmanager] Task failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Register the daily update check task
  await Workmanager().registerPeriodicTask(
    "1",
    "app_update_check",
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 5), // Wait a bit after 1st install
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Basic production-safe error capture
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("[DrainShield] Framework error: ${details.exception}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("[DrainShield] Async error: $error");
    return true;
  };

  // Basic infrastructure needed for the App widget itself
  await LocalizationService.instance.load(const Locale('en'));
  await SpenderIntelligenceService.instance.init();

  runApp(const DrainShieldApp());
}

class DrainShieldApp extends StatefulWidget {
  const DrainShieldApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) async {
    await LocalizationService.instance.load(newLocale);
    context.findAncestorStateOfType<_DrainShieldAppState>()?.updateLocale(
          newLocale,
        );
  }

  @override
  State<DrainShieldApp> createState() => _DrainShieldAppState();
}

class _DrainShieldAppState extends State<DrainShieldApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _fetchLocale();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Wait for the first frame to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result =
          await UpdateService.instance.checkForUpdates(isAutoCheck: true);
      if (result.status == UpdateStatus.updateAvailable && mounted) {
        _showUpdateDialog(result);
      }
    });
  }

  void _showUpdateDialog(UpdateCheckResult result) {
    final t = LocalizationService.instance;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              t.t('settingsUpdateTitle').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('settingsUpdateNewMsg', {'version': result.latestDisplay}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.t('settingsAboutVersion', {'version': result.currentDisplay}),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t.t('settingsUpdateActionLater').toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UpdateService.instance.launchStore(customUrl: result.updateUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.2),
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              t.t('settingsUpdateActionUpdate').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code');
    Locale activeLocale;
    if (code != null) {
      activeLocale = Locale(code);
    } else {
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      const supported = [
        'en',
        'ru',
        'de',
        'fr',
        'es',
        'pt',
        'tr',
        'ar',
        'zh',
        'hi',
        'ja',
        'ko',
        'it',
        'pl',
        'uk',
        'id',
        'vi',
      ];
      activeLocale = Locale(supported.contains(deviceCode) ? deviceCode : 'en');
    }
    await LocalizationService.instance.load(activeLocale);
    setState(() => _locale = activeLocale);
  }

  void updateLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return const SizedBox
          .shrink(); // Wait until locale is loaded to avoid brief wrong language flash
    }
    return LocalizationProvider(
      service: LocalizationService.instance,
      locale: _locale!,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: "DrainShield",
        theme: ThemeData.dark().copyWith(
          bottomSheetTheme: const BottomSheetThemeData(
            elevation: 0,
            backgroundColor: Colors.transparent,
            clipBehavior: Clip.none,
          ),
        ),
        locale: _locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
          Locale('de'),
          Locale('fr'),
          Locale('es'),
          Locale('pt'),
          Locale('tr'),
          Locale('ar'),
          Locale('zh'),
          Locale('hi'),
          Locale('ja'),
          Locale('ko'),
          Locale('it'),
          Locale('pl'),
          Locale('uk'),
          Locale('id'),
          Locale('vi'),
        ],
        builder: (context, child) {
          return Material(
            child: ReownAppKitModalTheme(
              isDarkMode: true,
              themeData: const ReownAppKitModalThemeData(
                radiuses: ReownAppKitModalRadiuses.square,
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(0.85),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: const BootScreen(),
        routes: {
          '/update': (context) => const UpdateScreen(),
        },
      ),
    );
  }
}

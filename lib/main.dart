import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "services/localization_service.dart";
import "screens/boot_screen.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        theme: ThemeData.dark(),
        locale: _locale,
        home: const BootScreen(),
      ),
    );
  }
}

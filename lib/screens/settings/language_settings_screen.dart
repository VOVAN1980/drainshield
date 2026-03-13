import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/localization_service.dart';
import '../../main.dart';
import '../../widgets/design/ds_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _currentLang = 'en';

  static const Map<String, String> _nativeNames = {
    'en': 'English',
    'ru': 'Русский',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português (Brasil)',
    'tr': 'Türkçe',
    'ar': 'العربية',
    'zh': '中文',
    'hi': 'हिन्दी',
    'ja': '日本語',
    'ko': '한국어',
    'it': 'Italiano',
    'pl': 'Polski',
    'uk': 'Українська',
    'id': 'Bahasa Indonesia',
    'vi': 'Tiếng Việt',
  };

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code');
    if (saved != null) {
      setState(() => _currentLang = saved);
    } else {
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      setState(
        () => _currentLang =
            _nativeNames.containsKey(deviceCode) ? deviceCode : 'en',
      );
    }
  }

  Future<void> _setLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    setState(() => _currentLang = code);
    if (mounted) {
      DrainShieldApp.setLocale(context, Locale(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(context, loc.t('settingsLanguage')),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: _nativeNames.length,
                itemBuilder: (context, i) {
                  final code = _nativeNames.keys.elementAt(i);
                  final name = _nativeNames.values.elementAt(i);
                  final isSelected = code == _currentLang;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00FF9D).withOpacity(0.08)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00FF9D).withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _setLang(code),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00FF9D)
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00FF9D),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

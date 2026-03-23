import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_background.dart';
import '../config/app_colors.dart';
import '../widgets/mascot_image.dart';
import 'settings/notifications_settings_screen.dart';
import 'settings/sounds_settings_screen.dart';
import 'settings/security_settings_screen.dart';
import 'settings/subscription_screen.dart';
import 'settings/language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    loc.t('settingsTitle'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const MascotImage(
              mascotState: MascotState.settings,
              width: 250,
              height: 250,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildSectionHeader(loc.t('settingsAccount')),
                  _buildSettingsRow(
                    context,
                    loc.t('settingsSubscription'),
                    Icons.star_outline,
                    const SubscriptionScreen(),
                    isPremium: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(loc.t('settingsSecurity')),
                  _buildSettingsRow(
                    context,
                    loc.t('settingsSecurityEvents'),
                    Icons.security_outlined,
                    const SecuritySettingsScreen(),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(loc.t('settingsPreferences')),
                  _buildSettingsRow(
                    context,
                    loc.t('settingsLanguage'),
                    Icons.language,
                    const LanguageSettingsScreen(),
                  ),
                  _buildSettingsRow(
                    context,
                    loc.t('settingsNotifications'),
                    Icons.notifications_none_outlined,
                    const NotificationsSettingsScreen(),
                  ),
                  _buildSettingsRow(
                    context,
                    loc.t('settingsSound'),
                    Icons.volume_up_outlined,
                    const SoundsSettingsScreen(),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(loc.t('settingsAboutTitle')),
                  _buildAboutSection(context, loc),
                  const SizedBox(height: 32),
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        "Version ${_packageInfo?.version ?? '...'}",
                        style: const TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.tertiaryText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, LocalizationService loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSettingsRow(
            context,
            loc.t('settingsAboutTitle'),
            Icons.info_outline,
            _buildLegalScreen(context, loc, loc.t('settingsAboutTitle'),
                loc.t('settingsAboutContent')),
            isTransparent: true,
          ),
          _buildExternalLinkRow(
            context,
            loc.t('settingsAboutPrivacy'),
            Icons.privacy_tip_outlined,
            'https://vovan1980.github.io/drainshield/privacy.html',
          ),
          _buildExternalLinkRow(
            context,
            loc.t('settingsAboutTerms'),
            Icons.description_outlined,
            'https://vovan1980.github.io/drainshield/terms.html',
          ),
          _buildSettingsRow(
            context,
            loc.t('settingsAboutDisclaimer'),
            Icons.gavel_outlined,
            _buildLegalScreen(context, loc, loc.t('settingsAboutDisclaimer'),
                loc.t('settingsDisclaimerContent')),
            isTransparent: true,
          ),
          _buildSettingsRow(
            context,
            loc.t('settingsAboutContact'),
            Icons.support_agent_outlined,
            _buildSupportScreen(context, loc),
            isTransparent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalScreen(BuildContext context, LocalizationService loc,
      String title, String content) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 32, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportScreen(BuildContext context, LocalizationService loc) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 32, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    loc.t('settingsAboutSupport'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00FF9D).withOpacity(0.05),
                        border: Border.all(
                          color: const Color(0xFF00FF9D).withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        size: 64,
                        color: Color(0xFF00FF9D),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      loc.t('settingsSupportTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.t('settingsSupportSub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.tertiaryText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildContactCard(
                      loc,
                      loc.t('settingsSupportEmailLabel'),
                      loc.t('settingsSupportEmailValue'),
                      Icons.mail_outline,
                      () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: loc.t('settingsSupportEmailValue'),
                          query: 'subject=DrainShield Support Request',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF9D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.t('settingsSupportResponseTime'),
                            style: const TextStyle(
                              color: AppColors.tertiaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    LocalizationService loc,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF9D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00FF9D),
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.tertiaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.tertiaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalLinkRow(
    BuildContext context,
    String title,
    IconData icon,
    String url,
  ) {
    return _buildSettingsRow(
      context,
      title,
      icon,
      const SizedBox.shrink(), // Dummy, won't be used
      isTransparent: true,
      onOverrideTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _buildSettingsRow(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen, {
    bool isPremium = false,
    bool isCompact = false,
    bool isTransparent = false,
    VoidCallback? onOverrideTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: isTransparent
              ? Colors.transparent
              : isPremium
                  ? Colors.orange.withOpacity(0.05)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTransparent
                ? Colors.transparent
                : isPremium
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
          ),
        ),
        child: ListTile(
          onTap: () {
            if (onOverrideTap != null) {
              onOverrideTap();
            } else {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => screen));
            }
          },
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPremium
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.tertiaryText,
              size: 18,
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPremium ? Colors.orange.withOpacity(0.9) : Colors.white,
              fontSize: 15,
              fontWeight: isPremium ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: isPremium
                ? Colors.orange.withOpacity(0.3)
                : AppColors.tertiaryText,
            size: 14,
          ),
          dense: isCompact,
        ),
      ),
    );
  }
}

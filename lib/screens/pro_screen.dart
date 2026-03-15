import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';
import '../services/pro/pro_service.dart';
import '../models/pro_status.dart';
import '../widgets/design/ds_background.dart';
import '../config/app_colors.dart';
import '../services/pro/billing_service.dart';
import '../widgets/mascot_image.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final proService = ProService.instance;
    final billing = BillingService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([proService, billing]),
      builder: (context, _) {
        final status = proService.status;
        final isProcessing = billing.status == BillingStatus.processing;

        return Scaffold(
          backgroundColor: const Color(0xFF030509),
          body: DsBackground(
            accentColor: const Color(0xFFFFD25A),
            child: Stack(
              children: [
                // ── Scrollable Content ──────────────────────────────
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 270, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!status.isPro || _isExpiring(status)) ...[
                          _buildPlanSelector(loc),
                          const SizedBox(height: 32),
                        ],
                        _buildSubscriptionDetails(loc, status),
                        const SizedBox(height: 32),
                        _buildFeatureSection(loc),
                        const SizedBox(height: 48),
                        if (isProcessing)
                          const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFFD25A)),
                          )
                        else
                          _buildMainAction(loc, status, billing),
                        const SizedBox(height: 24),
                        _buildFooter(loc, billing),
                      ],
                    ),
                  ),
                ),

                // ── Fixed Gold Header ───────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildGoldHeader(context, loc),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isExpiring(ProStatus status) {
    if (!status.isPro || status.expiryDate == null) return false;
    return status.expiryDate!.difference(DateTime.now()).inDays < 3;
  }

  Widget _buildGoldHeader(BuildContext context, LocalizationService loc) {
    return Container(
      height: 270,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF030509),
            const Color(0xFF030509).withOpacity(0.95),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.tertiaryText),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.symmetric(vertical: 8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DRAINSHIELD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "PRO",
                      style: TextStyle(
                        color: Color(0xFFFFD25A),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.t('proValueProp'),
                      style: const TextStyle(
                        color: AppColors.tertiaryText,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const MascotImage(
                mascotState: MascotState.pro,
                width: 220,
                height: 220,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(LocalizationService loc) {
    return Row(
      children: [
        Expanded(child: _buildPlanCard(loc, false)),
        const SizedBox(width: 16),
        Expanded(child: _buildPlanCard(loc, true)),
      ],
    );
  }

  Widget _buildPlanCard(LocalizationService loc, bool isYearly) {
    final bool isSelected = _isYearly == isYearly;
    const activeColor = Color(0xFFFFD25A);

    return GestureDetector(
      onTap: () => setState(() => _isYearly = isYearly),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isYearly ? loc.t('proYearlyPlan') : loc.t('proMonthlyPlan'),
                  style: TextStyle(
                    color: isSelected ? activeColor : AppColors.tertiaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (isYearly)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "HOT",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isYearly ? loc.t('proPriceYearly') : loc.t('proPriceMonthly'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isYearly)
              Text(
                "SAVE 33%",
                style: TextStyle(
                  color: activeColor.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails(LocalizationService loc, ProStatus status) {
    if (status.expiryDate == null) return const SizedBox.shrink();

    final df = DateFormat('dd MMM yyyy');
    final dateStr = df.format(status.expiryDate!);
    final isExpired = status.expiryDate!.isBefore(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired
                    ? Icons.history_rounded
                    : Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.tertiaryText,
              ),
              const SizedBox(width: 8),
              Text(
                loc.t(isExpired ? 'proStatusExpiredOn' : 'proStatusRenews',
                    {'date': dateStr}),
                style: const TextStyle(
                    color: AppColors.tertiaryText, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(loc.t('settingsSubscriptionWalletLimit'),
              status.maxWallets.toString()),
          const SizedBox(height: 8),
          _buildDetailRow(loc.t('settingsAboutSupport'),
              loc.t('settingsSecurityMonitoringActive')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFeatureSection(LocalizationService loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(loc.t('proFeatureAvailable')),
        const SizedBox(height: 20),
        _buildFeatureItem(loc.t('proMonitoringTitle'),
            loc.t('proMonitoringSub'), Icons.radar_rounded),
        _buildFeatureItem(
            loc.t('proRevokeTitle'), loc.t('proRevokeSub'), Icons.bolt_rounded),
        _buildFeatureItem(loc.t('proMultiWalletTitle'),
            loc.t('proMultiWalletSub'), Icons.account_balance_wallet_rounded),
        _buildFeatureItem(loc.t('proAlertsTitle'), loc.t('proAlertsSub'),
            Icons.notifications_active_rounded),
        _buildFeatureItem(loc.t('proFreezeTitle'), loc.t('proFreezeSub'),
            Icons.ac_unit_rounded),
        const SizedBox(height: 12),
        _buildSectionHeader(loc.t('proFeatureDevelopment')),
        const SizedBox(height: 20),
        _buildFeatureItem(
            loc.t('proEpkTitle'), loc.t('proEpkSub'), Icons.security_rounded,
            isComingSoon: true),
        _buildFeatureItem(loc.t('proIntelTitle'), loc.t('proIntelSub'),
            Icons.psychology_rounded,
            isComingSoon: true),
      ],
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.tertiaryText,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFeatureItem(String title, String sub, IconData icon,
      {bool isComingSoon = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isComingSoon
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFFFD25A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isComingSoon
                    ? Colors.white.withOpacity(0.42)
                    : const Color(0xFFFFD25A),
                size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isComingSoon ? AppColors.tertiaryText : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
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
    );
  }

  Widget _buildMainAction(
      LocalizationService loc, ProStatus status, BillingService billing) {
    if (status.isPro && !_isExpiring(status)) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: OutlinedButton(
          onPressed: () => billing.manageSubscription(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            loc.t('proManageSubscription'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD25A), Color(0xFFFDBB2D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD25A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (_isYearly) {
            await billing.buyYearly();
          } else {
            await billing.buyMonthly();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          loc.t('proUpgradeBtn'),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildFooter(LocalizationService loc, BillingService billing) {
    return Column(
      children: [
        Center(
          child: Text(
            loc.t('proPriceCancelHint'),
            style: const TextStyle(color: AppColors.tertiaryText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => billing.restorePurchases(),
            child: Text(
              loc.t('proRestoreBtn'),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

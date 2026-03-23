import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/security/security_event_service.dart';
import '../services/localization_service.dart';
import '../models/security_event.dart';
import '../widgets/design/ds_background.dart';
import '../config/app_colors.dart';
import '../services/pro/pro_service.dart';
import 'pro_screen.dart';

class SecurityEventsScreen extends StatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  State<SecurityEventsScreen> createState() => _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends State<SecurityEventsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(context, loc.t('settingsSecurityEvents')),
            Expanded(
              child: ListenableBuilder(
                listenable: SecurityEventService.instance,
                builder: (context, _) {
                  final events = SecurityEventService
                      .instance.cachedEvents.reversed
                      .toList();

                  if (events.isEmpty) {
                    return _buildEmptyState(loc);
                  }

                  final bool isPro = ProService.instance.isProActive();
                  final int eventsToShow = isPro ? events.length : events.length.clamp(0, 5);

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: eventsToShow,
                    itemBuilder: (context, index) {
                      return _buildEventTile(events[index]);
                    },
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
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined,
                color: Colors.white.withOpacity(0.7)),
            onPressed: () => _confirmClear(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LocalizationService loc) {
    final isPro = ProService.instance.isProActive();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('eventsEmptyTitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPro ? loc.t('eventsEmptyMsgPro') : loc.t('eventsEmptyMsgFree'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (!isPro) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.t('eventsEmptyUpgradeBtn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProUpgradeCard(LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.black, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('eventsUpgradeProTitle'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.t('eventsUpgradeProSub'),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                loc.t('eventsUpgradeBtn'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(SecurityEvent event) {
    final timeFormat = DateFormat('HH:mm, dd MMM');
    final color = _getSeverityColor(event.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getEventIcon(event.type), color: color, size: 20),
        ),
        title: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              event.message,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeFormat.format(event.timestamp),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () => _showDetails(event),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.amber;
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getEventIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.highRiskApproval:
      case SecurityEventType.unlimitedApproval:
        return Icons.warning_amber_rounded;
      case SecurityEventType.threatDbHit:
        return Icons.gpp_bad_outlined;
      case SecurityEventType.panicTriggered:
        return Icons.emergency;
      case SecurityEventType.revokeCompleted:
        return Icons.verified_user_outlined;
      case SecurityEventType.subscriptionExpiring:
        return Icons.credit_card;
      case SecurityEventType.monitoringCheckFailed:
        return Icons.error_outline;
      case SecurityEventType.walletConnected:
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _showDetails(SecurityEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF030509),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event.message,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 15,
                ),
              ),
              if (event.walletAddress != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow('Wallet', event.walletAddress!),
              ],
              if (event.metadata.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadata',
                  style: TextStyle(
                    color: AppColors.tertiaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...event.metadata.entries
                    .map((e) => _buildDetailRow(e.key, e.value.toString())),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title:
            const Text('Clear Events?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete all security logs.',
            style: TextStyle(color: AppColors.tertiaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.tertiaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecurityEventService.instance.clearAll();
    }
  }

  Widget _buildLockedHistoryTile(LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline,
                    color: Colors.white.withOpacity(0.3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('eventsHistoryLockedTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.t('eventsHistoryLockedSub'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: const Color(0xFFFFD700).withOpacity(0.5)),
                foregroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                loc.t('eventsUpgradeBtn'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

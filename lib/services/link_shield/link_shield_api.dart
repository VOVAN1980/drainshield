// DrainShield Link Shield API client.
//
// Calls the Cloudflare Worker backend for link scanning, reporting, and labeling.
// Falls back to local analyzer if backend is unreachable.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/link_scan_result.dart';

class LinkShieldApi {
  static const String _baseUrl =
      'https://drainshield-linkshield-api.drainshieldguard.workers.dev';
  static const Duration _timeout = Duration(seconds: 8);

  // Unique device hash for rate limiting (anonymous).
  static String? _deviceHash;

  static Future<String> _getDeviceHash() async {
    if (_deviceHash != null) return _deviceHash!;
    // Generate a stable anonymous ID
    final raw =
        '${Platform.operatingSystem}_${Platform.operatingSystemVersion}_${DateTime.now().millisecondsSinceEpoch}';
    _deviceHash = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
    return _deviceHash!;
  }

  // Scan a URL via the backend.
  // Returns null if backend is unreachable (caller should fall back to local).
  static Future<BackendScanResult?> scanLink(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/scan-link'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return BackendScanResult.fromJson(data);
        }
      }
      debugPrint('[LinkShieldApi] scan failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[LinkShieldApi] scan error: $e');
      return null;
    }
  }

  // Report a link as scam/phishing/drainer.
  static Future<bool> reportLink({
    required String url,
    required String reportType,
    String? userLabel,
    String? userComment,
  }) async {
    try {
      final deviceHash = await _getDeviceHash();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/report-link'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'url': url,
              'reportType': reportType,
              'userLabel': userLabel,
              'userComment': userComment,
              'deviceHash': deviceHash,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[LinkShieldApi] report error: $e');
      return false;
    }
  }

  // Label a link (user describes what this site is).
  static Future<bool> labelLink({
    required String url,
    required String label,
    String? comment,
  }) async {
    try {
      final deviceHash = await _getDeviceHash();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/label-link'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'url': url,
              'label': label,
              'comment': comment,
              'deviceHash': deviceHash,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[LinkShieldApi] label error: $e');
      return false;
    }
  }
}

// Parsed backend scan result.
class BackendScanResult {
  final String domain;
  final String verdict;
  final int riskScore;
  final String confidence;
  final List<String> reasons;
  final int reportCount;
  final List<String> userLabels;
  final bool cached;

  const BackendScanResult({
    required this.domain,
    required this.verdict,
    required this.riskScore,
    required this.confidence,
    required this.reasons,
    required this.reportCount,
    required this.userLabels,
    required this.cached,
  });

  factory BackendScanResult.fromJson(Map<String, dynamic> json) {
    return BackendScanResult(
      domain: json['domain'] ?? '',
      verdict: json['verdict'] ?? 'low_data',
      riskScore: json['riskScore'] ?? 25,
      confidence: json['confidence'] ?? 'low',
      reasons: List<String>.from(json['reasons'] ?? []),
      reportCount: json['reportCount'] ?? 0,
      userLabels: List<String>.from(json['userLabels'] ?? []),
      cached: json['cached'] ?? false,
    );
  }

  // Convert backend verdict string to LinkVerdict enum.
  LinkVerdict toVerdict() {
    switch (verdict) {
      case 'trusted':
        return LinkVerdict.trusted;
      case 'low_data':
        return LinkVerdict.lowData;
      case 'suspicious':
        return LinkVerdict.suspicious;
      case 'high_risk':
        return LinkVerdict.highRisk;
      case 'confirmed_scam':
        return LinkVerdict.confirmedScam;
      default:
        return LinkVerdict.lowData;
    }
  }

  // Convert backend confidence string to LinkConfidence enum.
  LinkConfidence toConfidence() {
    return confidence == 'high' ? LinkConfidence.high : LinkConfidence.low;
  }

  // Convert to LinkScanResult model for the UI.
  LinkScanResult toScanResult(String originalUrl) {
    final v = toVerdict();
    DomainReputation rep;
    switch (v) {
      case LinkVerdict.trusted:
        rep = DomainReputation.clean;
        break;
      case LinkVerdict.highRisk:
      case LinkVerdict.confirmedScam:
        rep = DomainReputation.listed;
        break;
      case LinkVerdict.suspicious:
        rep = DomainReputation.suspicious;
        break;
      default:
        rep = DomainReputation.notVerified;
    }

    return LinkScanResult(
      originalUrl: originalUrl,
      verdict: v,
      confidence: toConfidence(),
      riskScore: riskScore,
      domainInfo: DomainInfo(
        domain: domain,
        age: DomainAge.unknown,
        reputation: rep,
      ),
      web3Signals: const [],
      riskFactors: reasons,
      scannedAt: DateTime.now(),
      isOfflineResult: false,
    );
  }
}

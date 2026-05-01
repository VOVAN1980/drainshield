import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../config/address_validator.dart';
import "scan_screen.dart";

class WalletInputScreen extends StatefulWidget {
  const WalletInputScreen({super.key});
  @override
  State<WalletInputScreen> createState() => _WalletInputScreenState();
}

class _WalletInputScreenState extends State<WalletInputScreen> {
  final TextEditingController _ctl = TextEditingController();
  String _detectedChain = 'unknown';

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _ctl.removeListener(_onAddressChanged);
    _ctl.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final addr = _ctl.text.trim();
    final detected = AddressValidator.detectChainType(addr);
    if (detected != _detectedChain) {
      setState(() => _detectedChain = detected);
    }
  }

  void _go() {
    final addr = _ctl.text.trim();
    if (addr.isEmpty || _detectedChain == 'unknown') return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          address: addr,
          chainType: _detectedChain,
        ),
      ),
    );
  }

  Color _chainColor() {
    switch (_detectedChain) {
      case 'evm':
        return const Color(0xFF00FF9D);
      case 'solana':
        return const Color(0xFF9945FF);
      case 'tron':
        return const Color(0xFFFF0013);
      default:
        return Colors.white24;
    }
  }

  IconData _chainIcon() {
    switch (_detectedChain) {
      case 'evm':
        return Icons.hexagon_outlined;
      case 'solana':
        return Icons.brightness_5;
      case 'tron':
        return Icons.diamond_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final isValid = _detectedChain != 'unknown' && _ctl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.t('walletScanTitle')),
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 64, color: Colors.greenAccent),
              const SizedBox(height: 20),

              // Address input
              TextField(
                controller: _ctl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF141A22),
                  hintText: 'EVM / Solana / Tron address',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _detectedChain != 'unknown'
                      ? Icon(_chainIcon(), color: _chainColor(), size: 20)
                      : null,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              // Chain detection badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _chainColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _chainColor().withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_chainIcon(), color: _chainColor(), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _detectedChain == 'unknown'
                          ? 'Enter wallet address'
                          : '${AddressValidator.chainDisplayName(_detectedChain)} detected ✓',
                      style: TextStyle(
                        color: _chainColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Scan button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isValid ? _go : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? _chainColor() : Colors.grey[800],
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white24,
                  ),
                  child: Text(loc.t('walletScanStartBtn')),
                ),
              ),

              // Manual address note
              if (_detectedChain != 'unknown')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _detectedChain == 'evm'
                        ? 'Full scan + revoke available'
                        : 'Full scan available • Connect wallet for Panic Mode',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

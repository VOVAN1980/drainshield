import "package:flutter/material.dart";
import "../services/localization_service.dart";
import "scan_screen.dart";

class WalletInputScreen extends StatelessWidget {
  const WalletInputScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final ctl = TextEditingController(
      text: "0x0000000000000000000000000000000000001000",
    );
    void go() {
      final addr = ctl.text.trim();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanScreen(address: addr)),
      );
    }

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
              TextField(
                controller: ctl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF141A22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: go,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(loc.t('walletScanStartBtn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

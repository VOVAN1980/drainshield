$fp=".\lib\screens\dashboard_screen.dart"
$c=Get-Content $fp -Raw
if($c -notmatch "package:reown_appkit/reown_appkit.dart"){
  $c = $c -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`r`nimport 'package:reown_appkit/reown_appkit.dart';"
}
if($c -notmatch "late final ReownAppKitModal _appKitModal"){
  $c = $c -replace "(final Random _rnd = Random\(\);\s*)", "`$1`r`n  late final ReownAppKitModal _appKitModal;`r`n"
}
if($c -notmatch "projectId: `"e0108dbbf82ce1cde54203daebdfa14d`""){
$insert=@"
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: `"e0108dbbf82ce1cde54203daebdfa14d`",
      logLevel: LogLevel.error,
      metadata: const PairingMetadata(
        name: `"DrainShield`",
        description: `"Wallet Approval Risk Scanner & Revoke Tool`",
        url: `"https://drainshield.app`",
        icons: [`"https://avatars.githubusercontent.com/u/37784886`"],
        redirect: Redirect(
          native: `"drainshield://`",
          universal: `"https://drainshield.app`",
          linkMode: false,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try { await _appKitModal.init(); } catch (_) {}
    });
"@
  $c = [regex]::Replace($c,'void initState\(\)\s*\{\s*super\.initState\(\);\s*',"void initState() {`r`n    super.initState();`r`n$insert",1)
}
$c = [regex]::Replace($c,'(?s)Future<void>\s+_connectWallet\(\)\s+async\s*\{.*?\n\s*\}\s*\n\s*String\s+_short',@"
Future<void> _connectWallet() async {
    setState(() => isConnecting = true);
    try {
      await _appKitModal.init();
      _appKitModal.openModalView(const ReownAppKitModalAllWalletsPage());
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 500));
        final session = _appKitModal.session;
        final namespaces = session?.namespaces;
        final ns = (namespaces == null || namespaces.isEmpty)
            ? null
            : (namespaces[`"eip155`"] ?? namespaces.values.first);
        final accounts = ns?.accounts ?? const <String>[];
        if (accounts.isEmpty) continue;
        final parts = accounts.first.split(`":`");
        if (parts.length < 3) continue;
        final addr = parts[2];
        if (!mounted) return;
        setState(() {
          isConnected = true;
          isConnecting = false;
          walletAddress = _short(addr);
        });
        return;
      }
      throw Exception(`"Connect timeout`");
    } catch (e) {
      if (!mounted) return;
      setState(() => isConnecting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(`"Connect failed: $e`")));
    }
  }
  String _short
"@)
$e=New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($fp,$c,$e)
dart format $fp

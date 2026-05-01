/// Detects and validates wallet address formats for EVM, Solana, and Tron.
class AddressValidator {
  /// Detects the chain type from address format.
  ///
  /// Returns 'evm', 'solana', 'tron', or 'unknown'.
  static String detectChainType(String address) {
    if (address.isEmpty) return 'unknown';

    // EVM: 0x + 40 hex characters
    if (isValidEvmAddress(address)) return 'evm';

    // Tron: T-prefix + 33 Base58Check characters = 34 total
    if (isValidTronAddress(address)) return 'tron';

    // Solana: Base58, 32-44 characters, no 0x prefix, no T prefix
    if (isValidSolanaAddress(address)) return 'solana';

    return 'unknown';
  }

  /// EVM address: 0x followed by exactly 40 hex characters.
  static bool isValidEvmAddress(String addr) {
    return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(addr);
  }

  /// Solana address: Base58 encoded, 32-44 characters.
  /// Excludes addresses that start with 'T' (Tron) or '0x' (EVM).
  static bool isValidSolanaAddress(String addr) {
    if (addr.startsWith('0x')) return false;
    if (addr.startsWith('T') && addr.length == 34) return false;
    return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(addr);
  }

  /// Tron address: starts with 'T', exactly 34 Base58Check characters.
  static bool isValidTronAddress(String addr) {
    if (!addr.startsWith('T') || addr.length != 34) return false;
    return RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$').hasMatch(addr);
  }

  /// Returns a human-readable chain name for UI display.
  static String chainDisplayName(String chainType) {
    switch (chainType) {
      case 'evm':
        return 'EVM';
      case 'solana':
        return 'Solana';
      case 'tron':
        return 'Tron';
      default:
        return 'Unknown';
    }
  }

  /// Returns the native token symbol for a chain type.
  static String chainNativeSymbol(String chainType) {
    switch (chainType) {
      case 'solana':
        return 'SOL';
      case 'tron':
        return 'TRX';
      default:
        return 'ETH';
    }
  }
}

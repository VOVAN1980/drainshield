import '../services/token_metadata_cache.dart';
import '../config/chains.dart';

class WalletAsset {
  final String name;
  final String symbol;
  final String address;
  final double balance;
  final String? logoUrl;
  final double priceUsd;
  final double valueUsd;
  final int decimals;
  final bool isNative;
  final int chainId;
  final String chainKey; // 'bsc', 'eth', 'solana', 'tron'

  WalletAsset({
    required this.name,
    required this.symbol,
    required this.address,
    required this.balance,
    this.logoUrl,
    required this.priceUsd,
    required this.valueUsd,
    required this.decimals,
    this.isNative = false,
    required this.chainId,
    this.chainKey = 'bsc',
  });

  factory WalletAsset.fromMoralis(Map<String, dynamic> json, {String? chain}) {
    final address = json['token_address']?.toString() ??
        '0x0000000000000000000000000000000000000000';

    String name = json['name']?.toString() ?? 'Unknown';
    String symbol = json['symbol']?.toString() ?? '???';
    int decimals = int.tryParse(json['decimals']?.toString() ?? '18') ?? 18;
    String? logoUrl = json['thumbnail']?.toString() ?? json['logo']?.toString();

    if (chain != null && address.toLowerCase() != 'native') {
      final cache = TokenMetadataCache();
      final cached = cache.get(chain, address);
      if (cached != null) {
        name = cached.name;
        symbol = cached.symbol;
        decimals = cached.decimals;
        logoUrl = cached.logoUrl;
      } else {
        cache.set(
          chain,
          address,
          TokenMetadata(
            tokenAddress: address,
            name: name,
            symbol: symbol,
            decimals: decimals,
            logoUrl: logoUrl,
          ),
        );
      }
    }

    final balanceRaw =
        double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0;

    // Moralis tokens endpoint usually returns human-readable balance or we calculate it
    // If 'balance_formatted' is available, we can use it, otherwise divide by 10^decimals
    double balance = balanceRaw;
    if (json.containsKey('balance_formatted')) {
      balance = double.tryParse(json['balance_formatted'].toString()) ?? 0.0;
    } else {
      // Manual calculation if needed, but Moralis v2.2 usually provides formatted
      // balance = balanceRaw / pow(10, decimals);
    }

    return WalletAsset(
      name: name,
      symbol: symbol,
      address: address,
      balance: balance,
      logoUrl: logoUrl,
      priceUsd: double.tryParse(json['usd_price']?.toString() ?? '0') ?? 0.0,
      valueUsd: double.tryParse(json['usd_value']?.toString() ?? '0') ?? 0.0,
      decimals: decimals,
      isNative: false,
      chainId: chain != null ? ChainConfig.getChainId(chain) : 1,
      chainKey: chain ?? 'eth',
    );
  }

  factory WalletAsset.native({
    required String name,
    required String symbol,
    required double balance,
    String? logoUrl,
    required double priceUsd,
    required int decimals,
    required int chainId,
    String chainKey = 'bsc',
  }) {
    return WalletAsset(
      name: name,
      symbol: symbol,
      address: 'native',
      balance: balance,
      logoUrl: logoUrl,
      priceUsd: priceUsd,
      valueUsd: balance * priceUsd,
      decimals: decimals,
      isNative: true,
      chainId: chainId,
      chainKey: chainKey,
    );
  }
}

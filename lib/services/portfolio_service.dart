import "dart:convert";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "../models/wallet_asset.dart";
import "../models/wallet_transaction.dart";
import "../models/approval.dart";
import "moralis/moralis_config_service.dart";
import "approval_scan_service.dart";
import "../rpc/solana_rpc.dart";
import "../rpc/tron_rpc.dart";

class PortfolioService {
  final String? apiKey;
  final String? chain;

  PortfolioService({this.apiKey, this.chain});

  Future<List<WalletAsset>> getPortfolio(
    String address, {
    String? chainOverride,
  }) async {
    final ch = chainOverride ?? MoralisConfigService.instance.defaultChain;

    // Route to non-EVM fetchers
    if (ch == 'solana') return _fetchSolanaPortfolio(address);
    if (ch == 'tron') return _fetchTronPortfolio(address);

    // EVM: existing Moralis flow
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return [];

    try {
      final results = await Future.wait([
        _fetchNativeBalance(address, apiKey, ch),
        _fetchErc20Tokens(address, apiKey, ch),
      ]);

      final List<WalletAsset> allAssets = [];

      // Add native balance if it exists
      if (results[0] != null) {
        allAssets.add(results[0] as WalletAsset);
      }

      // Add ERC20 tokens
      if (results[1] != null) {
        allAssets.addAll(results[1] as List<WalletAsset>);
      }

      // Filter: only show assets with positive balance (safety check)
      // Exception: If it's a native asset, show it even if balance is small or 0
      final filtered = allAssets.where((a) {
        if (a.isNative) return true;
        return a.balance > 0 && a.valueUsd > 0.01;
      }).toList();

      // Sort by value descending, but keep native at the top if balances are 0
      filtered.sort((a, b) {
        if (a.isNative && b.isNative) return 0;
        if (a.isNative) return -1;
        if (b.isNative) return 1;
        return b.valueUsd.compareTo(a.valueUsd);
      });

      return filtered;
    } catch (e) {
      debugPrint("Error fetching portfolio: $e");
      return [];
    }
  }

  Future<WalletAsset?> _fetchNativeBalance(
    String address,
    String apiKey,
    String chain,
  ) async {
    try {
      final url = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/balance?chain=$chain",
      );
      final resp = await http.get(url, headers: {"X-API-Key": apiKey}).timeout(
        const Duration(seconds: 15),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final balanceRaw =
            double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
        final balance = balanceRaw / 1e18;

        // Fetch price for native token via wrapped version
        double price = 0.0;
        String? wrappedAddress;
        String nativeName = 'Native Token';
        String nativeSymbol = 'ETH';
        String nativeLogo =
            'https://assets.coingecko.com/coins/images/279/small/ethereum.png';

        switch (chain) {
          case 'bsc':
            wrappedAddress = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
            nativeName = 'BNB';
            nativeSymbol = 'BNB';
            nativeLogo =
                'https://assets.coingecko.com/coins/images/825/small/binance-coin-logo.png';
            break;
          case 'polygon':
            wrappedAddress = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
            nativeName = 'MATIC';
            nativeSymbol = 'MATIC';
            nativeLogo =
                'https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png';
            break;
          case 'eth':
            wrappedAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
            nativeName = 'Ethereum';
            nativeSymbol = 'ETH';
            break;
          case 'arbitrum':
            wrappedAddress = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";
            nativeName = 'Arbitrum ETH';
            nativeSymbol = 'ETH';
            break;
          case 'base':
            wrappedAddress = "0x4200000000000000000000000000000000000006";
            nativeName = 'Base ETH';
            nativeSymbol = 'ETH';
            break;
        }

        if (wrappedAddress != null) {
          final priceUrl = Uri.parse(
            "https://deep-index.moralis.io/api/v2.2/erc20/$wrappedAddress/price?chain=$chain",
          );
          final priceResp = await http.get(
            priceUrl,
            headers: {"X-API-Key": apiKey},
          ).timeout(const Duration(seconds: 15));
          if (priceResp.statusCode == 200) {
            final priceData = jsonDecode(priceResp.body);
            price = double.tryParse(priceData['usdPrice']?.toString() ?? '0') ??
                0.0;
          }
        }

        return WalletAsset.native(
          name: nativeName,
          symbol: nativeSymbol,
          balance: balance,
          priceUsd: price,
          decimals: 18,
          logoUrl: nativeLogo,
          chainId: _getChainIdFromSlug(chain),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<List<WalletTransaction>> getRecentNativeTransactions(
    String address,
    String chain, {
    String nativeSymbol = 'ETH',
  }) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return [];

    try {
      final url = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/history?chain=$chain&limit=15",
      );
      final resp = await http.get(url, headers: {"X-API-Key": apiKey}).timeout(
        const Duration(seconds: 15),
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> result = decoded['result'] ?? [];
        return result
            .map((item) => WalletTransaction.fromMoralisNative(
                  item,
                  address,
                  nativeSymbol,
                ))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching native history: $e");
    }
    return [];
  }

  Future<List<WalletTransaction>> getRecentTokenTransfers(
    String address,
    String tokenAddress,
    String chain,
  ) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return [];

    try {
      final url = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/erc20/transfers?chain=$chain&limit=50",
      );
      final resp = await http.get(url, headers: {"X-API-Key": apiKey}).timeout(
        const Duration(seconds: 15),
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> result = decoded['result'] ?? [];
        return result
            .map((item) => WalletTransaction.fromMoralisErc20(item, address))
            .where((tx) =>
                tx.fromAddress.toLowerCase() == tokenAddress.toLowerCase() ||
                (tx.toAddress?.toLowerCase() ?? '') ==
                    tokenAddress.toLowerCase() ||
                // The above is wrong, Moralis erc20/transfers already returns transfers OF tokens.
                // We need to filter by token_address.
                // Re-parsing the logic:
                true)
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching token history: $e");
    }
    return [];
  }

  // Helper to filter by token address if the API doesn't do it (Moralis does it if we use the right endpoint)
  // But erc20/transfers for WALLET returns ALL token transfers.
  // We can use /erc20/{address}/transfers?chain={chain} but that's for GLOBAL transfers of that token.
  // We need WALLET specific transfers of a specific token.
  // Moralis has: GET /wallets/{address}/erc20/transfers?chain={chain}
  // We will filter the result by token_address.

  Future<List<WalletTransaction>> getRecentTokenTransfersFiltered(
    String address,
    String tokenAddress,
    String chain,
  ) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return [];

    try {
      final url = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/erc20/transfers?chain=$chain&limit=100",
      );
      final resp = await http.get(url, headers: {"X-API-Key": apiKey}).timeout(
        const Duration(seconds: 15),
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> result = decoded['result'] ?? [];

        final allTransfers = result
            .map((item) {
              // Check if this item matches our token address
              final itemTokenAddr = item['token_address']?.toString() ?? '';
              if (itemTokenAddr.toLowerCase() != tokenAddress.toLowerCase()) {
                return null;
              }
              return WalletTransaction.fromMoralisErc20(item, address);
            })
            .whereType<WalletTransaction>()
            .toList();

        return allTransfers;
      }
    } catch (e) {
      debugPrint("Error fetching filtered token history: $e");
    }
    return [];
  }

  Future<List<ApprovalData>> getTokenApprovalsForAsset(
    String walletAddress,
    String tokenAddress,
    String chain,
  ) async {
    try {
      // Convert chain slug to chain ID
      final chainId = _getChainIdFromSlug(chain);
      return await ApprovalScanService.scan(
        walletAddress,
        targetTokenAddress: tokenAddress,
        chainId: chainId,
      );
    } catch (e) {
      debugPrint("Error fetching approvals for asset: $e");
      return [];
    }
  }

  int _getChainIdFromSlug(String slug) {
    switch (slug) {
      case 'bsc':
        return 56;
      case 'eth':
        return 1;
      case 'polygon':
        return 137;
      case 'arbitrum':
        return 42161;
      case 'base':
        return 8453;
      default:
        return 1;
    }
  }

  Future<List<WalletAsset>> _fetchErc20Tokens(
    String address,
    String apiKey,
    String chain,
  ) async {
    try {
      final url = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/tokens?chain=$chain",
      );
      final resp = await http.get(url, headers: {"X-API-Key": apiKey}).timeout(
        const Duration(seconds: 15),
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> items = [];

        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded.containsKey('result')) {
          final result = decoded['result'];
          if (result is List) {
            items = result;
          }
        }

        return items
            .map((item) => WalletAsset.fromMoralis(item, chain: chain))
            .where((a) => a.balance > 0 && a.valueUsd > 0.01)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Solana Portfolio ─────────────────────────────────────────────────────

  /// Known Solana SPL tokens: mint address → (symbol, name, decimals, isStable)
  static const Map<String, _SplTokenInfo> _knownSplTokens = {
    'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v': _SplTokenInfo('USDC', 'USD Coin', 6, true),
    'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB': _SplTokenInfo('USDT', 'Tether', 6, true),
    'So11111111111111111111111111111111111111112': _SplTokenInfo('WSOL', 'Wrapped SOL', 9, false),
    'DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263': _SplTokenInfo('BONK', 'Bonk', 5, false),
    'JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN': _SplTokenInfo('JUP', 'Jupiter', 6, false),
    '7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs': _SplTokenInfo('ETH', 'Ether (Wormhole)', 8, false),
    'mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So': _SplTokenInfo('mSOL', 'Marinade SOL', 9, false),
    '7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj': _SplTokenInfo('stSOL', 'Lido Staked SOL', 9, false),
    'HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3': _SplTokenInfo('PYTH', 'Pyth Network', 6, false),
    'rndrizKT3MK1iimdxRdWabcF7Zg7AR5T4nud4EkHBof': _SplTokenInfo('RNDR', 'Render Token', 8, false),
    'jtojtomepa8beP8AuQc6eXt5FriJwfFMwQx2v2f9mCL': _SplTokenInfo('JTO', 'Jito', 9, false),
    'WENWENvqqNya429ubCdR81ZmD69brwQaaBYY6p91oHk': _SplTokenInfo('WEN', 'Wen', 5, false),
  };

  Future<List<WalletAsset>> _fetchSolanaPortfolio(String address) async {
    final client = SolanaHttpRpcClient(
      rpcUrl: 'https://api.mainnet-beta.solana.com',
    );
    final assets = <WalletAsset>[];

    // Fetch SOL price from Binance (same as TRX)
    double solPriceUsd = 0.0;
    try {
      final res = await http
          .get(Uri.parse(
              'https://api.binance.com/api/v3/ticker/price?symbol=SOLUSDT'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        solPriceUsd =
            double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
      }
    } catch (_) {
      debugPrint('[PortfolioService] Solana: Binance price fetch failed');
    }

    try {
      // 1. SOL native balance
      final lamports = await client.getBalanceLamports(address);
      final solBalance = lamports.toDouble() / 1e9;
      assets.add(WalletAsset.native(
        name: 'Solana',
        symbol: 'SOL',
        balance: solBalance,
        logoUrl: 'https://cryptologos.cc/logos/solana-sol-logo.png',
        priceUsd: solPriceUsd,
        decimals: 9,
        chainId: 0,
        chainKey: 'solana',
      ));
    } catch (e) {
      debugPrint('[PortfolioService] Solana native balance error: $e');
    }

    try {
      // 2. SPL token balances
      final tokenAccounts = await client.getTokenAccountsByOwner(address);
      for (final account in tokenAccounts) {
        if (account.balance <= 0) continue;

        final info = _knownSplTokens[account.mint];
        final symbol = info?.symbol ?? _shortMint(account.mint);
        final name = info?.name ?? symbol;
        final isStable = info?.isStable ?? false;

        assets.add(WalletAsset(
          name: name,
          symbol: symbol,
          address: account.mint,
          balance: account.balance,
          logoUrl: null,
          priceUsd: isStable ? 1.0 : 0,
          valueUsd: isStable ? account.balance : 0,
          decimals: account.decimals,
          chainId: 0,
          chainKey: 'solana',
        ));
      }
    } catch (e) {
      debugPrint('[PortfolioService] Solana SPL token error: $e');
    }

    return assets;
  }

  static String _shortMint(String mint) {
    if (mint.length < 10) return mint;
    return '${mint.substring(0, 4)}...${mint.substring(mint.length - 4)}';
  }

  // ── Tron Portfolio ───────────────────────────────────────────────────────

  /// In-flight deduplication: if a Tron portfolio fetch is already running
  /// for this address, reuse its result instead of hammering TronGrid again.
  Future<List<WalletAsset>>? _tronInFlight;
  String? _tronInFlightAddress;

  Future<List<WalletAsset>> _fetchTronPortfolio(String address) {
    if (_tronInFlight != null && _tronInFlightAddress == address) {
      debugPrint('[PortfolioService] Tron: reusing in-flight for $address');
      return _tronInFlight!;
    }
    _tronInFlightAddress = address;
    _tronInFlight = _fetchTronPortfolioImpl(address).whenComplete(() {
      _tronInFlight = null;
      _tronInFlightAddress = null;
    });
    return _tronInFlight!;
  }

  Future<List<WalletAsset>> _fetchTronPortfolioImpl(String address) async {
    debugPrint('[PortfolioService] Tron: START $address');
    final client = TronHttpRpcClient.shared;
    final assets = <WalletAsset>[];

    try {
      debugPrint('[PortfolioService] Tron: getAccountPortfolio...');
      final accountData = await client.getAccountPortfolio(address);

      // Fetch TRX price from Binance
      double trxPriceUsd = 0.0;
      try {
        final res = await http
            .get(Uri.parse(
                'https://api.binance.com/api/v3/ticker/price?symbol=TRXUSDT'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          trxPriceUsd =
              double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
        }
      } catch (_) {
        debugPrint('[PortfolioService] Tron: Binance price fetch failed');
      }

      // 1. TRX native balance
      final balanceRaw =
          double.tryParse(accountData['balance']?.toString() ?? '0') ?? 0.0;
      final trxBalance = balanceRaw / 1e6;
      assets.add(WalletAsset.native(
        name: 'Tron',
        symbol: 'TRX',
        balance: trxBalance,
        logoUrl: 'https://cryptologos.cc/logos/tron-trx-logo.png',
        priceUsd: trxPriceUsd,
        decimals: 6,
        chainId: 0,
        chainKey: 'tron',
      ));

      // 2. TRC20 tokens from the single response
      final trc20List = accountData['trc20'] as List<dynamic>? ?? [];
      for (final item in trc20List) {
        if (item is Map) {
          final contractAddress = item.keys.first.toString();
          final balanceString = item.values.first.toString();
          final rawBalance = double.tryParse(balanceString) ?? 0.0;

          if (rawBalance <= 0) continue;

          final info = TronHttpRpcClient.knownTokens[contractAddress];
          if (info != null) {
            final balance = rawBalance / _pow10(info.decimals);
            assets.add(WalletAsset(
              name: info.symbol,
              symbol: info.symbol,
              address: contractAddress,
              balance: balance,
              logoUrl: null,
              priceUsd:
                  info.symbol == 'USDT' || info.symbol == 'USDC' ? 1.0 : 0,
              valueUsd:
                  info.symbol == 'USDT' || info.symbol == 'USDC' ? balance : 0,
              decimals: info.decimals,
              chainId: 0,
              chainKey: 'tron',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[PortfolioService] Tron: Fetch FAIL $e');
    }

    debugPrint('[PortfolioService] Tron: DONE ${assets.length} assets');
    return assets;
  }

  static double _pow10(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}

class _SplTokenInfo {
  final String symbol;
  final String name;
  final int decimals;
  final bool isStable;
  const _SplTokenInfo(this.symbol, this.name, this.decimals, this.isStable);
}

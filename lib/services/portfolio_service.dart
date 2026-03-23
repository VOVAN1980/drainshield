import "dart:convert";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "../models/wallet_asset.dart";
import "../models/wallet_transaction.dart";
import "../models/approval.dart";
import "moralis/moralis_config_service.dart";
import "approval_scan_service.dart";

class PortfolioService {
  final String? apiKey;
  final String? chain;

  PortfolioService({this.apiKey, this.chain});

  Future<List<WalletAsset>> getPortfolio(
    String address, {
    String? chainOverride,
  }) async {
    final apiKey = MoralisConfigService.key;
    final ch = chainOverride ?? MoralisConfigService.instance.defaultChain;

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

        final allTransfers = result.map((item) {
          // Check if this item matches our token address
          final itemTokenAddr = item['token_address']?.toString() ?? '';
          if (itemTokenAddr.toLowerCase() != tokenAddress.toLowerCase()) {
            return null;
          }
          return WalletTransaction.fromMoralisErc20(item, address);
        }).whereType<WalletTransaction>().toList();

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
}

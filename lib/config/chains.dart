class ChainConfig {
  static const Map<String, int> _chainMap = {
    'eth': 1,
    'ethereum': 1,
    'bsc': 56,
    'bnb': 56,
    'polygon': 137,
    'matic': 137,
    'arbitrum': 42161,
    'optimism': 10,
    'base': 8453,
  };

  /// Returns the chainId for a given chain name string.
  /// If the chain is unknown, returns 0 instead of defaulting to Ethereum (1).
  /// Returning 0 ensures that downstream transactions (like Revoke) will
  /// predictably fail gas estimation or wallet signing due to invalid network,
  /// preventing destructive actions on the wrong chain.
  static int getChainId(String chain) {
    final lower = chain.toLowerCase();
    return _chainMap[lower] ?? 0;
  }

  static const Map<int, String> _moralisSlugMap = {
    1: 'eth',
    56: 'bsc',
    137: 'polygon',
    42161: 'arbitrum',
    10: 'optimism',
    8453: 'base',
    100: 'gnosis',
  };

  /// Returns the Moralis chain slug for a given chainId.
  /// If the chainId is unsupported, returns null.
  static String? getMoralisChainSlug(int chainId) {
    return _moralisSlugMap[chainId];
  }

  static const Map<int, String> _chainNameMap = {
    1: 'Ethereum',
    56: 'BNB Chain',
    137: 'Polygon',
    42161: 'Arbitrum',
    10: 'Optimism',
    8453: 'Base',
    100: 'Gnosis',
  };

  static String getChainName(int chainId) {
    return _chainNameMap[chainId] ?? 'Unknown Network ($chainId)';
  }

  static const Map<int, String> _explorerMap = {
    1: 'https://etherscan.io',
    56: 'https://bscscan.com',
    137: 'https://polygonscan.com',
    42161: 'https://arbiscan.io',
    10: 'https://optimistic.etherscan.io',
    8453: 'https://basescan.org',
    100: 'https://gnosisscan.io',
  };

  static String? getExplorerUrl(int chainId, String address) {
    final base = _explorerMap[chainId];
    if (base == null) return null;
    return '$base/address/$address';
  }

  static const Map<int, String> _nativeSymbolMap = {
    1: 'ETH',
    56: 'BNB',
    137: 'POL', // Polygon migrated MATIC to POL
    42161: 'ETH',
    10: 'ETH',
    8453: 'ETH',
  };

  static String getNativeSymbol(int chainId) {
    return _nativeSymbolMap[chainId] ?? 'ETH';
  }
}

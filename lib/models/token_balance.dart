class TokenBalance {
  final String symbol;
  final String contract;
  final double balance;
  final String? logo;
  TokenBalance({
    required this.symbol,
    required this.contract,
    required this.balance,
    this.logo,
  });
}

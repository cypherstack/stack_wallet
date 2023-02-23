class EthToken {
  EthToken({
    required this.contractAddress,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.balance,
  });

  final String contractAddress;
  final String name;
  final String symbol;
  final int decimals;
  final int balance;
}

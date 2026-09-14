bool isSparkSpendTransaction(Map<String, dynamic> transaction) {
  final type = transaction['type'];
  return transaction['version'] == 3 && (type == 9 || type == 11);
}

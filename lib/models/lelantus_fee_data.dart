class LelantusFeeData {
  int changeToMint;
  int fee;
  List<int> spendCoinIndexes;
  LelantusFeeData(this.changeToMint, this.fee, this.spendCoinIndexes);

  @override
  String toString() {
    return "{changeToMint: $changeToMint, fee: $fee, spendCoinIndexes: $spendCoinIndexes}";
  }
}

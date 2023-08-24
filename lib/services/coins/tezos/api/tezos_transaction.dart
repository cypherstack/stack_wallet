class TezosTransaction {
  final String hash;
  final int height;
  final int timestamp;
  final int amountInMicroTez;
  final int feeInMicroTez;
  final String senderAddress;
  final String receiverAddress;

  TezosTransaction({
    required this.hash,
    required this.height,
    required this.timestamp,
    required this.amountInMicroTez,
    required this.feeInMicroTez,
    required this.senderAddress,
    required this.receiverAddress,
  });
}
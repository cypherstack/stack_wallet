class TezosTransaction {
  final int? id;
  final String hash;
  final String? type;
  final int height;
  final int timestamp;
  final int? cycle;
  final int? counter;
  final int? opN;
  final int? opP;
  final String? status;
  final bool? isSuccess;
  final int? gasLimit;
  final int? gasUsed;
  final int? storageLimit;
  final int amountInMicroTez;
  final int feeInMicroTez;
  final int? burnedAmountInMicroTez;
  final String senderAddress;
  final String receiverAddress;

  TezosTransaction({
    this.id,
    required this.hash,
    this.type,
    required this.height,
    required this.timestamp,
    this.cycle,
    this.counter,
    this.opN,
    this.opP,
    this.status,
    this.isSuccess,
    this.gasLimit,
    this.gasUsed,
    this.storageLimit,
    required this.amountInMicroTez,
    required this.feeInMicroTez,
    this.burnedAmountInMicroTez,
    required this.senderAddress,
    required this.receiverAddress,
  });
}
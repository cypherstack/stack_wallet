class TezosOperation {
  int? id;
  String hash;
  String? type;
  int height;
  int timestamp;
  int? cycle;
  int? counter;
  int? op_n;
  int? op_p;
  String? status;
  bool? is_success;
  int? gas_limit;
  int? gas_used;
  int? storage_limit;
  int amountInMicroTez;
  int feeInMicroTez;
  int? burnedAmountInMicroTez;
  String senderAddress;
  String receiverAddress;
  int? confirmations;

  TezosOperation({
    this.id,
    required this.hash,
    this.type,
    required this.height,
    required this.timestamp,
    this.cycle,
    this.counter,
    this.op_n,
    this.op_p,
    this.status,
    this.is_success,
    this.gas_limit,
    this.gas_used,
    this.storage_limit,
    required this.amountInMicroTez,
    required this.feeInMicroTez,
    this.burnedAmountInMicroTez,
    required this.senderAddress,
    required this.receiverAddress,
    this.confirmations
  });
}
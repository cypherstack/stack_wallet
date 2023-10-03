import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';

class EpicTransaction {

  Id isarId = Isar.autoIncrement;

  @Index()
  late final String walletId;

  @Index()
  final String parentKeyId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  late final int id;

  final String? txSlateId;

  @enumerated
  final TransactionType txType;

  final String creationTs;
  final String confirmationTs;
  final bool confirmed;
  final int numInputs;
  final int numOutputs;
  final String amountCredited;
  final String amountDebited;
  final String? fee;
  final String? ttlCutoffHeight;
  final Messages? messages;
  final String? storedTx;
  final String? kernelExcess;
  final int? kernelLookupMinHeight;
  final String? paymentProof;

  @Backlink(to: "transactions")
  final address = IsarLink<Address>();

  EpicTransaction({
    required this.walletId,
    required this.parentKeyId,
    required this.id,
    this.txSlateId,
    required this.txType,
    required this.creationTs,
    required this.confirmationTs,
    required this.confirmed,
    required this.numInputs,
    required this.numOutputs,
    required this.amountCredited,
    required this.amountDebited,
    this.fee,
    this.ttlCutoffHeight,
    this.messages,
    this.storedTx,
    this.kernelExcess,
    this.kernelLookupMinHeight,
    this.paymentProof,
  });

  // factory EpicTransaction.fromJson(Map<String, dynamic> json) {
  //   return EpicTransaction(
  //     parentKeyId: json['parent_key_id'] as String,
  //     id: json['id'] as int,
  //     txSlateId: json['tx_slate_id'] as String,
  //     txType: json['tx_type'] as TransactionType,
  //     creationTs: json['creation_ts'] as String,
  //     confirmationTs: json['confirmation_ts'] as String,
  //     confirmed: json['confirmed'] as bool,
  //     numInputs: json['num_inputs'] as int,
  //     numOutputs: json['num_outputs'] as int,
  //     amountCredited: json['amount_credited'] as String,
  //     amountDebited: json['amount_debited'] as String,
  //     fee: json['fee'] as String,
  //     ttlCutoffHeight: json['ttl_cutoff_height'] as String,
  //     messages: json['messages'] != null ? Messages.fromJson(json['messages'] as Map<String, dynamic>) : null,
  //     storedTx: json['stored_tx'] as String,
  //     kernelExcess: json['kernel_excess'] as String,
  //     kernelLookupMinHeight: json['kernel_lookup_min_height'] as int,
  //     paymentProof: json['payment_proof'] as String,
  //   );
  // }
}

class Messages {
  final List<Message> messages;

  Messages({required this.messages});

  factory Messages.fromJson(Map<String, dynamic> json) {
    final messageList = json['messages'] as List<dynamic>;
    final messages = messageList.map((message) => Message.fromJson(message as Map<String, dynamic>)).toList();
    return Messages(messages: messages);
  }
}

class Message {
  final String id;
  final String publicKey;
  final String? message;
  final String? messageSig;

  Message({
    required this.id,
    required this.publicKey,
    this.message,
    this.messageSig,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      publicKey: json['public_key'] as String,
      message: json['message'] as String,
      messageSig: json['message_sig'] as String,
    );
  }
}

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum TransactionType {
  // TODO: add more types before prod release?
  outgoing,
  incoming,
  sentToSelf, // should we keep this?
  unknown;
}

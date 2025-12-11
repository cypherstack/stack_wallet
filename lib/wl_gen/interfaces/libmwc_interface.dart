export '../generated/libmwc_interface_impl.dart';

abstract class LibMwcInterface {
  const LibMwcInterface();

  bool txTypeIsReceived(Enum value);
  bool txTypeIsReceiveCancelled(Enum value);
  bool txTypeIsSentCancelled(Enum value);

  Future<String> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
  });

  Future<String> openWallet({required String config, required String password});

  Future<void> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name,
  });

  Future<({String commitId, String slateId})> txHttpSend({
    required String wallet,
    required int selectionStrategyIsAll,
    required int minimumConfirmations,
    required String message,
    required int amount,
    required String address,
  });

  Future<({String commitId, String slateId})> createTransaction({
    required String wallet,
    required int amount,
    required String address,
    required int secretKeyIndex,
    required String mwcmqsConfig,
    required int minimumConfirmations,
    required String note,
  });

  Future<String> cancelTransaction({
    required String wallet,
    required String transactionId,
  });

  Future<String> txInit({
    required String wallet,
    required int amount,
    int minimumConfirmations = 1,
    bool selectionStrategyIsAll = false,
    String message = '',
  });

  Future<List<MwcTransaction>> getTransactions({
    required String wallet,
    required int refreshFromNode,
  });

  Future<({String? recipientAddress, String slatepack, bool wasEncrypted})>
  encodeSlatepack({
    required String slateJson,
    String? recipientAddress,
    bool encrypt = false,
    String? wallet,
  });
  Future<
    ({
      String? recipientAddress,
      String? senderAddress,
      String slateJson,
      bool wasEncrypted,
    })
  >
  decodeSlatepackWithWallet({
    required String wallet,
    required String slatepack,
  });

  Future<
    ({
      String? recipientAddress,
      String? senderAddress,
      String slateJson,
      bool wasEncrypted,
    })
  >
  decodeSlatepack({required String slatepack});

  Future<({String commitId, String slateId, String slateJson})>
  txReceiveDetailed({required String wallet, required String slateJson});

  Future<({String commitId, String slateId})> txFinalize({
    required String wallet,
    required String slateJson,
  });

  void startMwcMqsListener({
    required String wallet,
    required String mwcmqsConfig,
  });

  void stopMwcMqsListener();

  bool validateSendAddress({required String address});

  Future<({int fee, bool strategyUseAll, int total})> getTransactionFees({
    required String wallet,
    required int amount,
    required int minimumConfirmations,
    required int available,
  });

  Future<
    ({
      double awaitingFinalization,
      double pending,
      double spendable,
      double total,
    })
  >
  getWalletBalances({
    required String wallet,
    required int refreshFromNode,
    required int minimumConfirmations,
  });

  Future<String> getAddressInfo({required String wallet, required int index});

  Future<int> scanOutputs({
    required String wallet,
    required int startHeight,
    required int numberOfBlocks,
  });

  Future<int> getChainHeight({required String config});

  Future<String> deleteWallet({required String wallet, required String config});

  String getPluginVersion();
}

class MwcTransaction {
  final String parentKeyId;
  final int id;
  final String? txSlateId;
  final Enum txType;
  final String creationTs;
  final String confirmationTs;
  final bool confirmed;
  final int numInputs;
  final int numOutputs;
  final String amountCredited;
  final String amountDebited;
  final String? fee;
  final String? ttlCutoffHeight;
  final List<MwcMessage>? messages;
  final String? storedTx;
  final String? kernelExcess;
  final int? kernelLookupMinHeight;
  final String? paymentProof;

  MwcTransaction({
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
}

class MwcMessage {
  final String id;
  final String publicKey;
  final String? message;
  final String? messageSig;

  MwcMessage({
    required this.id,
    required this.publicKey,
    this.message,
    this.messageSig,
  });
}

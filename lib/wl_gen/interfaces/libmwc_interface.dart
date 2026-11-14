import 'mimblewimble_transaction.dart';

export '../generated/libmwc_interface_impl.dart';
export 'mimblewimble_transaction.dart';

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

  Future<List<MimblewimbleTransaction>> getTransactions({
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

  Future<String> initLogs({required String config});
}

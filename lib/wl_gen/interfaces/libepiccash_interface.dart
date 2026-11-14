import '../../utilities/dynamic_object.dart';
import 'mimblewimble_transaction.dart';

export '../generated/libepiccash_interface_impl.dart';
export 'mimblewimble_transaction.dart';

abstract class LibEpicCashInterface {
  const LibEpicCashInterface();

  bool txTypeIsReceived(Enum value);
  bool txTypeIsReceiveCancelled(Enum value);
  bool txTypeIsSentCancelled(Enum value);

  Future<DynamicObject> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
    required String epicBoxConfig,
  });

  Future<DynamicObject> openWallet({
    required String config,
    required String password,
    required String epicboxConfig,
  });

  Future<DynamicObject> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name,
    required String epicBoxConfig,
  });

  Future<({String commitId, String slateId})> txHttpSend({
    required DynamicObject wallet,
    required int selectionStrategyIsAll,
    required int minimumConfirmations,
    required String message,
    required int amount,
    required String address,
  });

  Future<({String commitId, String slateId, String slateJson})>
  createTransaction({
    required DynamicObject wallet,
    required int amount,
    required String address,
    required int secretKeyIndex,
    required int minimumConfirmations,
    required String note,
    bool returnSlate = false,
  });

  Future<({String slateId, String commitId, String slateJson})> txReceive({
    required DynamicObject wallet,
    required String slateJson,
  });

  Future<({String slateId, String commitId, String slateJson})> txFinalize({
    required DynamicObject wallet,
    required String slateJson,
  });

  Future<String> cancelTransaction({
    required DynamicObject wallet,
    required String transactionId,
  });

  Future<List<MimblewimbleTransaction>> getTransactions({
    required DynamicObject wallet,
    required int refreshFromNode,
  });

  Future<void> startEpicboxListener({required DynamicObject wallet});

  Future<void> stopEpicboxListener({required DynamicObject wallet});

  Future<bool> isEpicboxListenerRunning({required DynamicObject wallet});

  Future<bool> validateSendAddress({required String address});

  bool validateSendAddressSync({required String address});

  Future<({int fee, bool strategyUseAll, int total})> getTransactionFees({
    required DynamicObject wallet,
    required int amount,
    required int minimumConfirmations,
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
    required DynamicObject wallet,
    required int refreshFromNode,
    required int minimumConfirmations,
  });

  Future<String> getAddressInfo({
    required DynamicObject wallet,
    required int index,
    required String epicboxConfig,
  });

  Future<int> scanOutputs({
    required DynamicObject wallet,
    required int startHeight,
    required int numberOfBlocks,
  });

  Future<int> getChainHeight({required String config});

  Future<void> close({required DynamicObject wallet});

  Future<String> deleteWallet({required String config});

  void updateEpicboxConfig({
    required DynamicObject wallet,
    required String epicBoxConfig,
  });

  void updateConfig({required DynamicObject wallet, required String config});
}

class BadHttpAddressException implements Exception {}

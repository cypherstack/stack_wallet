import 'dart:convert';
import 'dart:typed_data';

import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/extensions/extensions.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/models/tx_recipient.dart';

export '../generated/frost_interface_impl.dart';

abstract class FrostInterface {
  const FrostInterface();

  //==================== utility ===============================================
  List<String> getParticipants({required String multisigConfig});

  bool validateEncodedMultisigConfig({required String encodedConfig});

  int getThreshold({required String multisigConfig});

  ({
    List<({String address, Amount amount})> recipients,
    String changeAddress,
    int feePerWeight,
    List<FrostOutput> inputs,
  })
  extractDataFromSignConfig({
    required String serializedKeys,
    required String signConfig,
    required CryptoCurrency coin,
  });

  //==================== wallet creation =======================================

  String createMultisigConfig({
    required String name,
    required int threshold,
    required List<String> participants,
  });

  ({
    String seed,
    String commitments,
    // Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    OpaqueWrapper multisigConfigWithNamePtr,
    // Pointer<SecretShareMachineWrapper> secretShareMachineWrapperPtr,
    OpaqueWrapper secretShareMachineWrapperPtr,
  })
  startKeyGeneration({required String multisigConfig, required String myName});

  // ({String share, Pointer<SecretSharesRes> secretSharesResPtr})
  ({String share, OpaqueWrapper secretSharesResPtr}) generateSecretShares({
    // required Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    required OpaqueWrapper multisigConfigWithNamePtr,
    required String mySeed,
    // required Pointer<SecretShareMachineWrapper> secretShareMachineWrapperPtr,
    required OpaqueWrapper secretShareMachineWrapperPtr,
    required List<String> commitments,
  });

  ({Uint8List multisigId, String recoveryString, String serializedKeys})
  completeKeyGeneration({
    // required Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    required OpaqueWrapper multisigConfigWithNamePtr,
    // required Pointer<SecretSharesRes> secretSharesResPtr,
    required OpaqueWrapper secretSharesResPtr,
    required List<String> shares,
  });

  //=================== transaction creation ===================================

  String createSignConfig({
    required String serializedKeys,
    required int network,
    required List<
      ({
        UTXO utxo,
        Uint8List scriptPubKey,
        FrostAddressDerivationData addressDerivationData,
      })
    >
    inputs,
    required List<TxRecipient> outputs,
    required String changeAddress,
    required int feePerWeight,
  });

  // ({Pointer<TransactionSignMachineWrapper> machinePtr, String preprocess})
  ({OpaqueWrapper machinePtr, String preprocess}) attemptSignConfig({
    required int network,
    required String config,
    required String serializedKeys,
  });

  // ({Pointer<TransactionSignatureMachineWrapper> machinePtr, String share})
  ({OpaqueWrapper machinePtr, String share}) continueSigning({
    // required Pointer<TransactionSignMachineWrapper> machinePtr,
    required OpaqueWrapper machinePtr,
    required List<String> preprocesses,
  });

  String completeSigning({
    // required Pointer<TransactionSignatureMachineWrapper> machinePtr,
    required OpaqueWrapper machinePtr,
    required List<String> shares,
  });

  // Pointer<SignConfig> decodedSignConfig({
  OpaqueWrapper decodedSignConfig({
    required String serializedKeys,
    required String encodedConfig,
    required int network,
  });

  //========================== resharing =======================================

  String createResharerConfig({
    required int newThreshold,
    required List<int> resharers,
    required List<String> newParticipants,
  });

  // ({String resharerStart, Pointer<StartResharerRes> machine}) beginResharer({
  ({String resharerStart, OpaqueWrapper machine}) beginResharer({
    required String serializedKeys,
    required String config,
  });

  /// expects [resharerStarts] of length equal to resharers.
  // ({String resharedStart, Pointer<StartResharedRes> prior}) beginReshared({
  ({String resharedStart, OpaqueWrapper prior}) beginReshared({
    required String myName,
    required String resharerConfig,
    required List<String> resharerStarts,
  });

  /// expects [encryptionKeysOfResharedTo] of length equal to new participants
  String finishResharer({
    // required StartResharerRes machine,
    required OpaqueWrapper machine,
    required List<String> encryptionKeysOfResharedTo,
  });

  /// expects [resharerCompletes] of length equal to resharers
  ({String multisigConfig, String serializedKeys, String resharedId})
  finishReshared({
    // required StartResharedRes prior,
    required OpaqueWrapper prior,
    required List<String> resharerCompletes,
  });

  // Pointer<ResharerConfig> decodedResharerConfig({
  OpaqueWrapper decodedResharerConfig({required String resharerConfig});

  ({int newThreshold, Map<String, int> resharers, List<String> newParticipants})
  extractResharerConfigData({required String rConfig});

  Uint8List getMultisigSalt({required String multisigConfig});
  int participantIndexFromKeys({required String serializedKeys});
  int getMultisigThreshold({required String multisigConfig});
  int thresholdFromKeys({required String serializedKeys});
  Uint8List getResharerSalt({required String resharerConfig});

  OpaqueWrapper getDeserializedKeys({required String keys});
  String getAddressForKeys({
    required OpaqueWrapper keys,
    required int network,
    required FrostAddressDerivationData addressDerivationData,
    required bool secure,
  });

  int get mainnet;
  int get testnet;

  String encodeRConfig(String config, Map<String, int> resharers) {
    return base64Encode("$config@${jsonEncode(resharers)}".toUint8ListFromUtf8);
  }

  String decodeRConfig(String rConfig) {
    return base64Decode(rConfig).toUtf8String.split("@").first;
  }
}

final class FrostInsufficientFundsException implements Exception {}

final class FrostBadIndexException implements Exception {}

final class OpaqueWrapper {
  final Object _value;

  const OpaqueWrapper(this._value);

  T getValue<T>() {
    if (_value is T) return _value as T;
    throw Exception(
      "OpaqueWrapper.getValue type of ${_value.runtimeType} is not ${T.runtimeType}",
    );
  }

  @override
  String toString() => "OpaqueWrapper(${_value.runtimeType})";
}

typedef FrostAddressDerivationData = ({
  int account,
  bool change,
  int index,
  bool secure,
});

class FrostOutput {
  final Uint8List hash;
  final int vout;
  final int value;
  final Uint8List scriptPubKey;

  final FrostAddressDerivationData? addressDerivationData;

  FrostOutput({
    required this.hash,
    required this.vout,
    required this.value,
    required this.scriptPubKey,
    required this.addressDerivationData,
  });

  @override
  String toString() =>
      'FrostOutput{'
      'hash: $hash, '
      'vout: $vout, '
      'value: $value, '
      'scriptPubKey: $scriptPubKey, '
      'addressDerivationData: $addressDerivationData'
      '}';
}

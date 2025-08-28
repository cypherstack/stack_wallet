import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/output.dart';
import 'package:frostdart/util.dart';

import '../models/isar/models/blockchain_data/utxo.dart';
import '../utilities/amount/amount.dart';
import '../utilities/extensions/extensions.dart';
import '../utilities/logger.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../wallets/models/tx_recipient.dart';

abstract class Frost {
  //==================== utility ===============================================
  static List<String> getParticipants({required String multisigConfig}) {
    try {
      final numberOfParticipants = multisigParticipants(
        multisigConfig: multisigConfig,
      );

      final List<String> participants = [];
      for (int i = 0; i < numberOfParticipants; i++) {
        participants.add(
          multisigParticipant(multisigConfig: multisigConfig, index: i),
        );
      }

      return participants;
    } catch (e, s) {
      Logging.instance.f("getParticipants failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static bool validateEncodedMultisigConfig({required String encodedConfig}) {
    try {
      decodeMultisigConfig(multisigConfig: encodedConfig);
      return true;
    } catch (e, s) {
      Logging.instance.f(
        "validateEncodedMultisigConfig failed: ",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  static int getThreshold({required String multisigConfig}) {
    try {
      final threshold = multisigThreshold(multisigConfig: multisigConfig);

      return threshold;
    } catch (e, s) {
      Logging.instance.f("getThreshold failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static ({
    List<({String address, Amount amount})> recipients,
    String changeAddress,
    int feePerWeight,
    List<Output> inputs,
  })
  extractDataFromSignConfig({
    required String serializedKeys,
    required String signConfig,
    required CryptoCurrency coin,
  }) {
    try {
      final network =
          coin.network.isTestNet ? Network.Testnet : Network.Mainnet;
      final signConfigPointer = decodedSignConfig(
        encodedConfig: signConfig,
        network: network,
        serializedKeys: serializedKeys,
      );

      // get various data from config
      final feePerWeight = signFeePerWeight(
        signConfigPointer: signConfigPointer,
      );
      final changeAddress = signChange(signConfigPointer: signConfigPointer);
      final recipientsCount = signPayments(
        signConfigPointer: signConfigPointer,
      );

      // get tx recipient info
      final List<({String address, Amount amount})> recipients = [];
      for (int i = 0; i < recipientsCount; i++) {
        final String address = signPaymentAddress(
          signConfigPointer: signConfigPointer,
          index: i,
        );
        final int amount = signPaymentAmount(
          signConfigPointer: signConfigPointer,
          index: i,
        );
        recipients.add((
          address: address,
          amount: Amount(
            rawValue: BigInt.from(amount),
            fractionDigits: coin.fractionDigits,
          ),
        ));
      }

      // get utxos
      final count = signInputs(signConfigPointer: signConfigPointer);
      final List<Output> outputs = [];
      for (int i = 0; i < count; i++) {
        final output = signInput(
          thresholdKeysWrapperPointer: deserializeKeys(keys: serializedKeys),
          signConfig: signConfig,
          index: i,
          network: network,
        );

        outputs.add(output);
      }

      return (
        recipients: recipients,
        changeAddress: changeAddress,
        feePerWeight: feePerWeight,
        inputs: outputs,
      );
    } catch (e, s) {
      Logging.instance.f(
        "extractDataFromSignConfig failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  //==================== wallet creation =======================================

  static String createMultisigConfig({
    required String name,
    required int threshold,
    required List<String> participants,
  }) {
    try {
      final config = newMultisigConfig(
        name: name,
        threshold: threshold,
        participants: participants,
      );

      return config;
    } catch (e, s) {
      Logging.instance.f(
        "createMultisigConfig failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static ({
    String seed,
    String commitments,
    Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    Pointer<SecretShareMachineWrapper> secretShareMachineWrapperPtr,
  })
  startKeyGeneration({required String multisigConfig, required String myName}) {
    try {
      final startKeyGenResPtr = startKeyGen(
        multisigConfig: multisigConfig,
        myName: myName,
        language: Language.english,
      );

      final seed = startKeyGenResPtr.ref.seed.toDartString();
      final commitments = startKeyGenResPtr.ref.commitments.toDartString();
      final configWithNamePtr = startKeyGenResPtr.ref.config;
      final machinePtr = startKeyGenResPtr.ref.machine;

      return (
        seed: seed,
        commitments: commitments,
        multisigConfigWithNamePtr: configWithNamePtr,
        secretShareMachineWrapperPtr: machinePtr,
      );
    } catch (e, s) {
      Logging.instance.f(
        "startKeyGeneration failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static ({String share, Pointer<SecretSharesRes> secretSharesResPtr})
  generateSecretShares({
    required Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    required String mySeed,
    required Pointer<SecretShareMachineWrapper> secretShareMachineWrapperPtr,
    required List<String> commitments,
  }) {
    try {
      final secretSharesResPtr = getSecretShares(
        multisigConfigWithName: multisigConfigWithNamePtr,
        seed: mySeed,
        language: Language.english,
        machine: secretShareMachineWrapperPtr,
        commitments: commitments,
      );

      final share = secretSharesResPtr.ref.shares.toDartString();

      return (share: share, secretSharesResPtr: secretSharesResPtr);
    } catch (e, s) {
      Logging.instance.f(
        "generateSecretShares failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static ({Uint8List multisigId, String recoveryString, String serializedKeys})
  completeKeyGeneration({
    required Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
    required Pointer<SecretSharesRes> secretSharesResPtr,
    required List<String> shares,
  }) {
    try {
      final keyGenResPtr = completeKeyGen(
        multisigConfigWithName: multisigConfigWithNamePtr,
        machineAndCommitments: secretSharesResPtr,
        shares: shares,
      );

      final id = Uint8List.fromList(
        List<int>.generate(
          MULTISIG_ID_LENGTH,
          (index) => keyGenResPtr.ref.multisig_id[index],
        ),
      );

      final recoveryString = keyGenResPtr.ref.recovery.toDartString();

      final serializedKeys = serializeKeys(keys: keyGenResPtr.ref.keys);

      return (
        multisigId: id,
        recoveryString: recoveryString,
        serializedKeys: serializedKeys,
      );
    } catch (e, s) {
      Logging.instance.f(
        "completeKeyGeneration failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  //=================== transaction creation ===================================

  static String createSignConfig({
    required String serializedKeys,
    required int network,
    required List<
      ({
        UTXO utxo,
        Uint8List scriptPubKey,
        AddressDerivationData addressDerivationData,
      })
    >
    inputs,
    required List<TxRecipient> outputs,
    required String changeAddress,
    required int feePerWeight,
  }) {
    try {
      final signConfig = newSignConfig(
        thresholdKeysWrapperPointer: deserializeKeys(keys: serializedKeys),
        network: network,
        outputs:
            inputs
                .map(
                  (e) => Output(
                    hash: e.utxo.txid.toUint8ListFromHex,
                    vout: e.utxo.vout,
                    value: e.utxo.value,
                    scriptPubKey: e.scriptPubKey,
                    addressDerivationData: e.addressDerivationData,
                  ),
                )
                .toList(),
        paymentAddresses: outputs.map((e) => e.address).toList(),
        paymentAmounts: outputs.map((e) => e.amount.raw.toInt()).toList(),
        change: changeAddress,
        feePerWeight: feePerWeight,
      );

      return signConfig;
    } catch (e, s) {
      Logging.instance.f("createSignConfig failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static ({
    Pointer<TransactionSignMachineWrapper> machinePtr,
    String preprocess,
  })
  attemptSignConfig({
    required int network,
    required String config,
    required String serializedKeys,
  }) {
    try {
      final keys = deserializeKeys(keys: serializedKeys);

      final attemptSignRes = attemptSign(
        thresholdKeysWrapperPointer: keys,
        network: network,
        signConfig: config,
      );

      return (
        preprocess: attemptSignRes.ref.preprocess.toDartString(),
        machinePtr: attemptSignRes.ref.machine,
      );
    } catch (e, s) {
      Logging.instance.f("attemptSignConfig failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static ({
    Pointer<TransactionSignatureMachineWrapper> machinePtr,
    String share,
  })
  continueSigning({
    required Pointer<TransactionSignMachineWrapper> machinePtr,
    required List<String> preprocesses,
  }) {
    try {
      final continueSignRes = continueSign(
        machine: machinePtr,
        preprocesses: preprocesses,
      );

      return (
        share: continueSignRes.ref.preprocess.toDartString(),
        machinePtr: continueSignRes.ref.machine,
      );
    } catch (e, s) {
      Logging.instance.f("continueSigning failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static String completeSigning({
    required Pointer<TransactionSignatureMachineWrapper> machinePtr,
    required List<String> shares,
  }) {
    try {
      final rawTransaction = completeSign(machine: machinePtr, shares: shares);

      return rawTransaction;
    } catch (e, s) {
      Logging.instance.f("completeSigning failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static Pointer<SignConfig> decodedSignConfig({
    required String serializedKeys,
    required String encodedConfig,
    required int network,
  }) {
    try {
      final configPtr = decodeSignConfig(
        thresholdKeysWrapperPointer: deserializeKeys(keys: serializedKeys),
        encodedSignConfig: encodedConfig,
        network: network,
      );
      return configPtr;
    } catch (e, s) {
      Logging.instance.f("decodedSignConfig failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  //========================== resharing =======================================

  static String createResharerConfig({
    required int newThreshold,
    required List<int> resharers,
    required List<String> newParticipants,
  }) {
    try {
      final config = newResharerConfig(
        newThreshold: newThreshold,
        newParticipants: newParticipants,
        resharers: resharers,
      );

      return config;
    } catch (e, s) {
      Logging.instance.f(
        "createResharerConfig failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static ({String resharerStart, Pointer<StartResharerRes> machine})
  beginResharer({required String serializedKeys, required String config}) {
    try {
      final result = startResharer(
        serializedKeys: serializedKeys,
        config: config,
      );

      return (resharerStart: result.encoded, machine: result.machine);
    } catch (e, s) {
      Logging.instance.f("beginResharer failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// expects [resharerStarts] of length equal to resharers.
  static ({String resharedStart, Pointer<StartResharedRes> prior})
  beginReshared({
    required String myName,
    required String resharerConfig,
    required List<String> resharerStarts,
  }) {
    try {
      final result = startReshared(
        newMultisigName: 'unused_property',
        myName: myName,
        resharerConfig: resharerConfig,
        resharerStarts: resharerStarts,
      );
      return (resharedStart: result.encoded, prior: result.machine);
    } catch (e, s) {
      Logging.instance.f("beginReshared failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// expects [encryptionKeysOfResharedTo] of length equal to new participants
  static String finishResharer({
    required StartResharerRes machine,
    required List<String> encryptionKeysOfResharedTo,
  }) {
    try {
      final result = completeResharer(
        machine: machine,
        encryptionKeysOfResharedTo: encryptionKeysOfResharedTo,
      );
      return result;
    } catch (e, s) {
      Logging.instance.f("finishResharer failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// expects [resharerCompletes] of length equal to resharers
  static ({String multisigConfig, String serializedKeys, String resharedId})
  finishReshared({
    required StartResharedRes prior,
    required List<String> resharerCompletes,
  }) {
    try {
      final result = completeReshared(
        prior: prior,
        resharerCompletes: resharerCompletes,
      );
      return result;
    } catch (e, s) {
      Logging.instance.f("finishReshared failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  static Pointer<ResharerConfig> decodedResharerConfig({
    required String resharerConfig,
  }) {
    try {
      final config = decodeResharerConfig(resharerConfig: resharerConfig);

      return config;
    } catch (e, s) {
      Logging.instance.f(
        "decodedResharerConfig failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static ({
    int newThreshold,
    Map<String, int> resharers,
    List<String> newParticipants,
  })
  extractResharerConfigData({required String rConfig}) {
    final decoded = _decodeRConfigWithResharers(rConfig);
    final resharerConfig = decoded.config;

    try {
      final newThreshold = resharerNewThreshold(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ),
      );

      final resharersCount = resharerResharers(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ),
      );
      final List<int> resharers = [];
      for (int i = 0; i < resharersCount; i++) {
        resharers.add(
          resharerResharer(
            resharerConfigPointer: decodedResharerConfig(
              resharerConfig: resharerConfig,
            ),
            index: i,
          ),
        );
      }

      final newParticipantsCount = resharerNewParticipants(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ),
      );
      final List<String> newParticipants = [];
      for (int i = 0; i < newParticipantsCount; i++) {
        newParticipants.add(
          resharerNewParticipant(
            resharerConfigPointer: decodedResharerConfig(
              resharerConfig: resharerConfig,
            ),
            index: i,
          ),
        );
      }

      final Map<String, int> resharersMap = {};

      for (final resharer in resharers) {
        resharersMap[decoded.resharers.entries
                .firstWhere((e) => e.value == resharer)
                .key] =
            resharer;
      }

      return (
        newThreshold: newThreshold,
        resharers: resharersMap,
        newParticipants: newParticipants,
      );
    } catch (e, s) {
      Logging.instance.f(
        "extractResharerConfigData failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static String encodeRConfig(String config, Map<String, int> resharers) {
    return base64Encode("$config@${jsonEncode(resharers)}".toUint8ListFromUtf8);
  }

  static String decodeRConfig(String rConfig) {
    return base64Decode(rConfig).toUtf8String.split("@").first;
  }

  static ({Map<String, int> resharers, String config})
  _decodeRConfigWithResharers(String rConfig) {
    final parts = base64Decode(rConfig).toUtf8String.split("@");

    final config = parts[0];
    final resharers = Map<String, int>.from(jsonDecode(parts[1]) as Map);

    return (resharers: resharers, config: config);
  }
}

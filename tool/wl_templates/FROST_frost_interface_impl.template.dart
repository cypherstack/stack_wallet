//ON
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/output.dart';
import 'package:frostdart/util.dart';

import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/extensions/extensions.dart';
import '../../utilities/logger.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../../wallets/models/tx_recipient.dart';
//END_ON
import '../interfaces/frost_interface.dart';

FrostInterface get frostInterface => _getInterface();

//OFF
FrostInterface _getInterface() => throw Exception("FROST not enabled!");

//END_OFF
//ON
FrostInterface _getInterface() => const _FrostInterfaceImpl();

final class _FrostInterfaceImpl extends FrostInterface {
  const _FrostInterfaceImpl();

  @override
  ({OpaqueWrapper machinePtr, String preprocess}) attemptSignConfig({
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
        machinePtr: OpaqueWrapper(attemptSignRes.ref.machine),
      );
    } catch (e, s) {
      Logging.instance.f("attemptSignConfig failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({OpaqueWrapper prior, String resharedStart}) beginReshared({
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
      return (
        resharedStart: result.encoded,
        prior: OpaqueWrapper(result.machine),
      );
    } catch (e, s) {
      Logging.instance.f("beginReshared failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({OpaqueWrapper machine, String resharerStart}) beginResharer({
    required String serializedKeys,
    required String config,
  }) {
    try {
      final result = startResharer(
        serializedKeys: serializedKeys,
        config: config,
      );

      return (
        resharerStart: result.encoded,
        machine: OpaqueWrapper(result.machine),
      );
    } catch (e, s) {
      Logging.instance.f("beginResharer failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({Uint8List multisigId, String recoveryString, String serializedKeys})
  completeKeyGeneration({
    required OpaqueWrapper multisigConfigWithNamePtr,
    required OpaqueWrapper secretSharesResPtr,
    required List<String> shares,
  }) {
    try {
      final keyGenResPtr = completeKeyGen(
        multisigConfigWithName: multisigConfigWithNamePtr.getValue(),
        machineAndCommitments: secretSharesResPtr.getValue(),
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

  @override
  String completeSigning({
    required OpaqueWrapper machinePtr,
    required List<String> shares,
  }) {
    try {
      final rawTransaction = completeSign(
        machine: machinePtr.getValue(),
        shares: shares,
      );

      return rawTransaction;
    } catch (e, s) {
      Logging.instance.f("completeSigning failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({OpaqueWrapper machinePtr, String share}) continueSigning({
    required OpaqueWrapper machinePtr,
    required List<String> preprocesses,
  }) {
    try {
      final continueSignRes = continueSign(
        machine: machinePtr.getValue(),
        preprocesses: preprocesses,
      );

      return (
        share: continueSignRes.ref.preprocess.toDartString(),
        machinePtr: OpaqueWrapper(continueSignRes.ref.machine),
      );
    } catch (e, s) {
      Logging.instance.f("continueSigning failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  String createMultisigConfig({
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

  @override
  String createResharerConfig({
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

  @override
  String createSignConfig({
    required String serializedKeys,
    required int network,
    required List<
      ({
        Uint8List scriptPubKey,
        UTXO utxo,
        FrostAddressDerivationData addressDerivationData,
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
        outputs: inputs
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

      if (e is FrostdartException && e.errorCode == NOT_ENOUGH_FUNDS_ERROR) {
        throw FrostInsufficientFundsException();
      }

      rethrow;
    }
  }

  @override
  OpaqueWrapper decodedResharerConfig({required String resharerConfig}) {
    try {
      final config = decodeResharerConfig(resharerConfig: resharerConfig);

      return OpaqueWrapper(config);
    } catch (e, s) {
      Logging.instance.f(
        "decodedResharerConfig failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  OpaqueWrapper decodedSignConfig({
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
      return OpaqueWrapper(configPtr);
    } catch (e, s) {
      Logging.instance.f("decodedSignConfig failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({
    String changeAddress,
    int feePerWeight,
    List<FrostOutput> inputs,
    List<({String address, Amount amount})> recipients,
  })
  extractDataFromSignConfig({
    required String serializedKeys,
    required String signConfig,
    required CryptoCurrency coin,
  }) {
    try {
      final network = coin.network.isTestNet
          ? Network.Testnet
          : Network.Mainnet;
      final signConfigPointer = decodedSignConfig(
        encodedConfig: signConfig,
        network: network,
        serializedKeys: serializedKeys,
      );

      // get various data from config
      final feePerWeight = signFeePerWeight(
        signConfigPointer: signConfigPointer.getValue(),
      );
      final changeAddress = signChange(
        signConfigPointer: signConfigPointer.getValue(),
      );
      final recipientsCount = signPayments(
        signConfigPointer: signConfigPointer.getValue(),
      );

      // get tx recipient info
      final List<({String address, Amount amount})> recipients = [];
      for (int i = 0; i < recipientsCount; i++) {
        final String address = signPaymentAddress(
          signConfigPointer: signConfigPointer.getValue(),
          index: i,
        );
        final int amount = signPaymentAmount(
          signConfigPointer: signConfigPointer.getValue(),
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
      final count = signInputs(signConfigPointer: signConfigPointer.getValue());
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
        inputs: outputs
            .map(
              (e) => FrostOutput(
                hash: e.hash,
                vout: e.vout,
                value: e.value,
                scriptPubKey: e.scriptPubKey,
                addressDerivationData: e.addressDerivationData,
              ),
            )
            .toList(),
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

  @override
  ({List<String> newParticipants, int newThreshold, Map<String, int> resharers})
  extractResharerConfigData({required String rConfig}) {
    final decoded = _decodeRConfigWithResharers(rConfig);
    final resharerConfig = decoded.config;

    try {
      final newThreshold = resharerNewThreshold(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ).getValue(),
      );

      final resharersCount = resharerResharers(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ).getValue(),
      );
      final List<int> resharers = [];
      for (int i = 0; i < resharersCount; i++) {
        resharers.add(
          resharerResharer(
            resharerConfigPointer: decodedResharerConfig(
              resharerConfig: resharerConfig,
            ).getValue(),
            index: i,
          ),
        );
      }

      final newParticipantsCount = resharerNewParticipants(
        resharerConfigPointer: decodedResharerConfig(
          resharerConfig: resharerConfig,
        ).getValue(),
      );
      final List<String> newParticipants = [];
      for (int i = 0; i < newParticipantsCount; i++) {
        newParticipants.add(
          resharerNewParticipant(
            resharerConfigPointer: decodedResharerConfig(
              resharerConfig: resharerConfig,
            ).getValue(),
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

  @override
  ({String multisigConfig, String resharedId, String serializedKeys})
  finishReshared({
    required OpaqueWrapper prior,
    required List<String> resharerCompletes,
  }) {
    try {
      final result = completeReshared(
        prior: prior.getValue(),
        resharerCompletes: resharerCompletes,
      );
      return result;
    } catch (e, s) {
      Logging.instance.f("finishReshared failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  String finishResharer({
    required OpaqueWrapper machine,
    required List<String> encryptionKeysOfResharedTo,
  }) {
    try {
      final result = completeResharer(
        machine: machine.getValue(),
        encryptionKeysOfResharedTo: encryptionKeysOfResharedTo,
      );
      return result;
    } catch (e, s) {
      Logging.instance.f("finishResharer failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({OpaqueWrapper secretSharesResPtr, String share}) generateSecretShares({
    required OpaqueWrapper multisigConfigWithNamePtr,
    required String mySeed,
    required OpaqueWrapper secretShareMachineWrapperPtr,
    required List<String> commitments,
  }) {
    try {
      final secretSharesResPtr = getSecretShares(
        multisigConfigWithName: multisigConfigWithNamePtr.getValue(),
        seed: mySeed,
        language: Language.english,
        machine: secretShareMachineWrapperPtr.getValue(),
        commitments: commitments,
      );

      final share = secretSharesResPtr.ref.shares.toDartString();

      return (
        share: share,
        secretSharesResPtr: OpaqueWrapper(secretSharesResPtr),
      );
    } catch (e, s) {
      Logging.instance.f(
        "generateSecretShares failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  List<String> getParticipants({required String multisigConfig}) {
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

  @override
  int getThreshold({required String multisigConfig}) {
    try {
      final threshold = multisigThreshold(multisigConfig: multisigConfig);

      return threshold;
    } catch (e, s) {
      Logging.instance.f("getThreshold failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  ({
    String commitments,
    OpaqueWrapper multisigConfigWithNamePtr,
    OpaqueWrapper secretShareMachineWrapperPtr,
    String seed,
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
        multisigConfigWithNamePtr: OpaqueWrapper(configWithNamePtr),
        secretShareMachineWrapperPtr: OpaqueWrapper(machinePtr),
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

  @override
  bool validateEncodedMultisigConfig({required String encodedConfig}) {
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

  @override
  Uint8List getMultisigSalt({required String multisigConfig}) =>
      multisigSalt(multisigConfig: multisigConfig);

  @override
  int participantIndexFromKeys({required String serializedKeys}) =>
      getParticipantIndexFromKeys(serializedKeys: serializedKeys);

  @override
  int getMultisigThreshold({required String multisigConfig}) =>
      multisigThreshold(multisigConfig: multisigConfig);

  @override
  int thresholdFromKeys({required String serializedKeys}) =>
      getThresholdFromKeys(serializedKeys: serializedKeys);

  @override
  Uint8List getResharerSalt({required String resharerConfig}) =>
      resharerSalt(resharerConfig: resharerConfig);

  @override
  OpaqueWrapper getDeserializedKeys({required String keys}) =>
      OpaqueWrapper(deserializeKeys(keys: keys));

  @override
  String getAddressForKeys({
    required OpaqueWrapper keys,
    required int network,
    required FrostAddressDerivationData addressDerivationData,
    required bool secure,
  }) {
    try {
      return addressForKeys(
        network: network,
        keys: keys.getValue(),
        addressDerivationData: addressDerivationData,
        secure: secure,
      );
    } on FrostdartException catch (e) {
      if (e.errorCode == 72) throw FrostBadIndexException();
      rethrow;
    }
  }

  @override
  int get mainnet => Network.Mainnet;

  @override
  int get testnet => Network.Testnet;

  ({Map<String, int> resharers, String config}) _decodeRConfigWithResharers(
    String rConfig,
  ) {
    final parts = base64Decode(rConfig).toUtf8String.split("@");

    final config = parts[0];
    final resharers = Map<String, int>.from(jsonDecode(parts[1]) as Map);

    return (resharers: resharers, config: config);
  }
}

//END_ON

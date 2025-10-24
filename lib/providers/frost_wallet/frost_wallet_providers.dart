import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallets/models/incomplete_frost_wallet.dart';
import '../../wallets/models/tx_data.dart';
import '../../wl_gen/interfaces/frost_interface.dart';

// =================== wallet creation =========================================
final pFrostMultisigConfig = StateProvider<String?>((ref) => null);
final pFrostMyName = StateProvider<String?>((ref) => null);

final pFrostStartKeyGenData =
    StateProvider<
      ({
        String seed,
        String commitments,
        OpaqueWrapper multisigConfigWithNamePtr,
        OpaqueWrapper secretShareMachineWrapperPtr,
      })?
    >((_) => null);

final pFrostSecretSharesData =
    StateProvider<({String share, OpaqueWrapper secretSharesResPtr})?>(
      (ref) => null,
    );

final pFrostCompletedKeyGenData =
    StateProvider<
      ({Uint8List multisigId, String recoveryString, String serializedKeys})?
    >((ref) => null);

// ================= transaction creation ======================================
final pFrostTxData = StateProvider<TxData?>((ref) => null);

final pFrostAttemptSignData =
    StateProvider<({OpaqueWrapper machinePtr, String preprocess})?>(
      (ref) => null,
    );

final pFrostContinueSignData =
    StateProvider<({OpaqueWrapper machinePtr, String share})?>((ref) => null);

// ===================== shared/util ===========================================
final pFrostSelectParticipantsUnordered = StateProvider<List<String>?>(
  (ref) => null,
);

// ========================= resharing =========================================
final pFrostResharingData = Provider((ref) => _ResharingData());

class _ResharingData {
  String? myName;

  IncompleteFrostWallet? incompleteWallet;

  // resharer encoded config string
  String? resharerRConfig;

  ({
    int newThreshold,
    Map<String, int> resharers,
    List<String> newParticipants,
  })?
  get configData => resharerRConfig != null
      ? frostInterface.extractResharerConfigData(rConfig: resharerRConfig!)
      : null;

  // resharer start string (for sharing) and machine
  ({String resharerStart, OpaqueWrapper machine})? startResharerData;

  // reshared start string (for sharing) and machine
  ({String resharedStart, OpaqueWrapper prior})? startResharedData;

  // resharer complete string (for sharing)
  String? resharerComplete;

  // new keys and config with an ID
  ({String multisigConfig, String serializedKeys, String resharedId})?
  newWalletData;

  // reset/clear all data
  void reset() {
    resharerRConfig = null;
    startResharerData = null;
    startResharedData = null;
    resharerComplete = null;
    newWalletData = null;
    incompleteWallet = null;
  }
}

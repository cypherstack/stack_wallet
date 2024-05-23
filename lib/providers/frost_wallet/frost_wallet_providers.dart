import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import '../../services/frost.dart';
import '../../wallets/models/incomplete_frost_wallet.dart';
import '../../wallets/models/tx_data.dart';

// =================== wallet creation =========================================
final pFrostMultisigConfig = StateProvider<String?>((ref) => null);
final pFrostMyName = StateProvider<String?>((ref) => null);

final pFrostStartKeyGenData = StateProvider<
    ({
      String seed,
      String commitments,
      Pointer<MultisigConfigWithName> multisigConfigWithNamePtr,
      Pointer<SecretShareMachineWrapper> secretShareMachineWrapperPtr,
    })?>((_) => null);

final pFrostSecretSharesData = StateProvider<
    ({
      String share,
      Pointer<SecretSharesRes> secretSharesResPtr,
    })?>((ref) => null);

final pFrostCompletedKeyGenData = StateProvider<
    ({
      Uint8List multisigId,
      String recoveryString,
      String serializedKeys,
    })?>((ref) => null);

// ================= transaction creation ======================================
final pFrostTxData = StateProvider<TxData?>((ref) => null);

final pFrostAttemptSignData = StateProvider<
    ({
      Pointer<TransactionSignMachineWrapper> machinePtr,
      String preprocess,
    })?>((ref) => null);

final pFrostContinueSignData = StateProvider<
    ({
      Pointer<TransactionSignatureMachineWrapper> machinePtr,
      String share,
    })?>((ref) => null);

// ===================== shared/util ===========================================
final pFrostSelectParticipantsUnordered =
    StateProvider<List<String>?>((ref) => null);

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
  })? get configData => resharerRConfig != null
      ? Frost.extractResharerConfigData(rConfig: resharerRConfig!)
      : null;

  // resharer start string (for sharing) and machine
  ({
    String resharerStart,
    Pointer<StartResharerRes> machine,
  })? startResharerData;

  // reshared start string (for sharing) and machine
  ({
    String resharedStart,
    Pointer<StartResharedRes> prior,
  })? startResharedData;

  // resharer complete string (for sharing)
  String? resharerComplete;

  // new keys and config with an ID
  ({
    String multisigConfig,
    String serializedKeys,
    String resharedId,
  })? newWalletData;

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

import 'package:bip48/bip48.dart';
import 'package:coinlib/coinlib.dart';

/// Represents the parameters needed to create a shared multisig account.
class MultisigParams {
  /// Number of required signatures (M in M-of-N).
  final int threshold;

  /// Total number of participants (N in M-of-N).
  final int totalCosigners;

  /// BIP44 coin type (e.g., 0 for Bitcoin mainnet).
  final int coinType;

  /// BIP44/48 account index.
  final int account;

  /// BIP48 script type (e.g., p2sh, p2wsh).
  final Bip48ScriptType scriptType;

  /// Creates a new set of multisig parameters.
  const MultisigParams({
    required this.threshold,
    required this.totalCosigners,
    required this.coinType,
    required this.account,
    required this.scriptType,
  });

  /// Validates the parameters for consistency.
  ///
  /// Returns true if all parameters are valid:
  /// - threshold > 0
  /// - threshold <= totalCosigners
  /// - account >= 0
  /// - coinType >= 0
  bool isValid() {
    return threshold > 0 &&
        threshold <= totalCosigners &&
        account >= 0 &&
        coinType >= 0;
  }
}

/// Represents a participant in the multisig setup process.
class CosignerInfo {
  /// The cosigner's BIP48 account-level extended public key.
  final String accountXpub;

  /// Position in the sorted set of cosigners (0-based).
  final int index;

  /// Creates info about a cosigner participant.
  const CosignerInfo({
    required this.accountXpub,
    required this.index,
  });
}

/// Coordinates the creation of a shared multisig account between multiple users.
class MultisigCoordinator {
  /// Local master key if available (otherwise uses accountXpub).
  final HDPrivateKey? localMasterKey;

  /// Parameters for the shared multisig wallet.
  final MultisigParams params;

  /// Collected cosigner information.
  final List<CosignerInfo> _cosigners = [];

  /// Local account xpub when not using master key.
  String? _accountXpub;

  /// Creates a coordinator using the local HD master private key.
  ///
  /// Uses the provided [localMasterKey] to derive the account xpub that will
  /// be shared with other cosigners.
  MultisigCoordinator({
    required this.localMasterKey,
    required this.params,
  }) {
    if (!params.isValid()) {
      throw ArgumentError('Invalid multisig parameters');
    }
  }

  /// Creates a coordinator using a pre-derived account xpub.
  ///
  /// This constructor should be used when you only want to verify addresses
  /// or don't have access to the master private key.
  MultisigCoordinator.fromXpub({
    required String accountXpub,
    required this.params,
  }) : localMasterKey = null {
    if (!params.isValid()) {
      throw ArgumentError('Invalid multisig parameters');
    }
    _accountXpub = accountXpub;
  }

  /// Gets this user's account xpub that needs to be shared with other cosigners.
  ///
  /// If created with a master key, derives the account xpub at the BIP48 path.
  /// If created with fromXpub, returns the provided account xpub.
  String getLocalAccountXpub() {
    if (_accountXpub != null) {
      return _accountXpub!;
    }

    if (localMasterKey == null) {
      throw StateError('No master key or account xpub available');
    }

    final path = bip48DerivationPath(
      coinType: params.coinType,
      account: params.account,
      scriptType: params.scriptType,
    );
    final accountKey = localMasterKey!.derivePath(path);
    return accountKey.hdPublicKey.encode(bitcoinNetwork.mainnet.pubHDPrefix);
  }

  /// Adds a cosigner's account xpub to the set.
  ///
  /// Throws [StateError] if all cosigners have already been added.
  void addCosigner(String accountXpub) {
    if (_cosigners.length >= params.totalCosigners - 1) {
      throw StateError('All cosigners have been added');
    }

    // Assign index based on current position
    _cosigners.add(CosignerInfo(
      accountXpub: accountXpub,
      index: _cosigners.length + 1, // Local user is always index 0.
    ));
  }

  /// Checks if all required cosigner information has been collected.
  bool isComplete() {
    return _cosigners.length == params.totalCosigners - 1;
  }

  /// Creates the local wallet instance once all cosigners are added.
  ///
  /// Throws [StateError] if not all cosigners have been added yet.
  Bip48Wallet createWallet() {
    if (!isComplete()) {
      throw StateError('Not all cosigners have been added');
    }

    // Create wallet with either our master key or xpub
    final wallet = localMasterKey != null
        ? Bip48Wallet(
            masterKey: localMasterKey,
            coinType: params.coinType,
            account: params.account,
            scriptType: params.scriptType,
            threshold: params.threshold,
            totalKeys: params.totalCosigners,
          )
        : Bip48Wallet(
            accountXpub: _accountXpub,
            coinType: params.coinType,
            account: params.account,
            scriptType: params.scriptType,
            threshold: params.threshold,
            totalKeys: params.totalCosigners,
          );

    // Add all cosigner xpubs.
    for (final cosigner in _cosigners) {
      wallet.addCosignerXpub(cosigner.accountXpub);
    }

    return wallet;
  }

  /// Verifies that derived addresses match between all participants.
  ///
  /// Takes a list of [sharedAddresses] that other participants derived, along
  /// with the [indices] used to derive them and whether they are [isChange]
  /// addresses.
  ///
  /// Returns true if all provided addresses match our local derivation.
  bool verifyAddresses(List<String> sharedAddresses,
      {required List<int> indices, required bool isChange}) {
    if (!isComplete()) return false;

    final wallet = createWallet();
    for (final idx in indices) {
      final derivedAddress =
          wallet.deriveMultisigAddress(idx, isChange: isChange);
      final sharedAddress = sharedAddresses[indices.indexOf(idx)];
      if (derivedAddress != sharedAddress) return false;
    }
    return true;
  }

  /// Gets a list of derived addresses for verification.
  ///
  /// Derives addresses at the specified [indices] on either the external
  /// or change chain based on [isChange].
  ///
  /// Throws [StateError] if not all cosigners have been added yet.
  List<String> getVerificationAddresses(
      {required List<int> indices, required bool isChange}) {
    if (!isComplete()) {
      throw StateError('Not all cosigners have been added');
    }

    final wallet = createWallet();
    return indices
        .map((idx) => wallet.deriveMultisigAddress(idx, isChange: isChange))
        .toList();
  }
}

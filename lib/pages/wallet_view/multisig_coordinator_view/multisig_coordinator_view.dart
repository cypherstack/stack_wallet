import 'dart:async';
import 'dart:io';

import 'package:bip48/bip48.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/background.dart';
import '../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/node_service_provider.dart';
import '../../../providers/global/prefs_provider.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../services/transaction_notification_tracker.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/coins/bip48_bitcoin.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/isar/models/wallet_info.dart';
import '../../../wallets/wallet/intermediate/bip39_hd_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/icon_widgets/copy_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../add_wallet_views/restore_wallet_view/sub_widgets/restore_failed_dialog.dart';
import '../../add_wallet_views/restore_wallet_view/sub_widgets/restore_succeeded_dialog.dart';
import '../../add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import '../../home_view/home_view.dart';

final multisigCoordinatorStateProvider =
    StateNotifierProvider<MultisigCoordinatorState, MultisigCoordinatorData>(
        (ref) {
  return MultisigCoordinatorState();
});

class MultisigCoordinatorState extends StateNotifier<MultisigCoordinatorData> {
  MultisigCoordinatorState() : super(const MultisigCoordinatorData());

  void updateThreshold(int threshold) {
    state = state.copyWith(threshold: threshold);
  }

  void updateParticipants(int total) {
    state = state.copyWith(participants: total);
  }

  void updateScriptType(MultisigScriptType type) {
    state = state.copyWith(scriptType: type);
  }

  void addCosignerXpub(String xpub) {
    if (state.cosignerXpubs.length < state.participants) {
      state = state.copyWith(
        cosignerXpubs: [...state.cosignerXpubs, xpub],
      );
    }
  }
}

class MultisigCoordinatorView extends ConsumerStatefulWidget {
  const MultisigCoordinatorView({
    super.key,
    required this.walletId,
    required this.scriptType,
    required this.participants,
    required this.threshold,
    required this.account,
  });

  final String walletId;
  final MultisigScriptType scriptType;
  final int participants;
  final int threshold;
  final int account;

  static const String routeName = "/multisigCoordinator";

  @override
  ConsumerState<MultisigCoordinatorView> createState() =>
      _MultisigSetupViewState();
}

class _MultisigSetupViewState extends ConsumerState<MultisigCoordinatorView> {
  final List<TextEditingController> xpubControllers = [];
  late Bip48Wallet _multisigWallet;
  String _myXpub = "";
  late final bool isDesktop;

  // bool _isNfcAvailable = false;
  // String _nfcStatus = 'Checking NFC availability...';

  @override
  void initState() {
    super.initState();
    isDesktop = Util.isDesktop;

    // Initialize controllers.
    for (int i = 0; i < widget.participants - 1; i++) {
      xpubControllers.add(TextEditingController());
    }

    // Initialize wallet and set xpub.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wallet = await (ref.read(pWallets).getWallet(widget.walletId)
          as Bip39HDWallet);
      final master = await wallet.getRootHDNode();

      final node = master.derivePath(BIP48Bitcoin(wallet.cryptoCurrency.network)
          .constructDerivePath(
              derivePathType: widget.scriptType == MultisigScriptType.segwit
                  ? DerivePathType.bip48p2shp2wsh
                  : DerivePathType.bip48p2wsh,
              chain: wallet.cryptoCurrency.network == CryptoCurrencyNetwork.main
                  ? 0
                  : 1, // TODO: Support coins other than Bitcoin.
              index: widget.scriptType == MultisigScriptType.segwit ? 1 : 2));

      _multisigWallet = Bip48Wallet(
        accountXpub: node.hdPublicKey.encode(
          wallet.cryptoCurrency.networkParams.pubHDPrefix,
        ),
        coinType: wallet.cryptoCurrency.network == CryptoCurrencyNetwork.main
            ? 0
            : 1, // TODO: Support coins other than Bitcoin.
        account: widget.account,
        scriptType: Bip48ScriptType.p2shMultisig,
        threshold: widget.threshold,
        totalKeys: widget.participants,
        network: wallet.cryptoCurrency.networkParams,
      );

      if (mounted) {
        setState(() => _myXpub = _multisigWallet.accountXpub);
      }
    });

    // _checkNfcAvailability();
  }

  @override
  void dispose() {
    for (final controller in xpubControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Future<void> _checkNfcAvailability() async {
  //   try {
  //     final availability = await NfcManager.instance.isAvailable();
  //     setState(() {
  //       _isNfcAvailable = availability;
  //       _nfcStatus = _isNfcAvailable
  //           ? 'NFC is available'
  //           : 'NFC is not available on this device';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _nfcStatus = 'Error checking NFC: $e';
  //       _isNfcAvailable = false;
  //     });
  //   }
  // }
  //
  // Future<void> _startNfcSession() async {
  //   if (!_isNfcAvailable) return;
  //
  //   setState(() => _nfcStatus = 'Ready to exchange information...');
  //
  //   try {
  //     await NfcManager.instance.startSession(
  //       onDiscovered: (tag) async {
  //         try {
  //           final ndef = Ndef.from(tag);
  //
  //           if (ndef == null) {
  //             setState(() => _nfcStatus = 'Tag is not NDEF compatible');
  //             return;
  //           }
  //
  //           final setupData = ref.watch(multisigSetupStateProvider);
  //
  //           if (ndef.isWritable) {
  //             final message = NdefMessage([
  //               NdefRecord.createMime(
  //                 'application/x-multisig-setup',
  //                 Uint8List.fromList(
  //                     utf8.encode(jsonEncode(setupData.toJson()))),
  //               ),
  //             ]);
  //
  //             try {
  //               await ndef.write(message);
  //               setState(
  //                   () => _nfcStatus = 'Configuration shared successfully');
  //             } catch (e) {
  //               setState(
  //                   () => _nfcStatus = 'Failed to share configuration: $e');
  //             }
  //           }
  //
  //           await NfcManager.instance.stopSession();
  //         } catch (e) {
  //           setState(() => _nfcStatus = 'Error during NFC exchange: $e');
  //           await NfcManager.instance.stopSession();
  //         }
  //       },
  //     );
  //   } catch (e) {
  //     setState(() => _nfcStatus = 'Error: $e');
  //     await NfcManager.instance.stopSession();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: SafeArea(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: AppBarBackButton(
              onPressed: () async {
                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  await Future<void>.delayed(const Duration(milliseconds: 75));
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Enter cosigner xPubs",
              style: STextStyles.navBarTitle(context),
            ),
            titleSpacing: 0,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "This is your extended public key (xPub) for each cosigner.  "
                            "Share it with each participant.",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const SizedBox(height: 24),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your xPub",
                                  style: STextStyles.w500_14(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textDark3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                            text: _myXpub),
                                        enabled: false,
                                        decoration: InputDecoration(
                                          hintText: "Loading xPub...",
                                          hintStyle:
                                              STextStyles.fieldLabel(context),
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textFieldDefaultBG,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SecondaryButton(
                                      width: 44,
                                      buttonHeight: ButtonHeight.xl,
                                      icon: QrCodeIcon(
                                        width: 20,
                                        height: 20,
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .buttonTextSecondary,
                                      ),
                                      onPressed: () {
                                        // TODO: Implement QR code scanning
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    SecondaryButton(
                                      width: 44,
                                      buttonHeight: ButtonHeight.xl,
                                      icon: CopyIcon(
                                        width: 20,
                                        height: 20,
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .buttonTextSecondary,
                                      ),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: _myXpub));
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Text(
                            "Enter the extended public key (xpub) for each cosigner.  "
                            "These can be obtained from each participant's wallet.",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const SizedBox(height: 24),

                          // Generate input fields for each cosigner.
                          for (int i = 1; i < widget.participants; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cosigner $i xPub",
                                    style:
                                        STextStyles.w500_14(context).copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textDark3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: xpubControllers[i - 1],
                                          decoration: InputDecoration(
                                            hintText: "Enter cosigner $i xPub",
                                            hintStyle:
                                                STextStyles.fieldLabel(context),
                                          ),
                                          onChanged: (value) {
                                            if (value.isNotEmpty) {
                                              ref
                                                  .read(
                                                      multisigCoordinatorStateProvider
                                                          .notifier)
                                                  .addCosignerXpub(value);
                                            }
                                            setState(
                                                () {}); // Trigger rebuild to update button state.
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SecondaryButton(
                                        width: 44,
                                        buttonHeight: ButtonHeight.xl,
                                        icon: QrCodeIcon(
                                          width: 20,
                                          height: 20,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .buttonTextSecondary,
                                        ),
                                        onPressed: () {
                                          // TODO: Implement QR code scanning
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      SecondaryButton(
                                        width: 44,
                                        buttonHeight: ButtonHeight.xl,
                                        icon: CopyIcon(
                                          width: 20,
                                          height: 20,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .buttonTextSecondary,
                                        ),
                                        onPressed: () async {
                                          final data = await Clipboard.getData(
                                              'text/plain');
                                          if (data?.text != null) {
                                            xpubControllers[i - 1].text =
                                                data!.text!;
                                            ref
                                                .read(
                                                    multisigCoordinatorStateProvider
                                                        .notifier)
                                                .addCosignerXpub(data.text!);
                                            setState(
                                                () {}); // Trigger rebuild to update button state.
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const Spacer(),

                          PrimaryButton(
                            label: "Create multisignature account",
                            enabled: xpubControllers.every(
                                (controller) => controller.text.isNotEmpty),
                            onPressed: () async {
                              final _newWallet = _multisigWallet;

                              // Add cosigners.
                              for (final controller in xpubControllers) {
                                _newWallet.addCosignerXpub(controller.text);
                                // TODO: handle error on InvalidBase58Checksum.
                              }

                              print(
                                  'First receiving address: ${_newWallet.deriveMultisigAddress(0, isChange: false)}');
                              print(
                                  'First change address: ${_newWallet.deriveMultisigAddress(0, isChange: true)}');

                              // TODO: Use attemptCreation to create new wallet
                              // with the additional multisig params as a
                              // BIP48BitcoinWallet.  If successful, show
                              // multisig params (script type, threshold,
                              // participants, account index) for backup.
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> attemptCreation() async {
    // if (!Platform.isLinux) await WakelockPlus.enable();

    final parentWallet =
        await (ref.read(pWallets).getWallet(widget.walletId) as Bip39HDWallet);

    String? otherDataJsonString;
    // TODO [prio=high]: Save MultisigCoordinatorData in otherDataJsonString.

    final info = WalletInfo.createNew(
      coin: parentWallet.cryptoCurrency,
      name:
          'widget.walletName', // TODO [prio=high]: Add wallet name input field to multisig setup view and pass it to the coordinator view here.
      restoreHeight: await parentWallet.chainHeight,
      otherDataJsonString: otherDataJsonString,
    );

    bool isRestoring = true;
    // show restoring in progress

    if (mounted) {
      unawaited(
        showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return RestoringDialog(
              // Replace with a bespoke dialog?
              onCancel: () async {
                isRestoring = false;

                await ref.read(pWallets).deleteWallet(
                      info,
                      ref.read(secureStoreProvider),
                    );
              },
            );
          },
        ),
      );
    }

    var node = ref
        .read(nodeServiceChangeNotifierProvider)
        .getPrimaryNodeFor(currency: parentWallet.cryptoCurrency);

    if (node == null) {
      node = parentWallet.cryptoCurrency.defaultNode;
      await ref.read(nodeServiceChangeNotifierProvider).setPrimaryNodeFor(
            coin: parentWallet.cryptoCurrency,
            node: node,
          );
    }

    final txTracker = TransactionNotificationTracker(walletId: info.walletId);

    try {
      final wallet = await Wallet.create(
        walletInfo: info,
        mainDB: ref.read(mainDBProvider),
        secureStorageInterface: ref.read(secureStoreProvider),
        nodeService: ref.read(nodeServiceChangeNotifierProvider),
        prefs: ref.read(prefsChangeNotifierProvider),
        mnemonicPassphrase: await parentWallet.getMnemonicPassphrase(),
        mnemonic: await parentWallet.getMnemonic(),
      );

      await wallet.init();

      await wallet.recover(isRescan: false);

      // check if state is still active before continuing
      if (mounted) {
        await wallet.info.setMnemonicVerified(
          isar: ref.read(mainDBProvider).isar,
        );

        ref.read(pWallets).addWallet(wallet);

        if (mounted) {
          if (isDesktop) {
            Navigator.of(context).popUntil(
              ModalRoute.withName(
                DesktopHomeView.routeName,
              ),
            );
          } else {
            unawaited(
              Navigator.of(context).pushNamedAndRemoveUntil(
                HomeView.routeName,
                (route) => false,
              ),
            );
          }

          await showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: true,
            builder: (context) {
              return const RestoreSucceededDialog(); // Replace with bespoke dialog?
            },
          );
        }

        if (!Platform.isLinux && !isDesktop) {
          await WakelockPlus.disable();
        }
      }
    } catch (e) {
      if (!Platform.isLinux && !isDesktop) {
        await WakelockPlus.disable();
      }

      // check if state is still active and restore wasn't cancelled
      // before continuing
      if (mounted && isRestoring) {
        // pop waiting dialog
        Navigator.pop(context);

        // show restoring wallet failed dialog
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return RestoreFailedDialog(
              errorMessage: e.toString(),
              walletId: info.walletId,
              walletName: info.name,
            ); // Replace with bespoke dialog?
          },
        );
      }
    }

    if (!Platform.isLinux && !isDesktop) {
      await WakelockPlus.disable();
    }
  }
}

class MultisigCoordinatorData {
  const MultisigCoordinatorData({
    this.threshold = 2,
    this.participants = 3,
    this.coinType = 0, // Bitcoin mainnet by default, can be overridden.
    this.account = 0,
    this.scriptType = MultisigScriptType.nativeSegwit,
    this.cosignerXpubs = const [],
  });

  final int threshold;
  final int participants;
  final int coinType;
  final int account;
  final MultisigScriptType scriptType;
  final List<String> cosignerXpubs;

  MultisigCoordinatorData copyWith({
    int? threshold,
    int? participants,
    int? coinType,
    int? account,
    MultisigScriptType? scriptType,
    List<String>? cosignerXpubs,
  }) {
    return MultisigCoordinatorData(
      threshold: threshold ?? this.threshold,
      participants: participants ?? this.participants,
      coinType: coinType ?? this.coinType,
      account: account ?? this.account,
      scriptType: scriptType ?? this.scriptType,
      cosignerXpubs: cosignerXpubs ?? this.cosignerXpubs,
    );
  }

  Map<String, dynamic> toJson() => {
        'threshold': threshold,
        'participants': participants,
        'coinType': coinType,
        'accountIndex': account,
        'scriptType': scriptType.index,
        'cosignerXpubs': cosignerXpubs,
      };

  factory MultisigCoordinatorData.fromJson(Map<String, dynamic> json) {
    return MultisigCoordinatorData(
      threshold: json['threshold'] as int,
      participants: json['participants'] as int,
      coinType: json['coinType'] as int,
      account: json['accountIndex'] as int,
      scriptType: MultisigScriptType.values[json['scriptType'] as int],
      cosignerXpubs: (json['cosignerXpubs'] as List).cast<String>(),
    );
  }
}

enum MultisigScriptType {
  // legacy,
  // P2SH.
  // "the only script types covered by this BIP are Native Segwit (p2wsh) and
  // Nested Segwit (p2sh-p2wsh)." (BIP48).
  segwit, // P2SH-P2WSH.
  nativeSegwit, // P2WSH.
}

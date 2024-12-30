import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/background.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/icon_widgets/copy_icon.dart';
import '../../../widgets/icon_widgets/qrcode_icon.dart';

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
  String _myXpub = "";
  // bool _isNfcAvailable = false;
  // String _nfcStatus = 'Checking NFC availability...';

  @override
  void initState() {
    super.initState();

    // Initialize controllers.
    for (int i = 0; i < widget.participants - 1; i++) {
      xpubControllers.add(TextEditingController());
    }

    // Get and set my xpub.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final targetPath = _getTargetPathForScriptType(widget.scriptType);
      final xpubData = await (ref.read(pWallets).getWallet(widget.walletId)
              as ExtendedKeysInterface)
          .getXPubs(bip48: true, account: widget.account);
      print(xpubData);

      final matchingPub = xpubData.xpubs.firstWhere(
        (pub) => pub.path == targetPath,
        orElse: () => XPub(path: "", encoded: "xPub not found!"),
      );

      if (matchingPub.path.isNotEmpty && mounted) {
        setState(() => _myXpub = matchingPub.encoded);
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
                                          hintText: "xPub...",
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
                            onPressed: () {
                              // final privWallet = Bip48Wallet(
                              //   masterKey: masterKey,
                              //   coinType: 0,
                              //   account: 0,
                              //   scriptType: Bip48ScriptType.p2shMultisig,
                              //   threshold: 2,
                              //   totalKeys: 3,
                              // );
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

  String _getTargetPathForScriptType(MultisigScriptType scriptType) {
    const pathMap = {
      MultisigScriptType.segwit: "m/48'/0'/0'/1'",
      MultisigScriptType.nativeSegwit: "m/48'/0'/0'/2'",
    };
    return pathMap[scriptType] ?? '';
  }
}

class MultisigCoordinatorData {
  const MultisigCoordinatorData({
    this.threshold = 2,
    this.participants = 3,
    this.coinType = 0, // Bitcoin mainnet.
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

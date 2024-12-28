import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icondart';
import '../../../widgets/stack_dialog.dart';

final multisigSetupStateProvider =
    StateNotifierProvider<MultisigSetupState, MultisigSetupData>((ref) {
  return MultisigSetupState();
});

class MultisigSetupData {
  const MultisigSetupData({
    this.threshold = 2,
    this.totalCosigners = 3,
    this.coinType = 0, // Bitcoin mainnet.
    this.accountIndex = 0,
    this.scriptType = MultisigScriptType.nativeSegwit,
    this.cosignerXpubs = const [],
  });

  final int threshold;
  final int totalCosigners;
  final int coinType;
  final int accountIndex;
  final MultisigScriptType scriptType;
  final List<String> cosignerXpubs;

  MultisigSetupData copyWith({
    int? threshold,
    int? totalCosigners,
    int? coinType,
    int? accountIndex,
    MultisigScriptType? scriptType,
    List<String>? cosignerXpubs,
  }) {
    return MultisigSetupData(
      threshold: threshold ?? this.threshold,
      totalCosigners: totalCosigners ?? this.totalCosigners,
      coinType: coinType ?? this.coinType,
      accountIndex: accountIndex ?? this.accountIndex,
      scriptType: scriptType ?? this.scriptType,
      cosignerXpubs: cosignerXpubs ?? this.cosignerXpubs,
    );
  }

  Map<String, dynamic> toJson() => {
        'threshold': threshold,
        'totalCosigners': totalCosigners,
        'coinType': coinType,
        'accountIndex': accountIndex,
        'scriptType': scriptType.index,
        'cosignerXpubs': cosignerXpubs,
      };

  factory MultisigSetupData.fromJson(Map<String, dynamic> json) {
    return MultisigSetupData(
      threshold: json['threshold'] as int,
      totalCosigners: json['totalCosigners'] as int,
      coinType: json['coinType'] as int,
      accountIndex: json['accountIndex'] as int,
      scriptType: MultisigScriptType.values[json['scriptType'] as int],
      cosignerXpubs: (json['cosignerXpubs'] as List).cast<String>(),
    );
  }
}

enum MultisigScriptType {
  legacy, // P2SH.
  segwit, // P2SH-P2WSH.
  nativeSegwit, // P2WSH.
}

class MultisigSetupState extends StateNotifier<MultisigSetupData> {
  MultisigSetupState() : super(const MultisigSetupData());

  void updateThreshold(int threshold) {
    state = state.copyWith(threshold: threshold);
  }

  void updateTotalCosigners(int total) {
    state = state.copyWith(totalCosigners: total);
  }

  void updateScriptType(MultisigScriptType type) {
    state = state.copyWith(scriptType: type);
  }

  void addCosignerXpub(String xpub) {
    if (state.cosignerXpubs.length < state.totalCosigners) {
      state = state.copyWith(
        cosignerXpubs: [...state.cosignerXpubs, xpub],
      );
    }
  }
}

class MultisigSetupView extends ConsumerStatefulWidget {
  const MultisigSetupView({
    super.key,
  });

  static const String routeName = "/multisigSetup";

  @override
  ConsumerState<MultisigSetupView> createState() => _MultisigSetupViewState();
}

class _MultisigSetupViewState extends ConsumerState<MultisigSetupView> {
  bool _isNfcAvailable = false;
  String _nfcStatus = 'Checking NFC availability...';

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await NfcManager.instance.isAvailable();
      setState(() {
        _isNfcAvailable = availability;
        _nfcStatus = _isNfcAvailable
            ? 'NFC is available'
            : 'NFC is not available on this device';
      });
    } catch (e) {
      setState(() {
        _nfcStatus = 'Error checking NFC: $e';
        _isNfcAvailable = false;
      });
    }
  }

  Future<void> _startNfcSession() async {
    if (!_isNfcAvailable) return;

    setState(() => _nfcStatus = 'Ready to exchange information...');

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);

            if (ndef == null) {
              setState(() => _nfcStatus = 'Tag is not NDEF compatible');
              return;
            }

            final setupData = ref.watch(multisigSetupStateProvider);

            if (ndef.isWritable) {
              final message = NdefMessage([
                NdefRecord.createMime(
                  'application/x-multisig-setup',
                  Uint8List.fromList(
                      utf8.encode(jsonEncode(setupData.toJson()))),
                ),
              ]);

              try {
                await ndef.write(message);
                setState(
                    () => _nfcStatus = 'Configuration shared successfully');
              } catch (e) {
                setState(
                    () => _nfcStatus = 'Failed to share configuration: $e');
              }
            }

            await NfcManager.instance.stopSession();
          } catch (e) {
            setState(() => _nfcStatus = 'Error during NFC exchange: $e');
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() => _nfcStatus = 'Error: $e');
      await NfcManager.instance.stopSession();
    }
  }

  /// Displays a short explanation dialog about musig.
  Future<void> _showMultisigInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const StackOkDialog(
          title: "What is a multisignature account?",
          message:
              "Multisignature accounts, also called shared accounts, require "
              "multiple signatures to authorize a transaction.  This can "
              "increase security by preventing a single point of failure or "
              "allow multiple parties to jointly control funds."
              "For example, in a 2-of-3 multisig account, two of the three "
              "cosigners are required in order to sign a transaction and spend "
              "funds.",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop;
    final setupData = ref.watch(multisigSetupStateProvider);

    // Required signatures<= total cosigners.
    final clampedThreshold = (setupData.threshold > setupData.totalCosigners)
        ? setupData.totalCosigners
        : setupData.threshold;

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
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              "Multisignature account setup",
              style: STextStyles.navBarTitle(context),
            ),
            titleSpacing: 0,
            actions: [
              AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  size: 36,
                  icon: SvgPicture.asset(
                    Assets.svg.circleQuestion,
                    width: 20,
                    height: 20,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .topNavIconPrimary,
                  ),
                  onPressed: _showMultisigInfoDialog,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (builderContext, constraints) {
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
                          // We'll add a method to share the config w/ cosigners
                          // so there's not much need to remind them here.
                          // RoundedWhiteContainer(
                          //   child: Text(
                          //     "Make sure all cosigners use the same "
                          //     "configuration when creating the shared account.",
                          //     style: STextStyles.w500_12(context).copyWith(
                          //       color: Theme.of(context)
                          //           .extension<StackColors>()!
                          //           .textSubtitle1,
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(height: 16),

                          Text(
                            "Configuration",
                            style: STextStyles.itemSubtitle(context),
                          ),
                          const SizedBox(height: 16),

                          // Script Type Selection
                          RoundedContainer(
                            padding: const EdgeInsets.all(16),
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Script Type",
                                  style: STextStyles.titleBold12(context),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<MultisigScriptType>(
                                  value: setupData.scriptType,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: MultisigScriptType.values.map((type) {
                                    String label;
                                    switch (type) {
                                      case MultisigScriptType.legacy:
                                        label = "Legacy (P2SH)";
                                        break;
                                      case MultisigScriptType.segwit:
                                        label = "Nested SegWit (P2SH-P2WSH)";
                                        break;
                                      case MultisigScriptType.nativeSegwit:
                                        label = "Native SegWit (P2WSH)";
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      ref
                                          .read(
                                            multisigSetupStateProvider.notifier,
                                          )
                                          .updateScriptType(value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Multisig params setup

                          RoundedContainer(
                            padding: const EdgeInsets.all(16),
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .popupBG,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total cosigners: ${setupData.totalCosigners}",
                                  style: STextStyles.titleBold12(context),
                                ),
                                Slider(
                                  value: setupData.totalCosigners.toDouble(),
                                  min: 2,
                                  max: 7, // There's not actually a max.
                                  divisions: 7, // Match the above or look off.
                                  label:
                                      "${setupData.totalCosigners} cosigners",
                                  onChanged: (value) {
                                    ref
                                        .read(
                                            multisigSetupStateProvider.notifier)
                                        .updateTotalCosigners(value.toInt());
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Required Signatures: $clampedThreshold of ${setupData.totalCosigners}",
                                  style: STextStyles.titleBold12(context),
                                ),
                                Slider(
                                  value: clampedThreshold.toDouble(),
                                  min: 1,
                                  max: setupData.totalCosigners.toDouble(),
                                  divisions: setupData.totalCosigners - 1,
                                  label:
                                      "$clampedThreshold of ${setupData.totalCosigners}",
                                  onChanged: (value) {
                                    ref
                                        .read(
                                            multisigSetupStateProvider.notifier)
                                        .updateThreshold(value.toInt());
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // We'll make a FROST-like progress indicator in a
                          // dialog to show the progress of the setup process.
                          // This simpler example will be removed soon.
                          // Text(
                          //   "Exchange Method",
                          //   style: STextStyles.itemSubtitle(context),
                          // ),
                          // const SizedBox(height: 16),
                          //
                          // // NFC exchange.
                          // RoundedContainer(
                          //   padding: const EdgeInsets.all(16),
                          //   color: Theme.of(context)
                          //       .extension<StackColors>()!
                          //       .popupBG,
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Row(
                          //         children: [
                          //           Icon(
                          //             _isNfcAvailable
                          //                 ? Icons.nfc
                          //                 : Icons.nfc_outlined,
                          //             color: _isNfcAvailable
                          //                 ? Theme.of(context)
                          //                     .extension<StackColors>()!
                          //                     .accentColorGreen
                          //                 : Theme.of(context)
                          //                     .extension<StackColors>()!
                          //                     .textDark3,
                          //           ),
                          //           const SizedBox(width: 8),
                          //           Text(
                          //             "NFC Exchange",
                          //             style: STextStyles.titleBold12(context),
                          //           ),
                          //         ],
                          //       ),
                          //       const SizedBox(height: 16),
                          //       Text(
                          //         _nfcStatus,
                          //         style: STextStyles.baseXS(context),
                          //       ),
                          //       if (_isNfcAvailable) ...[
                          //         const SizedBox(height: 16),
                          //         SizedBox(
                          //           width: double.infinity,
                          //           child: !isDesktop
                          //               ? TextButton(
                          //                   onPressed: _startNfcSession,
                          //                   style: Theme.of(context)
                          //                       .extension<StackColors>()!
                          //                       .getPrimaryEnabledButtonStyle(
                          //                           context),
                          //                   child: Text(
                          //                     "Tap to Exchange Information",
                          //                     style:
                          //                         STextStyles.button(context),
                          //                   ),
                          //                 )
                          //               : PrimaryButton(
                          //                   label:
                          //                       "Tap to Exchange Information",
                          //                   onPressed: _startNfcSession,
                          //                   enabled: true,
                          //                 ),
                          //         ),
                          //       ],
                          //     ],
                          //   ),
                          // ),

                          const Spacer(),
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
}

import 'dart:ffi';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

// was FinishResharingView
class FrostReshareStep4 extends ConsumerStatefulWidget {
  const FrostReshareStep4({super.key});

  static const String routeName = "/frostReshareStep4";
  static const String title = "Resharer completes";

  @override
  ConsumerState<FrostReshareStep4> createState() => _FrostReshareStep4State();
}

class _FrostReshareStep4State extends ConsumerState<FrostReshareStep4> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<int> resharerIndexes;
  late final String myName;
  late final int? myResharerIndexIndex;
  late final String? myResharerComplete;
  late final bool amOutgoingParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      if (amOutgoingParticipant) {
        ref.read(pFrostResharingData).reset();
        Navigator.of(context).popUntil(
          ModalRoute.withName(
            Util.isDesktop ? DesktopWalletView.routeName : WalletView.routeName,
          ),
        );
      } else {
        // collect resharer completes strings and insert my own at the correct index
        final resharerCompletes = controllers.map((e) => e.text).toList();
        if (myResharerIndexIndex != null && myResharerComplete != null) {
          resharerCompletes.insert(myResharerIndexIndex!, myResharerComplete!);
        }

        final data = Frost.finishReshared(
          prior: ref.read(pFrostResharingData).startResharedData!.prior.ref,
          resharerCompletes: resharerCompletes,
        );

        ref.read(pFrostResharingData).newWalletData = data;

        ref.read(pFrostCreateCurrentStep.state).state = 5;
        await Navigator.of(context).pushNamed(
          ref
              .read(pFrostScaffoldArgs)!
              .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
              .routeName,
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Fatal,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Error",
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  @override
  void initState() {
    final amNewParticipant =
        ref.read(pFrostResharingData).startResharerData == null &&
            ref.read(pFrostResharingData).incompleteWallet != null &&
            ref.read(pFrostResharingData).incompleteWallet?.walletId ==
                ref.read(pFrostScaffoldArgs)!.walletId!;

    myName = ref.read(pFrostResharingData).myName!;

    resharerIndexes = ref.read(pFrostResharingData).configData!.resharers;

    if (amNewParticipant) {
      myResharerComplete = null;
      myResharerIndexIndex = null;
      amOutgoingParticipant = false;
    } else {
      myResharerComplete = ref.read(pFrostResharingData).resharerComplete!;

      final frostInfo = ref
          .read(mainDBProvider)
          .isar
          .frostWalletInfo
          .getByWalletIdSync(ref.read(pFrostScaffoldArgs)!.walletId!)!;
      final myOldIndex =
          frostInfo.participants.indexOf(ref.read(pFrostResharingData).myName!);

      myResharerIndexIndex = resharerIndexes.indexOf(myOldIndex);
      if (myResharerIndexIndex! >= 0) {
        // remove my name for now as we don't need a text field for it
        resharerIndexes.removeAt(myResharerIndexIndex!);
      }

      amOutgoingParticipant = !ref
          .read(pFrostResharingData)
          .configData!
          .newParticipants
          .contains(ref.read(pFrostResharingData).myName!);
    }

    for (int i = 0; i < resharerIndexes.length; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
      fieldIsEmptyFlags.add(true);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].dispose();
    }
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (myResharerComplete != null)
            SizedBox(
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: myResharerComplete!,
                    size: 220,
                    backgroundColor:
                        Theme.of(context).extension<StackColors>()!.background,
                    foregroundColor: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                  ),
                ],
              ),
            ),
          if (myResharerComplete != null)
            const SizedBox(
              height: 16,
            ),
          if (myResharerComplete != null)
            DetailItem(
              title: "My resharer complete",
              detail: myResharerComplete!,
              button: Util.isDesktop
                  ? IconCopyButton(
                      data: myResharerComplete!,
                    )
                  : SimpleCopyButton(
                      data: myResharerComplete!,
                    ),
            ),
          if (!amOutgoingParticipant)
            const SizedBox(
              height: 16,
            ),
          if (!amOutgoingParticipant)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < resharerIndexes.length; i++)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                          child: TextField(
                            key: Key("frostEncryptionKeyTextFieldKey_$i"),
                            controller: controllers[i],
                            focusNode: focusNodes[i],
                            readOnly: false,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: STextStyles.field(context),
                            onChanged: (_) {
                              setState(() {
                                fieldIsEmptyFlags[i] =
                                    controllers[i].text.isEmpty;
                              });
                            },
                            decoration: standardInputDecoration(
                              "Enter index "
                              "${resharerIndexes[i]}"
                              "'s resharer complete",
                              focusNodes[i],
                              context,
                            ).copyWith(
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                top: 6,
                                bottom: 8,
                                right: 5,
                              ),
                              suffixIcon: Padding(
                                padding: fieldIsEmptyFlags[i]
                                    ? const EdgeInsets.only(right: 8)
                                    : const EdgeInsets.only(right: 0),
                                child: UnconstrainedBox(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      !fieldIsEmptyFlags[i]
                                          ? TextFieldIconButton(
                                              semanticsLabel:
                                                  "Clear Button. Clears The Encryption Key Field Input.",
                                              key: Key(
                                                  "frostEncryptionKeyClearButtonKey_$i"),
                                              onTap: () {
                                                controllers[i].text = "";

                                                setState(() {
                                                  fieldIsEmptyFlags[i] = true;
                                                });
                                              },
                                              child: const XIcon(),
                                            )
                                          : TextFieldIconButton(
                                              semanticsLabel:
                                                  "Paste Button. Pastes From Clipboard To Encryption Key Field Input.",
                                              key: Key(
                                                  "frostEncryptionKeyPasteButtonKey_$i"),
                                              onTap: () async {
                                                final ClipboardData? data =
                                                    await Clipboard.getData(
                                                        Clipboard.kTextPlain);
                                                if (data?.text != null &&
                                                    data!.text!.isNotEmpty) {
                                                  controllers[i].text =
                                                      data.text!.trim();
                                                }

                                                setState(() {
                                                  fieldIsEmptyFlags[i] =
                                                      controllers[i]
                                                          .text
                                                          .isEmpty;
                                                });
                                              },
                                              child: fieldIsEmptyFlags[i]
                                                  ? const ClipboardIcon()
                                                  : const XIcon(),
                                            ),
                                      if (fieldIsEmptyFlags[i])
                                        TextFieldIconButton(
                                          semanticsLabel: "Scan QR Button. "
                                              "Opens Camera For Scanning QR Code.",
                                          key: Key("frostScanQrButtonKey_$i"),
                                          onTap: () async {
                                            try {
                                              if (FocusScope.of(context)
                                                  .hasFocus) {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                await Future<void>.delayed(
                                                    const Duration(
                                                        milliseconds: 75));
                                              }

                                              final qrResult =
                                                  await BarcodeScanner.scan();

                                              controllers[i].text =
                                                  qrResult.rawContent;

                                              setState(() {
                                                fieldIsEmptyFlags[i] =
                                                    controllers[i].text.isEmpty;
                                              });
                                            } on PlatformException catch (e, s) {
                                              Logging.instance.log(
                                                "Failed to get camera permissions "
                                                "while trying to scan qr code: $e\n$s",
                                                level: LogLevel.Warning,
                                              );
                                            }
                                          },
                                          child: const QrCodeIcon(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: amOutgoingParticipant ? "Exit" : "Complete",
            enabled: amOutgoingParticipant ||
                !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}

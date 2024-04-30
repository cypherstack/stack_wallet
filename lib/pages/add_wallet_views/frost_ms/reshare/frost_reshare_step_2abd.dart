import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
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

class FrostReshareStep2abd extends ConsumerStatefulWidget {
  const FrostReshareStep2abd({super.key});

  static const String routeName = "/FrostReshareStep2abd";
  static const String title = "Resharers";

  @override
  ConsumerState<FrostReshareStep2abd> createState() =>
      _FrostReshareStep2abdState();
}

class _FrostReshareStep2abdState extends ConsumerState<FrostReshareStep2abd> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<int> resharerIndexes;
  late final int myResharerIndexIndex;
  late final String myResharerStart;
  late final bool amOutgoingParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _buttonLock = false;

  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      if (!amOutgoingParticipant) {
        // collect resharer strings
        final resharerStarts = controllers.map((e) => e.text).toList();
        if (myResharerIndexIndex >= 0) {
          // only insert my own at the correct index if I am a resharer
          resharerStarts.insert(myResharerIndexIndex, myResharerStart);
        }

        final result = Frost.beginReshared(
          myName: ref.read(pFrostResharingData).myName!,
          resharerConfig: ref.read(pFrostResharingData).resharerConfig!,
          resharerStarts: resharerStarts,
        );

        ref.read(pFrostResharingData).startResharedData = result;
      }

      ref.read(pFrostCreateCurrentStep.state).state = 3;
      await Navigator.of(context).pushNamed(
        ref
            .read(pFrostScaffoldArgs)!
            .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
            .routeName,
      );
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
    // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
    final frostInfo = ref
        .read(mainDBProvider)
        .isar
        .frostWalletInfo
        .getByWalletIdSync(ref.read(pFrostScaffoldArgs)!.walletId!)!;
    final myOldIndex =
        frostInfo.participants.indexOf(ref.read(pFrostResharingData).myName!);

    myResharerStart =
        ref.read(pFrostResharingData).startResharerData!.resharerStart;

    resharerIndexes = ref.read(pFrostResharingData).configData!.resharers;
    myResharerIndexIndex = resharerIndexes.indexOf(myOldIndex);
    if (myResharerIndexIndex >= 0) {
      // remove my name for now as we don't need a text field for it
      resharerIndexes.removeAt(myResharerIndexIndex);
    }

    amOutgoingParticipant = !ref
        .read(pFrostResharingData)
        .configData!
        .newParticipants
        .contains(ref.read(pFrostResharingData).myName!);

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
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: myResharerStart,
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
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "My resharer",
            detail: myResharerStart,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myResharerStart,
                  )
                : SimpleCopyButton(
                    data: myResharerStart,
                  ),
          ),
          const SizedBox(
            height: 12,
          ),
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
                          key: Key("frostResharerTextFieldKey_$i"),
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
                            "'s resharer",
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
                                                "Clear Button. Clears The Resharer Field Input.",
                                            key: Key(
                                                "frostResharerClearButtonKey_$i"),
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
                                                "Paste Button. Pastes From Clipboard To Resharer Field Input.",
                                            key: Key(
                                                "frostResharerPasteButtonKey_$i"),
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
                                                    controllers[i].text.isEmpty;
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
                                        key: Key(
                                            "frostCommitmentsScanQrButtonKey_$i"),
                                        onTap: () async {
                                          try {
                                            if (FocusScope.of(context)
                                                .hasFocus) {
                                              FocusScope.of(context).unfocus();
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
            height: 12,
          ),
          PrimaryButton(
            label: "Continue",
            enabled: amOutgoingParticipant ||
                !fieldIsEmptyFlags.reduce((v, e) => v |= e),
            onPressed: _onPressed,
          ),
        ],
      ),
    );
  }
}

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/frost_qr_dialog_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostSendStep2 extends ConsumerStatefulWidget {
  const FrostSendStep2({super.key});

  static const String routeName = "/FrostSendStep2";
  static const String title = "Preprocesses";

  @override
  ConsumerState<FrostSendStep2> createState() => _FrostSendStep2State();
}

class _FrostSendStep2State extends ConsumerState<FrostSendStep2> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final String myName;
  late final List<String> participantsWithoutMe;
  late final String myPreprocess;
  late final int myIndex;
  late final int threshold;

  final List<bool> fieldIsEmptyFlags = [];

  bool hasEnoughPreprocesses() {
    // own preprocess is not included in controllers and must be set here
    int count = 1;

    for (final controller in controllers) {
      if (controller.text.isNotEmpty) {
        count++;
      }
    }

    return count >= threshold;
  }

  @override
  void initState() {
    final wallet = ref.read(pWallets).getWallet(
          ref.read(pFrostScaffoldArgs)!.walletId!,
        ) as BitcoinFrostWallet;
    final frostInfo = wallet.frostInfo;

    myName = frostInfo.myName;
    threshold = frostInfo.threshold;
    participantsWithoutMe =
        List.from(frostInfo.participants); // Copy so it isn't fixed-length.
    myIndex = participantsWithoutMe.indexOf(frostInfo.myName);
    myPreprocess = ref.read(pFrostAttemptSignData.state).state!.preprocess;

    participantsWithoutMe.removeAt(myIndex);

    for (int i = 0; i < participantsWithoutMe.length; i++) {
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1.",
                      style: STextStyles.w500_12(context),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        "Share your preprocess with other signing group members.",
                        style: STextStyles.w500_12(context),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1.",
                      style: STextStyles.w500_12(context),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Enter their preprocesses into the corresponding fields. ",
                              style: STextStyles.w600_12(context),
                            ),
                            TextSpan(
                              text: "You must have the threshold number of "
                                  "preprocesses (including yours) to send this transaction.",
                              style: STextStyles.w600_12(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .customTextButtonEnabledText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "My name",
            detail: myName,
          ),
          const SizedBox(
            height: 12,
          ),
          DetailItem(
            title: "My preprocess",
            detail: myPreprocess,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myPreprocess,
                  )
                : SimpleCopyButton(
                    data: myPreprocess,
                  ),
          ),
          const SizedBox(height: 12),
          FrostQrDialogPopupButton(
            data: myPreprocess,
          ),
          const SizedBox(
            height: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < participantsWithoutMe.length; i++)
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
                          key: Key("frostPreprocessesTextFieldKey_$i"),
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
                            "Enter ${participantsWithoutMe[i]}'s preprocess",
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
                                                "Clear Button. Clears The Preprocess Field Input.",
                                            key: Key(
                                              "frostPreprocessesClearButtonKey_$i",
                                            ),
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
                                                "Paste Button. Pastes From Clipboard To Preprocess Field Input.",
                                            key: Key(
                                              "frostPreprocessesPasteButtonKey_$i",
                                            ),
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
                                        semanticsLabel:
                                            "Scan QR Button. Opens Camera For Scanning QR Code.",
                                        key: Key(
                                          "frostPreprocessesScanQrButtonKey_$i",
                                        ),
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
                                              "Failed to get camera permissions while trying to scan qr code: $e\n$s",
                                              level: LogLevel.Warning,
                                            );
                                          }
                                        },
                                        child: const QrCodeIcon(),
                                      )
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
            label: "Continue signing",
            enabled: hasEnoughPreprocesses(),
            onPressed: () async {
              // collect Preprocess strings (not including my own)
              final preprocesses = controllers.map((e) => e.text).toList();

              // collect participants who are involved in this transaction
              final List<String> requiredParticipantsUnordered = [];
              for (int i = 0; i < participantsWithoutMe.length; i++) {
                if (preprocesses[i].isNotEmpty) {
                  requiredParticipantsUnordered.add(participantsWithoutMe[i]);
                }
              }
              ref.read(pFrostSelectParticipantsUnordered.notifier).state =
                  requiredParticipantsUnordered;

              // insert an empty string at my index
              preprocesses.insert(myIndex, "");

              try {
                ref.read(pFrostContinueSignData.notifier).state =
                    Frost.continueSigning(
                  machinePtr:
                      ref.read(pFrostAttemptSignData.state).state!.machinePtr,
                  preprocesses: preprocesses,
                );

                ref.read(pFrostCreateCurrentStep.state).state = 3;
                await Navigator.of(context).pushNamed(
                  ref
                      .read(pFrostScaffoldArgs)!
                      .stepRoutes[ref.read(pFrostCreateCurrentStep) - 1]
                      .routeName,
                );

                // await Navigator.of(context).pushNamed(
                //   FrostContinueSignView.routeName,
                //   arguments: widget.walletId,
                // );
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "Failed to continue signing",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

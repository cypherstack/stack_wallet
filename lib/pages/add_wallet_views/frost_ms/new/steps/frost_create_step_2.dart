import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_create_step_3.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost/frost_step_qr_dialog.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostCreateStep2 extends ConsumerStatefulWidget {
  const FrostCreateStep2({super.key});

  static const String routeName = "/frostCreateStep2";
  static const String title = "Shares";

  @override
  ConsumerState<FrostCreateStep2> createState() => _FrostCreateStep2State();
}

class _FrostCreateStep2State extends ConsumerState<FrostCreateStep2> {
  static const info = [
    "Send your share to other group members.",
    "Enter their shares into the corresponding fields.",
  ];

  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<String> participants;
  late final String myShare;
  late final int myIndex;

  final List<bool> fieldIsEmptyFlags = [];

  Future<void> _showQrCodeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => FrostStepQrDialog(
        myName: ref.read(pFrostMyName)!,
        title: "Step 2 of 4 - ${FrostCreateStep2.title}",
        data: myShare,
      ),
    );
  }

  @override
  void initState() {
    participants = Frost.getParticipants(
      multisigConfig: ref.read(pFrostMultisigConfig.state).state!,
    );
    myIndex = participants.indexOf(ref.read(pFrostMyName.state).state!);
    myShare = ref.read(pFrostSecretSharesData.state).state!.share;

    // temporarily remove my name. Added back later
    participants.removeAt(myIndex);

    for (int i = 0; i < participants.length; i++) {
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
          const FrostStepUserSteps(
            userSteps: info,
          ),
          const SizedBox(height: 12),
          DetailItem(
            title: "My name",
            detail: ref.watch(pFrostMyName.state).state!,
          ),
          const SizedBox(height: 12),
          DetailItem(
            title: "My share",
            detail: myShare,
            button: Util.isDesktop
                ? IconCopyButton(
                    data: myShare,
                  )
                : SimpleCopyButton(
                    data: myShare,
                  ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: "View QR code",
            icon: SvgPicture.asset(
              Assets.svg.qrcode,
              colorFilter: ColorFilter.mode(
                Theme.of(context).extension<StackColors>()!.buttonTextSecondary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: _showQrCodeDialog,
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < participants.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 12,
                ),
                Text(
                  participants[i],
                  style: STextStyles.w500_14(context),
                ),
                const SizedBox(
                  height: 4,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    key: Key("frSharesTextFieldKey_$i"),
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    readOnly: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: STextStyles.field(context),
                    decoration: standardInputDecoration(
                      "Enter ${participants[i]}'s share",
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              !fieldIsEmptyFlags[i]
                                  ? TextFieldIconButton(
                                      semanticsLabel:
                                          "Clear Button. Clears The Share Field Input.",
                                      key: Key("frSharesClearButtonKey_$i"),
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
                                          "Paste Button. Pastes From Clipboard To Share Field Input.",
                                      key: Key("frSharesPasteButtonKey_$i"),
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
                                  key: Key("frSharesScanQrButtonKey_$i"),
                                  onTap: () async {
                                    try {
                                      if (FocusScope.of(context).hasFocus) {
                                        FocusScope.of(context).unfocus();
                                        await Future<void>.delayed(
                                            const Duration(milliseconds: 75));
                                      }

                                      final qrResult =
                                          await BarcodeScanner.scan();

                                      controllers[i].text = qrResult.rawContent;

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
              ],
            ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(height: 12),
          PrimaryButton(
            label: "Generate",
            onPressed: () async {
              // check for empty commitments
              if (controllers
                  .map((e) => e.text.isEmpty)
                  .reduce((value, element) => value |= element)) {
                return await showDialog<void>(
                  context: context,
                  builder: (_) => StackOkDialog(
                    title: "Missing shares",
                    desktopPopRootNavigator: Util.isDesktop,
                  ),
                );
              }

              // collect commitment strings and insert my own at the correct index
              final shares = controllers.map((e) => e.text).toList();
              shares.insert(myIndex, myShare);

              try {
                ref.read(pFrostCompletedKeyGenData.notifier).state =
                    Frost.completeKeyGeneration(
                  multisigConfigWithNamePtr: ref
                      .read(pFrostStartKeyGenData.state)
                      .state!
                      .multisigConfigWithNamePtr,
                  secretSharesResPtr: ref
                      .read(pFrostSecretSharesData.state)
                      .state!
                      .secretSharesResPtr,
                  shares: shares,
                );

                ref.read(pFrostCreateCurrentStep.state).state = 3;
                await Navigator.of(context).pushNamed(
                  FrostCreateStep3.routeName,
                );
              } catch (e, s) {
                Logging.instance.log(
                  "$e\n$s",
                  level: LogLevel.Fatal,
                );

                if (context.mounted) {
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "Failed to complete key generation",
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

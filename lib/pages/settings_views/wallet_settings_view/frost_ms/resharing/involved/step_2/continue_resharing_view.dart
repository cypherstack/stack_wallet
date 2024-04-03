import 'dart:ffi';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/frost_ms/resharing/finish_resharing_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/dialogs/frost_interruption_dialog.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class ContinueResharingView extends ConsumerStatefulWidget {
  const ContinueResharingView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/continueResharingView";

  final String walletId;

  @override
  ConsumerState<ContinueResharingView> createState() =>
      _ContinueResharingViewState();
}

class _ContinueResharingViewState extends ConsumerState<ContinueResharingView> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final List<String> newParticipants;
  late final int myIndex;
  late final String? myEncryptionKey;
  late final bool amOutgoingParticipant;

  final List<bool> fieldIsEmptyFlags = [];

  bool _buttonLock = false;
  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      // collect encryptionKeys strings and insert my own at the correct index
      final encryptionKeys = controllers.map((e) => e.text).toList();
      if (!amOutgoingParticipant) {
        encryptionKeys.insert(myIndex, myEncryptionKey!);
      }

      final result = Frost.finishResharer(
        machine: ref.read(pFrostResharingData).startResharerData!.machine.ref,
        encryptionKeysOfResharedTo: encryptionKeys,
      );

      ref.read(pFrostResharingData).resharerComplete = result;

      await Navigator.of(context).pushNamed(
        FinishResharingView.routeName,
        arguments: widget.walletId,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Fatal,
      );

      await showDialog<void>(
        context: context,
        builder: (_) => StackOkDialog(
          title: "Error",
          message: e.toString(),
          desktopPopRootNavigator: Util.isDesktop,
        ),
      );
    } finally {
      _buttonLock = false;
    }
  }

  @override
  void initState() {
    myEncryptionKey =
        ref.read(pFrostResharingData).startResharedData?.resharedStart;

    newParticipants = ref.read(pFrostResharingData).configData!.newParticipants;
    myIndex = newParticipants.indexOf(ref.read(pFrostResharingData).myName!);

    if (myIndex >= 0) {
      // remove my name for now as we don't need a text field for it
      newParticipants.removeAt(myIndex);
    }

    if (myEncryptionKey == null && myIndex == -1) {
      amOutgoingParticipant = true;
    } else if (myEncryptionKey != null && myIndex >= 0) {
      amOutgoingParticipant = false;
    } else {
      throw Exception("Invalid resharing state");
    }

    for (int i = 0; i < newParticipants.length; i++) {
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
    return WillPopScope(
      onWillPop: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostInterruptionDialog(
            type: FrostInterruptionDialogType.resharing,
            popUntilOnYesRouteName: Util.isDesktop
                ? DesktopWalletView.routeName
                : WalletView.routeName,
          ),
        );
        return false;
      },
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => DesktopScaffold(
          background: Theme.of(context).extension<StackColors>()!.background,
          appBar: DesktopAppBar(
            isCompactHeight: false,
            leading: AppBarBackButton(
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => const FrostInterruptionDialog(
                    type: FrostInterruptionDialogType.resharing,
                    popUntilOnYesRouteName: DesktopWalletView.routeName,
                  ),
                );
              },
            ),
          ),
          body: SizedBox(
            width: 480,
            child: child,
          ),
        ),
        child: ConditionalParent(
          condition: !Util.isDesktop,
          builder: (child) => Background(
            child: Scaffold(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              appBar: AppBar(
                leading: AppBarBackButton(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => const FrostInterruptionDialog(
                        type: FrostInterruptionDialogType.resharing,
                        popUntilOnYesRouteName: WalletView.routeName,
                      ),
                    );
                  },
                ),
                title: Text(
                  "Encryption keys",
                  style: STextStyles.navBarTitle(context),
                ),
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          child: Column(
            children: [
              if (!amOutgoingParticipant)
                SizedBox(
                  height: 220,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QrImageView(
                        data: myEncryptionKey!,
                        size: 220,
                        backgroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        foregroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                    ],
                  ),
                ),
              if (!amOutgoingParticipant) const _Div(),
              if (!amOutgoingParticipant)
                DetailItem(
                  title: "My encryption key",
                  detail: myEncryptionKey!,
                  button: Util.isDesktop
                      ? IconCopyButton(
                          data: myEncryptionKey!,
                        )
                      : SimpleCopyButton(
                          data: myEncryptionKey!,
                        ),
                ),
              if (!amOutgoingParticipant) const _Div(),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < newParticipants.length; i++)
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
                                "Enter "
                                "${newParticipants[i]}"
                                "'s encryption key",
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
                                            key: Key(
                                                "frostCommitmentsScanQrButtonKey_$i"),
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
                                                      controllers[i]
                                                          .text
                                                          .isEmpty;
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
              const _Div(),
              PrimaryButton(
                label: "Continue",
                enabled: !fieldIsEmptyFlags.reduce((v, e) => v |= e),
                onPressed: _onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 12,
    );
  }
}

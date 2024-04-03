import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/send_view/frost_ms/frost_complete_sign_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_frost_wallet.dart';
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

class FrostContinueSignView extends ConsumerStatefulWidget {
  const FrostContinueSignView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/frostContinueSignView";

  final String walletId;

  @override
  ConsumerState<FrostContinueSignView> createState() =>
      _FrostContinueSignViewState();
}

class _FrostContinueSignViewState extends ConsumerState<FrostContinueSignView> {
  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  late final String myName;
  late final List<String> participantsWithoutMe;
  late final List<String> participantsAll;
  late final String myShare;
  late final int myIndex;

  final List<bool> fieldIsEmptyFlags = [];

  @override
  void initState() {
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as BitcoinFrostWallet;

    final frostInfo = wallet.frostInfo;

    myName = frostInfo.myName;
    participantsAll = frostInfo.participants;
    myIndex = frostInfo.participants.indexOf(frostInfo.myName);
    myShare = ref.read(pFrostContinueSignData.state).state!.share;

    participantsWithoutMe = frostInfo.participants
        .toSet()
        .intersection(
            ref.read(pFrostSelectParticipantsUnordered.state).state!.toSet())
        .toList();

    participantsWithoutMe.remove(myName);

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
    return WillPopScope(
      onWillPop: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => FrostInterruptionDialog(
            type: FrostInterruptionDialogType.transactionCreation,
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
                    type: FrostInterruptionDialogType.transactionCreation,
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
                        type: FrostInterruptionDialogType.transactionCreation,
                        popUntilOnYesRouteName: WalletView.routeName,
                      ),
                    );
                  },
                ),
                title: Text(
                  "Shares",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: myShare,
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
              const _Div(),
              DetailItem(
                title: "My name",
                detail: myName,
              ),
              const _Div(),
              DetailItem(
                title: "My shares",
                detail: myShare,
                button: Util.isDesktop
                    ? IconCopyButton(
                        data: myShare,
                      )
                    : SimpleCopyButton(
                        data: myShare,
                      ),
              ),
              const _Div(),
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
                              key: Key("frostSharesTextFieldKey_$i"),
                              controller: controllers[i],
                              focusNode: focusNodes[i],
                              readOnly: false,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: STextStyles.field(context),
                              decoration: standardInputDecoration(
                                "Enter ${participantsWithoutMe[i]}'s share",
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
                                                    "Clear Button. Clears "
                                                    "The Share Field Input.",
                                                key: Key(
                                                  "frostSharesClearButtonKey_$i",
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
                                                    "Paste Button. Pastes From "
                                                    "Clipboard To Share Field Input.",
                                                key: Key(
                                                    "frostSharesPasteButtonKey_$i"),
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
                                            semanticsLabel:
                                                "Scan QR Button. Opens Camera "
                                                "For Scanning QR Code.",
                                            key: Key(
                                              "frostSharesScanQrButtonKey_$i",
                                            ),
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
              const _Div(),
              PrimaryButton(
                label: "Complete signing",
                onPressed: () async {
                  // check for empty shares
                  if (controllers
                      .map((e) => e.text.isEmpty)
                      .reduce((value, element) => value |= element)) {
                    return await showDialog<void>(
                      context: context,
                      builder: (_) => StackOkDialog(
                        title: "Missing Shares",
                        desktopPopRootNavigator: Util.isDesktop,
                      ),
                    );
                  }

                  // collect Share strings
                  final sharesCollected =
                      controllers.map((e) => e.text).toList();

                  final List<String> shares = [];
                  for (final participant in participantsAll) {
                    if (participantsWithoutMe.contains(participant)) {
                      shares.add(sharesCollected[
                          participantsWithoutMe.indexOf(participant)]);
                    } else {
                      shares.add("");
                    }
                  }

                  try {
                    final rawTx = Frost.completeSigning(
                      machinePtr: ref
                          .read(pFrostContinueSignData.state)
                          .state!
                          .machinePtr,
                      shares: shares,
                    );

                    ref.read(pFrostTxData.state).state =
                        ref.read(pFrostTxData.state).state!.copyWith(
                              raw: rawTx,
                            );

                    await Navigator.of(context).pushNamed(
                      FrostCompleteSignView.routeName,
                      arguments: widget.walletId,
                    );
                  } catch (e, s) {
                    Logging.instance.log(
                      "$e\n$s",
                      level: LogLevel.Fatal,
                    );

                    return await showDialog<void>(
                      context: context,
                      builder: (_) => StackOkDialog(
                        title: "Failed to complete signing process",
                        desktopPopRootNavigator: Util.isDesktop,
                      ),
                    );
                  }
                },
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

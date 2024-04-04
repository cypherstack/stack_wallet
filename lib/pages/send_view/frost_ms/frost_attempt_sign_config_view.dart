import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/pages/send_view/frost_ms/frost_continue_sign_config_view.dart';
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
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/detail_item.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostAttemptSignConfigView extends ConsumerStatefulWidget {
  const FrostAttemptSignConfigView({
    super.key,
    required this.walletId,
  });

  static const String routeName = "/frostAttemptSignConfigView";

  final String walletId;

  @override
  ConsumerState<FrostAttemptSignConfigView> createState() =>
      _FrostAttemptSignConfigViewState();
}

class _FrostAttemptSignConfigViewState
    extends ConsumerState<FrostAttemptSignConfigView> {
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
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as BitcoinFrostWallet;
    final frostInfo = wallet.frostInfo;

    myName = frostInfo.myName;
    threshold = frostInfo.threshold;
    participantsWithoutMe = List.from(frostInfo.participants); // Copy so it isn't fixed-length.
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
    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopScaffold(
        background: Theme.of(context).extension<StackColors>()!.background,
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Preprocesses",
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
                    data: myPreprocess,
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
            const _Div(),
            DetailItem(
              title: "My name",
              detail: myName,
            ),
            const _Div(),
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
                                              "Scan QR Button. Opens Camera For Scanning QR Code.",
                                          key: Key(
                                            "frostPreprocessesScanQrButtonKey_$i",
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
            const _Div(),
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

                  await Navigator.of(context).pushNamed(
                    FrostContinueSignView.routeName,
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
                      title: "Failed to continue signing",
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }
              },
            ),
          ],
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

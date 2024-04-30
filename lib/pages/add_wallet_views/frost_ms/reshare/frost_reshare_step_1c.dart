import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/show_loading.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/incomplete_frost_wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostReshareStep1c extends ConsumerStatefulWidget {
  const FrostReshareStep1c({super.key});

  static const String routeName = "/frostReshareStep1c";
  static const String title = "Import reshare config";

  @override
  ConsumerState<FrostReshareStep1c> createState() => _FrostReshareStep1cState();
}

class _FrostReshareStep1cState extends ConsumerState<FrostReshareStep1c> {
  static const info = [
    "Scan the config QR code or paste the code provided by the group creator.",
    "Enter your name EXACTLY as the group creator entered it. When in doubt, "
        "double check with them. The names are case-sensitive.",
    "Wait for other participants to finish entering their information.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process could be canceled.",
    "Check the box and press “Join group”.",
  ];

  late final TextEditingController myNameFieldController, configFieldController;
  late final FocusNode myNameFocusNode, configFocusNode;

  bool _nameEmpty = true,
      _configEmpty = true,
      _userVerifyContinue = false,
      _buttonLock = false;

  Future<IncompleteFrostWallet> _createWallet() async {
    final data = ref.read(pFrostScaffoldArgs)!;

    final info = WalletInfo.createNew(
      name: data.info.walletName,
      coin: data.info.frostCurrency.coin,
    );

    final wallet = IncompleteFrostWallet();
    wallet.info = info;

    return wallet;
  }

  @override
  void initState() {
    myNameFieldController = TextEditingController();
    configFieldController = TextEditingController();
    myNameFocusNode = FocusNode();
    configFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    myNameFieldController.dispose();
    configFieldController.dispose();
    myNameFocusNode.dispose();
    configFocusNode.dispose();
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
          const SizedBox(
            height: 16,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              key: const Key("frMyNameTextFieldKey"),
              controller: myNameFieldController,
              onChanged: (_) {
                setState(() {
                  _nameEmpty = myNameFieldController.text.isEmpty;
                });
              },
              focusNode: myNameFocusNode,
              readOnly: false,
              autocorrect: false,
              enableSuggestions: false,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "My name",
                myNameFocusNode,
                context,
              ).copyWith(
                contentPadding: const EdgeInsets.only(
                  left: 16,
                  top: 6,
                  bottom: 8,
                  right: 5,
                ),
                suffixIcon: Padding(
                  padding: _nameEmpty
                      ? const EdgeInsets.only(right: 8)
                      : const EdgeInsets.only(right: 0),
                  child: UnconstrainedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        !_nameEmpty
                            ? TextFieldIconButton(
                                semanticsLabel:
                                    "Clear Button. Clears The Config Field.",
                                key: const Key("frMyNameClearButtonKey"),
                                onTap: () {
                                  myNameFieldController.text = "";

                                  setState(() {
                                    _nameEmpty = true;
                                  });
                                },
                                child: const XIcon(),
                              )
                            : TextFieldIconButton(
                                semanticsLabel:
                                    "Paste Button. Pastes From Clipboard To Name Field.",
                                key: const Key("frMyNamePasteButtonKey"),
                                onTap: () async {
                                  final ClipboardData? data =
                                      await Clipboard.getData(
                                          Clipboard.kTextPlain);
                                  if (data?.text != null &&
                                      data!.text!.isNotEmpty) {
                                    myNameFieldController.text =
                                        data.text!.trim();
                                  }

                                  setState(() {
                                    _nameEmpty =
                                        myNameFieldController.text.isEmpty;
                                  });
                                },
                                child: _nameEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              key: const Key("frConfigTextFieldKey"),
              controller: configFieldController,
              onChanged: (_) {
                setState(() {
                  _configEmpty = configFieldController.text.isEmpty;
                });
              },
              focusNode: configFocusNode,
              readOnly: false,
              autocorrect: false,
              enableSuggestions: false,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "Enter config",
                configFocusNode,
                context,
              ).copyWith(
                contentPadding: const EdgeInsets.only(
                  left: 16,
                  top: 6,
                  bottom: 8,
                  right: 5,
                ),
                suffixIcon: Padding(
                  padding: _configEmpty
                      ? const EdgeInsets.only(right: 8)
                      : const EdgeInsets.only(right: 0),
                  child: UnconstrainedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        !_configEmpty
                            ? TextFieldIconButton(
                                semanticsLabel:
                                    "Clear Button. Clears The Config Field.",
                                key: const Key("frConfigClearButtonKey"),
                                onTap: () {
                                  configFieldController.text = "";

                                  setState(() {
                                    _configEmpty = true;
                                  });
                                },
                                child: const XIcon(),
                              )
                            : TextFieldIconButton(
                                semanticsLabel:
                                    "Paste Button. Pastes From Clipboard To Config Field Input.",
                                key: const Key("frConfigPasteButtonKey"),
                                onTap: () async {
                                  final ClipboardData? data =
                                      await Clipboard.getData(
                                          Clipboard.kTextPlain);
                                  if (data?.text != null &&
                                      data!.text!.isNotEmpty) {
                                    configFieldController.text =
                                        data.text!.trim();
                                  }

                                  setState(() {
                                    _configEmpty =
                                        configFieldController.text.isEmpty;
                                  });
                                },
                                child: _configEmpty
                                    ? const ClipboardIcon()
                                    : const XIcon(),
                              ),
                        if (_configEmpty)
                          TextFieldIconButton(
                            semanticsLabel:
                                "Scan QR Button. Opens Camera For Scanning QR Code.",
                            key: const Key("frConfigScanQrButtonKey"),
                            onTap: () async {
                              try {
                                if (FocusScope.of(context).hasFocus) {
                                  FocusScope.of(context).unfocus();
                                  await Future<void>.delayed(
                                      const Duration(milliseconds: 75));
                                }

                                final qrResult = await BarcodeScanner.scan();

                                configFieldController.text =
                                    qrResult.rawContent;

                                setState(() {
                                  _configEmpty =
                                      configFieldController.text.isEmpty;
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
          const SizedBox(
            height: 16,
          ),
          if (!Util.isDesktop) const Spacer(),
          const SizedBox(
            height: 16,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _userVerifyContinue = !_userVerifyContinue;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 26,
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: _userVerifyContinue,
                      onChanged: (value) => setState(
                        () => _userVerifyContinue = value == true,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      "I have verified that everyone has joined the group",
                      style: STextStyles.w500_14(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryButton(
            label: "Join group",
            enabled: _userVerifyContinue && !_nameEmpty && !_configEmpty,
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }
              if (_buttonLock) {
                return;
              }
              _buttonLock = true;

              try {
                ref.read(pFrostResharingData).reset();
                ref.read(pFrostResharingData).myName =
                    myNameFieldController.text;
                ref.read(pFrostResharingData).resharerConfig =
                    configFieldController.text;

                if (!ref
                    .read(pFrostResharingData)
                    .configData!
                    .newParticipants
                    .contains(ref.read(pFrostResharingData).myName!)) {
                  ref.read(pFrostResharingData).reset();
                  return await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: "My name not found in config participants",
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }

                Exception? ex;
                final wallet = await showLoading(
                  whileFuture: _createWallet(),
                  context: context,
                  message: "Setting up wallet",
                  isDesktop: Util.isDesktop,
                  onException: (e) => ex = e,
                );

                if (ex != null) {
                  throw ex!;
                }

                if (context.mounted) {
                  ref.read(pFrostResharingData).incompleteWallet = wallet!;
                  final data = ref.read(pFrostScaffoldArgs)!;
                  ref.read(pFrostScaffoldArgs.state).state = (
                    info: data.info,
                    walletId: wallet.walletId,
                    stepRoutes: data.stepRoutes,
                    onSuccess: data.onSuccess,
                  );
                  ref.read(pFrostCreateCurrentStep.state).state = 2;
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

                if (context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => StackOkDialog(
                      title: e.toString(),
                      desktopPopRootNavigator: Util.isDesktop,
                    ),
                  );
                }
              } finally {
                _buttonLock = false;
              }
            },
          )
        ],
      ),
    );
  }
}

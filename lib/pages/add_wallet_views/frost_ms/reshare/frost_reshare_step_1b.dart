import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frostdart/frostdart.dart';
import 'package:stackwallet/pages/add_wallet_views/frost_ms/new/steps/frost_route_generator.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/frost_wallet/frost_wallet_providers.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/services/frost.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/models/frost_wallet_info.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/frost_step_user_steps.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class FrostReshareStep1b extends ConsumerStatefulWidget {
  const FrostReshareStep1b({
    super.key,
  });

  static const String routeName = "/frostReshareStep1b";
  static const String title = "Import reshare config";

  @override
  ConsumerState<FrostReshareStep1b> createState() => _FrostReshareStep1bState();
}

class _FrostReshareStep1bState extends ConsumerState<FrostReshareStep1b> {
  static const info = [
    "Scan the config QR code or paste the code provided by the group member who"
        " is initiating resharing.",
    "Wait for other participants to finish importing the config.",
    "Verify that everyone has filled out their forms before continuing. If you "
        "try to continue before everyone is ready, the process will be canceled.",
    "Check the box and press “Start resharing”.",
  ];

  late final TextEditingController configFieldController;
  late final FocusNode configFocusNode;

  bool _configEmpty = true;

  bool _buttonLock = false;
  bool _userVerifyContinue = false;

  Future<void> _onPressed() async {
    if (_buttonLock) {
      return;
    }
    _buttonLock = true;

    try {
      final walletId = ref.read(pFrostScaffoldArgs)!.walletId!;
      // TODO: optimize this by creating watcher providers (similar to normal WalletInfo)
      final frostInfo = ref
          .read(mainDBProvider)
          .isar
          .frostWalletInfo
          .getByWalletIdSync(walletId)!;

      ref.read(pFrostResharingData).reset();
      ref.read(pFrostResharingData).myName = frostInfo.myName;
      ref.read(pFrostResharingData).resharerConfig = configFieldController.text;

      String? salt;
      try {
        salt = Format.uint8listToString(
          resharerSalt(
            resharerConfig: ref.read(pFrostResharingData).resharerConfig!,
          ),
        );
      } catch (_) {
        throw Exception("Bad resharer config");
      }

      if (frostInfo.knownSalts.contains(salt)) {
        throw Exception("Duplicate config salt");
      } else {
        final salts = frostInfo.knownSalts.toList();
        salts.add(salt);
        final mainDB = ref.read(mainDBProvider);
        await mainDB.isar.writeTxn(() async {
          final id = frostInfo.id;
          await mainDB.isar.frostWalletInfo.delete(id);
          await mainDB.isar.frostWalletInfo.put(
            frostInfo.copyWith(knownSalts: salts),
          );
        });
      }

      final serializedKeys = await ref.read(secureStoreProvider).read(
            key: "{$walletId}_serializedFROSTKeys",
          );
      if (mounted) {
        final result = Frost.beginResharer(
          serializedKeys: serializedKeys!,
          config: ref.read(pFrostResharingData).resharerConfig!,
        );

        ref.read(pFrostResharingData).startResharerData = result;

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

      if (mounted) {
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
  }

  @override
  void initState() {
    configFieldController = TextEditingController();
    configFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    configFieldController.dispose();
    configFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 16,
          ),
          const FrostStepUserSteps(
            userSteps: info,
          ),
          const SizedBox(height: 20),
          Text(
            "Enter config",
            style: STextStyles.w500_14(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle1,
            ),
          ),
          const SizedBox(
            height: 10,
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
                      "I have verified that everyone has imported the config",
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
            label: "Start resharing",
            enabled: !_configEmpty && _userVerifyContinue,
            onPressed: () async {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }

              await _onPressed();
            },
          ),
        ],
      ),
    );
  }
}

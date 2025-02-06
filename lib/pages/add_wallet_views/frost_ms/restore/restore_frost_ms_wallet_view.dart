import 'dart:async';
import 'dart:io';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frostdart/frostdart.dart' as frost;

import '../../../../notifications/show_flush_bar.dart';
import '../../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../providers/global/node_service_provider.dart';
import '../../../../providers/global/prefs_provider.dart';
import '../../../../providers/global/secure_store_provider.dart';
import '../../../../providers/global/wallets_provider.dart';
import '../../../../services/frost.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/constants.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/show_loading.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../utilities/util.dart';
import '../../../../wallets/crypto_currency/intermediate/frost_currency.dart';
import '../../../../wallets/isar/models/frost_wallet_info.dart';
import '../../../../wallets/isar/models/wallet_info.dart';
import '../../../../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../../../../wallets/wallet/wallet.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/conditional_parent.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/desktop/desktop_app_bar.dart';
import '../../../../widgets/desktop/desktop_scaffold.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/desktop/qr_code_scanner_dialog.dart';
import '../../../../widgets/frost_mascot.dart';
import '../../../../widgets/icon_widgets/clipboard_icon.dart';
import '../../../../widgets/icon_widgets/qrcode_icon.dart';
import '../../../../widgets/icon_widgets/x_icon.dart';
import '../../../../widgets/stack_dialog.dart';
import '../../../../widgets/stack_text_field.dart';
import '../../../../widgets/textfield_icon_button.dart';
import '../../../home_view/home_view.dart';

class RestoreFrostMsWalletView extends ConsumerStatefulWidget {
  const RestoreFrostMsWalletView({
    super.key,
    required this.walletName,
    required this.frostCurrency,
  });

  static const String routeName = "/restoreFrostMsWalletView";

  final String walletName;
  final FrostCurrency frostCurrency;

  @override
  ConsumerState<RestoreFrostMsWalletView> createState() =>
      _RestoreFrostMsWalletViewState();
}

class _RestoreFrostMsWalletViewState
    extends ConsumerState<RestoreFrostMsWalletView> {
  late final TextEditingController keysFieldController, configFieldController;
  late final FocusNode keysFocusNode, configFocusNode;

  bool _keysEmpty = true, _configEmpty = true;

  bool _restoreButtonLock = false;

  Future<Wallet> _createWalletAndRecover() async {
    final keys = keysFieldController.text;
    final config = configFieldController.text;

    final myNameIndex = frost.getParticipantIndexFromKeys(serializedKeys: keys);
    final participants = Frost.getParticipants(multisigConfig: config);
    final myName = participants[myNameIndex];

    final info = WalletInfo.createNew(
      coin: widget.frostCurrency,
      name: widget.walletName,
    );

    final wallet = await Wallet.create(
      walletInfo: info,
      mainDB: ref.read(mainDBProvider),
      secureStorageInterface: ref.read(secureStoreProvider),
      nodeService: ref.read(nodeServiceChangeNotifierProvider),
      prefs: ref.read(prefsChangeNotifierProvider),
    );

    final frostInfo = FrostWalletInfo(
      walletId: info.walletId,
      knownSalts: [],
      participants: participants,
      myName: myName,
      threshold: frost.multisigThreshold(
        multisigConfig: config,
      ),
    );

    await ref.read(mainDBProvider).isar.writeTxn(() async {
      await ref.read(mainDBProvider).isar.frostWalletInfo.put(frostInfo);
    });

    await (wallet as BitcoinFrostWallet).recover(
      serializedKeys: keys,
      multisigConfig: config,
      isRescan: false,
    );

    await info.setMnemonicVerified(
      isar: ref.read(mainDBProvider).isar,
    );

    return wallet;
  }

  Future<void> _restore() async {
    if (_restoreButtonLock) {
      return;
    }
    _restoreButtonLock = true;

    try {
      if (FocusScope.of(context).hasFocus) {
        FocusScope.of(context).unfocus();
      }

      Exception? ex;
      final wallet = await showLoading(
        whileFuture: _createWalletAndRecover(),
        context: context,
        message: "Restoring wallet...",
        rootNavigator: Util.isDesktop,
        onException: (e) {
          ex = e;
        },
      );

      if (ex != null) {
        throw ex!;
      }

      ref.read(pWallets).addWallet(wallet!);

      if (mounted) {
        if (Util.isDesktop) {
          Navigator.of(context).popUntil(
            ModalRoute.withName(
              DesktopHomeView.routeName,
            ),
          );
        } else {
          unawaited(
            Navigator.of(context).pushNamedAndRemoveUntil(
              HomeView.routeName,
              (route) => false,
            ),
          );
        }

        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.success,
            message: "Your wallet is set up.",
            iconAsset: Assets.svg.check,
            context: context,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "",
        error: e,
        stackTrace: s,
      );

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => StackOkDialog(
            title: "Failed to restore",
            message: e.toString(),
            desktopPopRootNavigator: Util.isDesktop,
          ),
        );
      }
    } finally {
      _restoreButtonLock = false;
    }
  }

  @override
  void initState() {
    keysFieldController = TextEditingController();
    configFieldController = TextEditingController();
    keysFocusNode = FocusNode();
    configFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    keysFieldController.dispose();
    configFieldController.dispose();
    keysFocusNode.dispose();
    configFocusNode.dispose();
    super.dispose();
  }

  Future<void> scanQr() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
          await Future<void>.delayed(
            const Duration(milliseconds: 75),
          );
        }

        final qrResult = await BarcodeScanner.scan();

        configFieldController.text = qrResult.rawContent;

        setState(() {
          _configEmpty = configFieldController.text.isEmpty;
        });
      } else {
        // Platform.isLinux, Platform.isWindows, or Platform.isMacOS.
        final qrResult = await showDialog<String>(
          context: context,
          builder: (context) => const QrCodeScannerDialog(),
        );

        if (qrResult == null) {
          Logging.instance.d(
            "Qr scanning cancelled",
          );
        } else {
          // TODO [prio=low]: Validate QR code data.
          configFieldController.text = qrResult;

          setState(() {
            _configEmpty = configFieldController.text.isEmpty;
          });
        }
      }
    } on PlatformException catch (e, s) {
      Logging.instance.w(
        "Failed to get camera permissions while trying to scan qr code: ",
        error: e,
        stackTrace: s,
      );
    }
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
          // TODO: [prio=high] get rid of placeholder text??
          trailing: FrostMascot(
            title: 'Lorem ipsum',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam est justo, ',
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Restore FROST multisig wallet",
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
                                      Clipboard.kTextPlain,
                                    );
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
                              onTap: scanQr,
                              child: const QrCodeIcon(),
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
                key: const Key("frMyNameTextFieldKey"),
                controller: keysFieldController,
                onChanged: (_) {
                  setState(() {
                    _keysEmpty = keysFieldController.text.isEmpty;
                  });
                },
                focusNode: keysFocusNode,
                readOnly: false,
                autocorrect: false,
                enableSuggestions: false,
                style: STextStyles.field(context),
                decoration: standardInputDecoration(
                  "Keys",
                  keysFocusNode,
                  context,
                ).copyWith(
                  contentPadding: const EdgeInsets.only(
                    left: 16,
                    top: 6,
                    bottom: 8,
                    right: 5,
                  ),
                  suffixIcon: Padding(
                    padding: _keysEmpty
                        ? const EdgeInsets.only(right: 8)
                        : const EdgeInsets.only(right: 0),
                    child: UnconstrainedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          !_keysEmpty
                              ? TextFieldIconButton(
                                  semanticsLabel:
                                      "Clear Button. Clears The Keys Field.",
                                  key: const Key("frMyNameClearButtonKey"),
                                  onTap: () {
                                    keysFieldController.text = "";

                                    setState(() {
                                      _keysEmpty = true;
                                    });
                                  },
                                  child: const XIcon(),
                                )
                              : TextFieldIconButton(
                                  semanticsLabel:
                                      "Paste Button. Pastes From Clipboard To Keys Field.",
                                  key: const Key("frKeysPasteButtonKey"),
                                  onTap: () async {
                                    final ClipboardData? data =
                                        await Clipboard.getData(
                                      Clipboard.kTextPlain,
                                    );
                                    if (data?.text != null &&
                                        data!.text!.isNotEmpty) {
                                      keysFieldController.text =
                                          data.text!.trim();
                                    }

                                    setState(() {
                                      _keysEmpty =
                                          keysFieldController.text.isEmpty;
                                    });
                                  },
                                  child: _keysEmpty
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
            if (!Util.isDesktop) const Spacer(),
            const SizedBox(
              height: 16,
            ),
            PrimaryButton(
              label: "Restore",
              enabled: !_keysEmpty && !_configEmpty,
              onPressed: _restore,
            ),
          ],
        ),
      ),
    );
  }
}

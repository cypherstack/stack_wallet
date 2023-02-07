import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/wordlists/english.dart' as bip39wordlist;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_libmonero/wownero/wownero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/confirm_recovery_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restore_failed_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restore_succeeded_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/providers/global/secure_store_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/custom_text_selection_controls.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/form_input_status_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
import 'package:stackwallet/widgets/table_view/table_view.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';
import 'package:wakelock/wakelock.dart';

class RestoreWalletView extends ConsumerStatefulWidget {
  const RestoreWalletView({
    Key? key,
    required this.walletName,
    required this.coin,
    required this.seedWordsLength,
    required this.restoreFromDate,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const routeName = "/restoreWallet";

  final String walletName;
  final Coin coin;
  final int seedWordsLength;
  final DateTime restoreFromDate;

  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<RestoreWalletView> createState() => _RestoreWalletViewState();
}

class _RestoreWalletViewState extends ConsumerState<RestoreWalletView> {
  final _formKey = GlobalKey<FormState>();
  late final int _seedWordCount;
  late final bool isDesktop;

  final HashSet<String> _wordListHashSet = HashSet.from(bip39wordlist.WORDLIST);
  final ScrollController controller = ScrollController();

  final List<TextEditingController> _controllers = [];
  final List<FormInputStatus> _inputStatuses = [];

  late final BarcodeScannerInterface scanner;

  late final TextSelectionControls textSelectionControls;

  Future<void> onControlsPaste(TextSelectionDelegate delegate) async {
    final data = await widget.clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) {
      return;
    }

    final text = data!.text!.trim();
    if (text.isEmpty || _controllers.isEmpty) {
      unawaited(delegate.pasteText(SelectionChangedCause.toolbar));
      return;
    }

    final words = text.split(" ");
    if (words.isEmpty) {
      unawaited(delegate.pasteText(SelectionChangedCause.toolbar));
      return;
    }

    if (words.length == 1) {
      _controllers.first.text = words.first;
      if (_isValidMnemonicWord(words.first.toLowerCase())) {
        setState(() {
          _inputStatuses.first = FormInputStatus.valid;
        });
      } else {
        setState(() {
          _inputStatuses.first = FormInputStatus.invalid;
        });
      }
      return;
    }

    _clearAndPopulateMnemonic(words);
  }

  @override
  void initState() {
    _seedWordCount = widget.seedWordsLength;
    isDesktop = Util.isDesktop;

    textSelectionControls = Platform.isIOS
        ? CustomCupertinoTextSelectionControls(onPaste: onControlsPaste)
        : CustomMaterialTextSelectionControls(onPaste: onControlsPaste);

    scanner = widget.barcodeScanner;
    for (int i = 0; i < _seedWordCount; i++) {
      _controllers.add(TextEditingController());
      _inputStatuses.add(FormInputStatus.empty);
    }

    super.initState();
  }

  @override
  void dispose() {
    for (var element in _controllers) {
      element.dispose();
    }

    super.dispose();
  }

  // TODO: check for wownero wordlist?
  bool _isValidMnemonicWord(String word) {
    // TODO: get the actual language
    if (widget.coin == Coin.monero) {
      var moneroWordList = monero.getMoneroWordList("English");
      return moneroWordList.contains(word);
    }
    if (widget.coin == Coin.wownero) {
      var wowneroWordList = wownero.getWowneroWordList("English",
          seedWordsLength: widget.seedWordsLength);
      return wowneroWordList.contains(word);
    }
    return _wordListHashSet.contains(word);
  }

  OutlineInputBorder _buildOutlineInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: color,
      ),
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
    );
  }

  Future<void> attemptRestore() async {
    if (_formKey.currentState!.validate()) {
      String mnemonic = "";
      for (var element in _controllers) {
        mnemonic += " ${element.text.trim().toLowerCase()}";
      }
      mnemonic = mnemonic.trim();

      int height = 0;

      if (widget.coin == Coin.monero) {
        height = monero.getHeigthByDate(date: widget.restoreFromDate);
      } else if (widget.coin == Coin.wownero) {
        height = wownero.getHeightByDate(date: widget.restoreFromDate);
      }
      // todo: wait until this implemented
      // else if (widget.coin == Coin.wownero) {
      //   height = wownero.getHeightByDate(date: widget.restoreFromDate);
      // }

      // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
      if (widget.coin == Coin.epicCash) {
        int secondsSinceEpoch =
            widget.restoreFromDate.millisecondsSinceEpoch ~/ 1000;
        const int epicCashFirstBlock = 1565370278;
        const double overestimateSecondsPerBlock = 61;
        int chosenSeconds = secondsSinceEpoch - epicCashFirstBlock;
        int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
        //todo: check if print needed
        // debugPrint(
        //     "approximate height: $approximateHeight chosen_seconds: $chosenSeconds");
        height = approximateHeight;
        if (height < 0) {
          height = 0;
        }
      }

      // TODO: do actual check to make sure it is a valid mnemonic for monero
      if (bip39.validateMnemonic(mnemonic) == false &&
          !(widget.coin == Coin.monero || widget.coin == Coin.wownero)) {
        unawaited(showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Invalid seed phrase!",
          context: context,
        ));
      } else {
        if (!Platform.isLinux) await Wakelock.enable();
        final walletsService = ref.read(walletsServiceChangeNotifierProvider);

        final walletId = await walletsService.addNewWallet(
          name: widget.walletName,
          coin: widget.coin,
          shouldNotifyListeners: false,
        );
        bool isRestoring = true;
        // show restoring in progress
        unawaited(showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (context) {
            return RestoringDialog(
              onCancel: () async {
                isRestoring = false;
                ref
                    .read(walletsChangeNotifierProvider.notifier)
                    .removeWallet(walletId: walletId!);

                await walletsService.deleteWallet(
                  widget.walletName,
                  false,
                );
              },
            );
          },
        ));

        var node = ref
            .read(nodeServiceChangeNotifierProvider)
            .getPrimaryNodeFor(coin: widget.coin);

        if (node == null) {
          node = DefaultNodes.getNodeFor(widget.coin);
          await ref.read(nodeServiceChangeNotifierProvider).setPrimaryNodeFor(
                coin: widget.coin,
                node: node,
              );
        }

        final txTracker = TransactionNotificationTracker(walletId: walletId!);

        final failovers = ref
            .read(nodeServiceChangeNotifierProvider)
            .failoverNodesFor(coin: widget.coin);

        final wallet = CoinServiceAPI.from(
          widget.coin,
          walletId,
          widget.walletName,
          ref.read(secureStoreProvider),
          node,
          txTracker,
          ref.read(prefsChangeNotifierProvider),
          failovers,
        );

        final manager = Manager(wallet);

        try {
          // TODO GUI option to set maxUnusedAddressGap?
          // default is 20 but it may miss some transactions if
          // the previous wallet software generated many addresses
          // without using them
          await manager.recoverFromMnemonic(
            mnemonic: mnemonic,
            mnemonicPassphrase: "", // TODO add ui for certain coins
            maxUnusedAddressGap: widget.coin == Coin.firo ? 50 : 20,
            maxNumberOfIndexesToCheck: 1000,
            height: height,
          );

          // check if state is still active before continuing
          if (mounted) {
            await ref
                .read(walletsServiceChangeNotifierProvider)
                .setMnemonicVerified(
                  walletId: manager.walletId,
                );

            ref
                .read(walletsChangeNotifierProvider.notifier)
                .addWallet(walletId: manager.walletId, manager: manager);

            if (mounted) {
              if (isDesktop) {
                Navigator.of(context)
                    .popUntil(ModalRoute.withName(DesktopHomeView.routeName));
              } else {
                unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
                    HomeView.routeName, (route) => false));
              }
            }

            await showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (context) {
                return const RestoreSucceededDialog();
              },
            );
            if (!Platform.isLinux && !isDesktop) {
              await Wakelock.disable();
            }
          }
        } catch (e) {
          if (!Platform.isLinux && !isDesktop) {
            await Wakelock.disable();
          }

          // if (e is HiveError &&
          //     e.message == "Box has already been closed.") {
          //   // restore was cancelled
          //   return;
          // }

          // check if state is still active and restore wasn't cancelled
          // before continuing
          if (mounted && isRestoring) {
            // pop waiting dialog
            Navigator.pop(context);

            // show restoring wallet failed dialog
            await showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (context) {
                return RestoreFailedDialog(
                  errorMessage: e.toString(),
                  walletId: wallet.walletId,
                  walletName: wallet.walletName,
                );
              },
            );
          }
        }

        if (!Platform.isLinux && !isDesktop) {
          await Wakelock.disable();
        }
      }
    }
  }

  InputDecoration _getInputDecorationFor(
      FormInputStatus status, String prefix) {
    Color color;
    Color prefixColor;
    Color borderColor;
    Widget? suffixIcon;
    switch (status) {
      case FormInputStatus.empty:
        color = Theme.of(context).extension<StackColors>()!.textFieldDefaultBG;
        prefixColor = Theme.of(context).extension<StackColors>()!.textSubtitle2;
        borderColor =
            Theme.of(context).extension<StackColors>()!.textFieldDefaultBG;
        break;
      case FormInputStatus.invalid:
        color = Theme.of(context).extension<StackColors>()!.textFieldErrorBG;
        prefixColor = Theme.of(context)
            .extension<StackColors>()!
            .textFieldErrorSearchIconLeft;
        borderColor =
            Theme.of(context).extension<StackColors>()!.textFieldErrorBorder;
        suffixIcon = SvgPicture.asset(
          Assets.svg.alertCircle,
          width: 16,
          height: 16,
          color: Theme.of(context)
              .extension<StackColors>()!
              .textFieldErrorSearchIconRight,
        );
        break;
      case FormInputStatus.valid:
        color = Theme.of(context).extension<StackColors>()!.textFieldSuccessBG;
        prefixColor = Theme.of(context)
            .extension<StackColors>()!
            .textFieldSuccessSearchIconLeft;
        borderColor =
            Theme.of(context).extension<StackColors>()!.textFieldSuccessBorder;
        suffixIcon = SvgPicture.asset(
          Assets.svg.checkCircle,
          width: 16,
          height: 16,
          color: Theme.of(context)
              .extension<StackColors>()!
              .textFieldSuccessSearchIconRight,
        );
        break;
    }
    return InputDecoration(
      fillColor: color,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
      prefixIcon: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            bottom: 2,
          ),
          child: Text(
            prefix,
            style: STextStyles.fieldLabel(context).copyWith(
              color: prefixColor,
              fontSize: Util.isDesktop ? 16 : 14,
            ),
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
        maxWidth: 36,
        maxHeight: 32,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
        maxWidth: 28,
        maxHeight: 16,
      ),
      suffixIcon: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: suffixIcon,
        ),
      ),
      enabledBorder: _buildOutlineInputBorder(borderColor),
      focusedBorder: _buildOutlineInputBorder(borderColor),
      errorBorder: _buildOutlineInputBorder(borderColor),
      disabledBorder: _buildOutlineInputBorder(borderColor),
      focusedErrorBorder: _buildOutlineInputBorder(borderColor),
    );
  }

  void _clearAndPopulateMnemonic(List<String> words) {
    final count = min(_controllers.length, words.length);

    // replace field content with listed words
    for (int i = 0; i < count; i++) {
      final word = words[i].trim();
      _controllers[i].text = words[i];
      if (_isValidMnemonicWord(word.toLowerCase())) {
        setState(() {
          _inputStatuses[i] = FormInputStatus.valid;
        });
      } else {
        setState(() {
          _inputStatuses[i] = FormInputStatus.invalid;
        });
      }
    }

    // clear remaining fields
    for (int i = count; i < _controllers.length; i++) {
      _controllers[i].text = "";
      setState(() {
        _inputStatuses[i] = FormInputStatus.empty;
      });
    }

    if (!isDesktop) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }
  }

  Future<void> scanMnemonicQr() async {
    try {
      final qrResult = await scanner.scan();

      final results = AddressUtils.decodeQRSeedData(qrResult.rawContent);

      Logging.instance.log("scan parsed: $results", level: LogLevel.Info);

      if (results["mnemonic"] != null) {
        final list = (results["mnemonic"] as List)
            .map((value) => value as String)
            .toList(growable: false);
        if (list.isNotEmpty) {
          _clearAndPopulateMnemonic(list);
          Logging.instance.log("mnemonic populated", level: LogLevel.Info);
        } else {
          Logging.instance
              .log("mnemonic failed to populate", level: LogLevel.Info);
        }
      }
    } on PlatformException catch (e) {
      // likely failed to get camera permissions
      Logging.instance
          .log("Restore wallet qr scan failed: $e", level: LogLevel.Warning);
    }
  }

  Future<void> pasteMnemonic() async {
    //todo: check if print needed
    // debugPrint("restoreWalletPasteButton tapped");
    final ClipboardData? data =
        await widget.clipboard.getData(Clipboard.kTextPlain);

    if (data?.text != null && data!.text!.isNotEmpty) {
      final content = data.text!.trim();
      final list = content.split(" ");
      _clearAndPopulateMnemonic(list);
    }
  }

  Future<void> requestRestore() async {
    // wait for keyboard to disappear
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await showDialog<dynamic>(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (context) {
        return ConfirmRecoveryDialog(
          onConfirm: attemptRestore,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? const DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(),
              trailing: ExitToMyStackButton(),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 50));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    right: 10,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      key: const Key("restoreWalletViewQrCodeButton"),
                      size: 36,
                      shadows: const [],
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      icon: QrCodeIcon(
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                      onPressed: scanMnemonicQr,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    right: 10,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBarIconButton(
                      key: const Key("restoreWalletPasteButton"),
                      size: 36,
                      shadows: const [],
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      icon: ClipboardIcon(
                        width: 20,
                        height: 20,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                      onPressed: pasteMnemonic,
                    ),
                  ),
                ),
              ],
            ),
      body: Container(
        color: Theme.of(context).extension<StackColors>()!.background,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (isDesktop)
                const Spacer(
                  flex: 10,
                ),
              if (!isDesktop)
                Text(
                  widget.walletName,
                  style: STextStyles.itemSubtitle(context),
                ),
              SizedBox(
                height: isDesktop ? 0 : 4,
              ),
              Text(
                "Recovery phrase",
                style: isDesktop
                    ? STextStyles.desktopH2(context)
                    : STextStyles.pageTitleH1(context),
              ),
              SizedBox(
                height: isDesktop ? 16 : 8,
              ),
              Text(
                "Enter your $_seedWordCount-word recovery phrase.",
                style: isDesktop
                    ? STextStyles.desktopSubtitleH2(context)
                    : STextStyles.subtitle(context),
              ),
              SizedBox(
                height: isDesktop ? 16 : 10,
              ),
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: pasteMnemonic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              Assets.svg.clipboard,
                              width: 22,
                              height: 22,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonTextSecondary,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Paste",
                              style: STextStyles
                                  .desktopButtonSmallSecondaryEnabled(context),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (isDesktop)
                const SizedBox(
                  height: 20,
                ),
              if (isDesktop)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1008,
                  ),
                  child: Builder(
                    builder: (BuildContext context) {
                      const cols = 4;
                      final int rows = _seedWordCount ~/ cols;
                      final int remainder = _seedWordCount % cols;

                      return Column(
                        children: [
                          Form(
                            key: _formKey,
                            child: TableView(
                              shrinkWrap: true,
                              rowSpacing: 20,
                              rows: [
                                for (int i = 0; i < rows; i++)
                                  TableViewRow(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 16,
                                    cells: [
                                      for (int j = 1; j <= cols; j++)
                                        TableViewCell(
                                          flex: 1,
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                autocorrect: !isDesktop,
                                                enableSuggestions: !isDesktop,
                                                textCapitalization:
                                                    TextCapitalization.none,
                                                key: Key(
                                                    "restoreMnemonicFormField_$i"),
                                                decoration:
                                                    _getInputDecorationFor(
                                                        _inputStatuses[
                                                            i * 4 + j - 1],
                                                        "${i * 4 + j}"),
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                                selectionControls:
                                                    i * 4 + j - 1 == 1
                                                        ? textSelectionControls
                                                        : null,
                                                onChanged: (value) {
                                                  if (value.isEmpty) {
                                                    setState(() {
                                                      _inputStatuses[
                                                              i * 4 + j - 1] =
                                                          FormInputStatus.empty;
                                                    });
                                                  } else if (_isValidMnemonicWord(
                                                      value
                                                          .trim()
                                                          .toLowerCase())) {
                                                    setState(() {
                                                      _inputStatuses[
                                                              i * 4 + j - 1] =
                                                          FormInputStatus.valid;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _inputStatuses[
                                                              i * 4 + j - 1] =
                                                          FormInputStatus
                                                              .invalid;
                                                    });
                                                  }
                                                },
                                                controller:
                                                    _controllers[i * 4 + j - 1],
                                                style:
                                                    STextStyles.field(context)
                                                        .copyWith(
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textRestore,
                                                  fontSize: isDesktop ? 16 : 14,
                                                ),
                                              ),
                                              if (_inputStatuses[
                                                      i * 4 + j - 1] ==
                                                  FormInputStatus.invalid)
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 12.0,
                                                      bottom: 4.0,
                                                    ),
                                                    child: Text(
                                                      "Please check spelling",
                                                      textAlign: TextAlign.left,
                                                      style: STextStyles.label(
                                                              context)
                                                          .copyWith(
                                                        color: Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .textError,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                    ],
                                    expandingChild: null,
                                  ),
                                if (remainder > 0)
                                  TableViewRow(
                                    spacing: 16,
                                    cells: [
                                      for (int i = rows * cols;
                                          i < _seedWordCount;
                                          i++) ...[
                                        TableViewCell(
                                          flex: 1,
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                autocorrect: !isDesktop,
                                                enableSuggestions: !isDesktop,
                                                textCapitalization:
                                                    TextCapitalization.none,
                                                key: Key(
                                                    "restoreMnemonicFormField_$i"),
                                                decoration:
                                                    _getInputDecorationFor(
                                                        _inputStatuses[i],
                                                        "${i + 1}"),
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                                selectionControls: i == 1
                                                    ? textSelectionControls
                                                    : null,
                                                onChanged: (value) {
                                                  if (value.isEmpty) {
                                                    setState(() {
                                                      _inputStatuses[i] =
                                                          FormInputStatus.empty;
                                                    });
                                                  } else if (_isValidMnemonicWord(
                                                      value
                                                          .trim()
                                                          .toLowerCase())) {
                                                    setState(() {
                                                      _inputStatuses[i] =
                                                          FormInputStatus.valid;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _inputStatuses[i] =
                                                          FormInputStatus
                                                              .invalid;
                                                    });
                                                  }
                                                },
                                                controller: _controllers[i],
                                                style:
                                                    STextStyles.field(context)
                                                        .copyWith(
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .overlay,
                                                  fontSize: isDesktop ? 16 : 14,
                                                ),
                                              ),
                                              if (_inputStatuses[i] ==
                                                  FormInputStatus.invalid)
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 12.0,
                                                      bottom: 4.0,
                                                    ),
                                                    child: Text(
                                                      "Please check spelling",
                                                      textAlign: TextAlign.left,
                                                      style: STextStyles.label(
                                                              context)
                                                          .copyWith(
                                                        color: Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .textError,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                      ],
                                      for (int i = remainder;
                                          i < cols;
                                          i++) ...[
                                        TableViewCell(
                                          flex: 1,
                                          child: Container(),
                                        ),
                                      ],
                                    ],
                                    expandingChild: null,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          PrimaryButton(
                            label: "Restore wallet",
                            width: 480,
                            onPressed: requestRestore,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (isDesktop)
                const Spacer(
                  flex: 15,
                ),
              if (!isDesktop)
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 1; i <= _seedWordCount; i++)
                              Column(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: TextFormField(
                                      autocorrect: !isDesktop,
                                      enableSuggestions: !isDesktop,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      key: Key("restoreMnemonicFormField_$i"),
                                      decoration: _getInputDecorationFor(
                                          _inputStatuses[i - 1], "$i"),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      selectionControls:
                                          i == 1 ? textSelectionControls : null,
                                      onChanged: (value) {
                                        if (value.isEmpty) {
                                          setState(() {
                                            _inputStatuses[i - 1] =
                                                FormInputStatus.empty;
                                          });
                                        } else if (_isValidMnemonicWord(
                                            value.trim().toLowerCase())) {
                                          setState(() {
                                            _inputStatuses[i - 1] =
                                                FormInputStatus.valid;
                                          });
                                        } else {
                                          setState(() {
                                            _inputStatuses[i - 1] =
                                                FormInputStatus.invalid;
                                          });
                                        }
                                      },
                                      controller: _controllers[i - 1],
                                      style:
                                          STextStyles.field(context).copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textRestore,
                                        fontSize: isDesktop ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                  if (_inputStatuses[i - 1] ==
                                      FormInputStatus.invalid)
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12.0,
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          "Please check spelling",
                                          textAlign: TextAlign.left,
                                          style: STextStyles.label(context)
                                              .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textError,
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                              ),
                              child: PrimaryButton(
                                onPressed: requestRestore,
                                label: "Restore",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

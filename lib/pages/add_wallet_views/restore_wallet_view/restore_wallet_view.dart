import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/wordlists/english.dart' as bip39wordlist;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/confirm_recovery_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restore_failed_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restore_succeeded_dialog.dart';
import 'package:stackwallet/pages/add_wallet_views/restore_wallet_view/sub_widgets/restoring_dialog.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/enums/form_input_status_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/clipboard_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/qrcode_icon.dart';
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

  final HashSet<String> _wordListHashSet = HashSet.from(bip39wordlist.WORDLIST);
  final ScrollController controller = ScrollController();

  final List<TextEditingController> _controllers = [];
  // late final TextEditingController _heightController;
  final List<FormInputStatus> _inputStatuses = [];

  // late final FocusNode _heightFocusNode;

  late final BarcodeScannerInterface scanner;

  @override
  void initState() {
    _seedWordCount = widget.seedWordsLength;

    // _heightFocusNode = FocusNode();

    scanner = widget.barcodeScanner;
    for (int i = 0; i < _seedWordCount; i++) {
      _controllers.add(TextEditingController());
      _inputStatuses.add(FormInputStatus.empty);
    }
    // _heightController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    for (var element in _controllers) {
      element.dispose();
    }
    // _heightController.dispose();
    // _heightFocusNode.dispose();
    super.dispose();
  }

  bool _isValidMnemonicWord(String word) {
    // TODO: get the actual language
    if (widget.coin == Coin.monero) {
      var moneroWordList = monero.getMoneroWordList("English");
      return moneroWordList.contains(word);
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
      }

      // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
      if (widget.coin == Coin.epicCash) {
        int secondsSinceEpoch =
            widget.restoreFromDate.millisecondsSinceEpoch ~/ 1000;
        const int epicCashFirstBlock = 1565370278;
        const double overestimateSecondsPerBlock = 61;
        int chosenSeconds = secondsSinceEpoch - epicCashFirstBlock;
        int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
        debugPrint(
            "approximate height: $approximateHeight chosen_seconds: $chosenSeconds");
        height = approximateHeight;
        if (height < 0) {
          height = 0;
        }
      }

      // TODO: do actual check to make sure it is a valid mnemonic for monero
      if (bip39.validateMnemonic(mnemonic) == false &&
          !(widget.coin == Coin.monero)) {
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Invalid seed phrase!",
          context: context,
        );
      } else {
        if (!Platform.isLinux) Wakelock.enable();
        final walletsService = ref.read(walletsServiceChangeNotifierProvider);

        final walletId = await walletsService.addNewWallet(
          name: widget.walletName,
          coin: widget.coin,
          shouldNotifyListeners: false,
        );
        bool isRestoring = true;
        // show restoring in progress
        showDialog<dynamic>(
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
        );

        var node = ref
            .read(nodeServiceChangeNotifierProvider)
            .getPrimaryNodeFor(coin: widget.coin);

        if (node == null) {
          node = DefaultNodes.getNodeFor(widget.coin);
          ref.read(nodeServiceChangeNotifierProvider).setPrimaryNodeFor(
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
            maxUnusedAddressGap: 20,
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
              Navigator.of(context).pushNamedAndRemoveUntil(
                  HomeView.routeName, (route) => false);
            }

            showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (context) {
                return const RestoreSucceededDialog();
              },
            ).then(
              (_) {
                if (!Platform.isLinux) Wakelock.disable();
                // timer.cancel();
              },
            );
          }
        } catch (e) {
          if (!Platform.isLinux) Wakelock.disable();

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
            showDialog<dynamic>(
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

        if (!Platform.isLinux) Wakelock.disable();
      }
    }
  }

  InputDecoration _getInputDecorationFor(
      FormInputStatus status, String prefix) {
    Color color;
    Color prefixColor;
    Widget? suffixIcon;
    switch (status) {
      case FormInputStatus.empty:
        color = CFColors.fieldGray;
        prefixColor = CFColors.gray3;
        break;
      case FormInputStatus.invalid:
        color = CFColors.notificationRedBackground;
        prefixColor = CFColors.notificationRedForeground;
        suffixIcon = SvgPicture.asset(
          Assets.svg.alertCircle,
          width: 16,
          height: 16,
          color: CFColors.notificationRedForeground,
        );
        break;
      case FormInputStatus.valid:
        color = CFColors.notificationGreenBackground;
        prefixColor = CFColors.notificationGreenForeground;
        suffixIcon = SvgPicture.asset(
          Assets.svg.checkCircle,
          width: 16,
          height: 16,
          color: CFColors.notificationGreenForeground,
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
            style: STextStyles.fieldLabel.copyWith(
              color: prefixColor,
            ),
          ),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
        maxWidth: 36,
        maxHeight: 20,
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
      enabledBorder: _buildOutlineInputBorder(color),
      focusedBorder: _buildOutlineInputBorder(color),
      errorBorder: _buildOutlineInputBorder(color),
      disabledBorder: _buildOutlineInputBorder(color),
      focusedErrorBorder: _buildOutlineInputBorder(color),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 50));
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
                color: CFColors.almostWhite,
                icon: const QrCodeIcon(
                  width: 20,
                  height: 20,
                  color: CFColors.stackAccent,
                ),
                onPressed: () async {
                  try {
                    // ref
                    //     .read(shouldShowLockscreenOnResumeStateProvider.state)
                    //     .state = false;
                    final qrResult = await scanner.scan();

                    // Future<void>.delayed(
                    //   const Duration(seconds: 2),
                    //   () => ref
                    //       .read(shouldShowLockscreenOnResumeStateProvider.state)
                    //       .state = true,
                    // );

                    final results =
                        AddressUtils.decodeQRSeedData(qrResult.rawContent);

                    Logging.instance
                        .log("scan parsed: $results", level: LogLevel.Info);

                    if (results["mnemonic"] != null) {
                      final list = (results["mnemonic"] as List)
                          .map((value) => value as String)
                          .toList(growable: false);
                      if (list.isNotEmpty) {
                        _clearAndPopulateMnemonic(list);
                        Logging.instance
                            .log("mnemonic populated", level: LogLevel.Info);
                      } else {
                        Logging.instance.log("mnemonic failed to populate",
                            level: LogLevel.Info);
                      }
                    }
                  } on PlatformException catch (e) {
                    // ref
                    //     .read(shouldShowLockscreenOnResumeStateProvider.state)
                    //     .state = true;
                    // likely failed to get camera permissions
                    Logging.instance.log("Restore wallet qr scan failed: $e",
                        level: LogLevel.Warning);
                  }
                },
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
                color: CFColors.almostWhite,
                icon: const ClipboardIcon(
                  width: 20,
                  height: 20,
                  color: CFColors.stackAccent,
                ),
                onPressed: () async {
                  debugPrint("restoreWalletPasteButton tapped");
                  final ClipboardData? data =
                      await widget.clipboard.getData(Clipboard.kTextPlain);

                  if (data?.text != null && data!.text!.isNotEmpty) {
                    final content = data.text!.trim();
                    final list = content.split(" ");
                    _clearAndPopulateMnemonic(list);
                    controller.animateTo(controller.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.decelerate);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: CFColors.almostWhite,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                widget.walletName,
                style: STextStyles.itemSubtitle,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                "Recovery phrase",
                style: STextStyles.pageTitleH1,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                "Enter your $_seedWordCount-word recovery phrase.",
                style: STextStyles.subtitle,
              ),
              const SizedBox(
                height: 10,
              ),
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
                                    textCapitalization: TextCapitalization.none,
                                    key: Key("restoreMnemonicFormField_$i"),
                                    decoration: _getInputDecorationFor(
                                        _inputStatuses[i - 1], "$i"),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
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
                                    style: STextStyles.field,
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
                                        style: STextStyles.label.copyWith(
                                          color: CFColors
                                              .notificationRedForeground,
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          // if (widget.coin == Coin.monero ||
                          //     widget.coin == Coin.epicCash)
                          //   Padding(
                          //     padding: const EdgeInsets.only(
                          //       top: 8.0,
                          //     ),
                          //     child: ClipRRect(
                          //       borderRadius: BorderRadius.circular(
                          //         Constants.size.circularBorderRadius,
                          //       ),
                          //       child: TextField(
                          //         key: Key("restoreMnemonicFormField_height"),
                          //         inputFormatters: <TextInputFormatter>[
                          //           FilteringTextInputFormatter.allow(
                          //               RegExp("[0-9]*")),
                          //         ],
                          //         keyboardType:
                          //             TextInputType.numberWithOptions(),
                          //         controller: _heightController,
                          //         focusNode: _heightFocusNode,
                          //         style: STextStyles.field,
                          //         decoration: standardInputDecoration(
                          //           "Height",
                          //           _heightFocusNode,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                            ),
                            child: TextButton(
                              style: Theme.of(context)
                                  .textButtonTheme
                                  .style
                                  ?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent,
                                    ),
                                  ),
                              onPressed: () async {
                                // wait for keyboard to disappear
                                FocusScope.of(context).unfocus();
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 100),
                                );

                                showDialog<dynamic>(
                                  context: context,
                                  useSafeArea: false,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return ConfirmRecoveryDialog(
                                      onConfirm: attemptRestore,
                                    );
                                  },
                                );
                              },
                              child: Text(
                                "Restore",
                                style: STextStyles.button,
                              ),
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

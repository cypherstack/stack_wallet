import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cs_monero/src/deprecated/get_height_by_date.dart'
    as cs_monero_deprecated;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/isar/models/wallet_info.dart';
import '../../../wallets/wallet/impl/epiccash_wallet.dart';
import '../../../wallets/wallet/impl/monero_wallet.dart';
import '../../../wallets/wallet/impl/wownero_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/view_only_option_interface.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/stack_text_field.dart';
import '../../home_view/home_view.dart';
import 'confirm_recovery_dialog.dart';
import 'sub_widgets/restore_failed_dialog.dart';
import 'sub_widgets/restore_succeeded_dialog.dart';
import 'sub_widgets/restoring_dialog.dart';

class RestoreViewOnlyWalletView extends ConsumerStatefulWidget {
  const RestoreViewOnlyWalletView({
    super.key,
    required this.walletName,
    required this.coin,
    required this.restoreFromDate,
    this.enableLelantusScanning = false,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  });

  static const routeName = "/restoreViewOnlyWallet";

  final String walletName;
  final CryptoCurrency coin;
  final DateTime? restoreFromDate;
  final bool enableLelantusScanning;
  final BarcodeScannerInterface barcodeScanner;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<RestoreViewOnlyWalletView> createState() =>
      _RestoreViewOnlyWalletViewState();
}

class _RestoreViewOnlyWalletViewState
    extends ConsumerState<RestoreViewOnlyWalletView> {
  late final TextEditingController addressController;
  late final TextEditingController viewKeyController;

  bool _enableRestoreButton = false;

  bool _buttonLock = false;

  Future<void> _requestRestore() async {
    if (_buttonLock) return;
    _buttonLock = true;

    try {
      if (!Util.isDesktop) {
        // wait for keyboard to disappear
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );
      }

      if (mounted) {
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return ConfirmRecoveryDialog(
              onConfirm: _attemptRestore,
            );
          },
        );
      }
    } finally {
      _buttonLock = false;
    }
  }

  Future<void> _attemptRestore() async {
    int height = 0;
    final Map<String, dynamic> otherDataJson = {
      WalletInfoKeys.isViewOnlyKey: true,
    };

    if (widget.restoreFromDate != null) {
      if (widget.coin is Monero) {
        height = cs_monero_deprecated.getMoneroHeightByDate(
          date: widget.restoreFromDate!,
        );
      }
      if (widget.coin is Wownero) {
        height = cs_monero_deprecated.getWowneroHeightByDate(
          date: widget.restoreFromDate!,
        );
      }
      if (height < 0) {
        height = 0;
      }
    }

    if (widget.coin is Firo) {
      otherDataJson.addAll(
        {
          WalletInfoKeys.lelantusCoinIsarRescanRequired: false,
          WalletInfoKeys.enableLelantusScanning: widget.enableLelantusScanning,
        },
      );
    }

    if (!Platform.isLinux && !Util.isDesktop) await WakelockPlus.enable();

    try {
      final info = WalletInfo.createNew(
        coin: widget.coin,
        name: widget.walletName,
        restoreHeight: height,
        otherDataJsonString: jsonEncode(otherDataJson),
      );

      bool isRestoring = true;
      // show restoring in progress

      if (mounted) {
        unawaited(
          showDialog<dynamic>(
            context: context,
            useSafeArea: false,
            barrierDismissible: false,
            builder: (context) {
              return RestoringDialog(
                onCancel: () async {
                  isRestoring = false;

                  await ref.read(pWallets).deleteWallet(
                        info,
                        ref.read(secureStoreProvider),
                      );
                },
              );
            },
          ),
        );
      }

      var node = ref
          .read(nodeServiceChangeNotifierProvider)
          .getPrimaryNodeFor(currency: widget.coin);

      if (node == null) {
        node = widget.coin.defaultNode;
        await ref.read(nodeServiceChangeNotifierProvider).setPrimaryNodeFor(
              coin: widget.coin,
              node: node,
            );
      }

      try {
        final wallet = await Wallet.create(
          walletInfo: info,
          mainDB: ref.read(mainDBProvider),
          secureStorageInterface: ref.read(secureStoreProvider),
          nodeService: ref.read(nodeServiceChangeNotifierProvider),
          prefs: ref.read(prefsChangeNotifierProvider),
          viewOnlyData: ViewOnlyWalletData(
            address: addressController.text,
            privateViewKey: viewKeyController.text,
          ),
        );

        // TODO: extract interface with isRestore param
        switch (wallet.runtimeType) {
          case const (EpiccashWallet):
            await (wallet as EpiccashWallet).init(isRestore: true);
            break;

          case const (MoneroWallet):
            await (wallet as MoneroWallet).init(isRestore: true);
            break;

          case const (WowneroWallet):
            await (wallet as WowneroWallet).init(isRestore: true);
            break;

          default:
            await wallet.init();
        }

        await wallet.recover(isRescan: false);

        // check if state is still active before continuing
        if (mounted) {
          // don't remove this setMnemonicVerified thing
          await wallet.info.setMnemonicVerified(
            isar: ref.read(mainDBProvider).isar,
          );

          ref.read(pWallets).addWallet(wallet);

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

            await showDialog<dynamic>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (context) {
                return const RestoreSucceededDialog();
              },
            );
          }
        }
      } catch (e) {
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
                walletId: info.walletId,
                walletName: info.name,
              );
            },
          );
        }
      }
    } finally {
      if (!Platform.isLinux && !Util.isDesktop) await WakelockPlus.disable();
    }
  }

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController();
    viewKeyController = TextEditingController();
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
                      const Duration(milliseconds: 50),
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
      body: Container(
        color: Theme.of(context).extension<StackColors>()!.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: isDesktop ? 480 : double.infinity,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                          "Enter view only details",
                          style: isDesktop
                              ? STextStyles.desktopH2(context)
                              : STextStyles.pageTitleH1(context),
                        ),
                        SizedBox(
                          height: isDesktop ? 24 : 16,
                        ),
                        FullTextField(
                          label: "Address",
                          controller: addressController,
                          onChanged: (newValue) {
                            setState(() {
                              _enableRestoreButton = newValue.isNotEmpty &&
                                  viewKeyController.text.isNotEmpty;
                            });
                          },
                        ),
                        SizedBox(
                          height: isDesktop ? 16 : 12,
                        ),
                        FullTextField(
                          label: "View Key",
                          controller: viewKeyController,
                          onChanged: (value) {
                            setState(() {
                              _enableRestoreButton = value.isNotEmpty &&
                                  addressController.text.isNotEmpty;
                            });
                          },
                        ),
                        if (!isDesktop) const Spacer(),
                        SizedBox(
                          height: isDesktop ? 24 : 16,
                        ),
                        PrimaryButton(
                          enabled: _enableRestoreButton,
                          onPressed: _requestRestore,
                          width: isDesktop ? 480 : null,
                          label: "Restore",
                        ),
                        if (isDesktop)
                          const Spacer(
                            flex: 15,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

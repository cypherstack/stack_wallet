import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cs_monero/src/deprecated/get_height_by_date.dart'
    as cs_monero_deprecated;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../models/keys/view_only_wallet_data.dart';
import '../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/barcode_scanner_interface.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../../wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import '../../../wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import '../../../wallets/isar/models/wallet_info.dart';
import '../../../wallets/wallet/impl/epiccash_wallet.dart';
import '../../../wallets/wallet/impl/monero_wallet.dart';
import '../../../wallets/wallet/impl/wownero_wallet.dart';
import '../../../wallets/wallet/impl/xelis_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/stack_text_field.dart';
import '../../../widgets/toggle.dart';
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
    required this.restoreBlockHeight,
    this.enableLelantusScanning = false,
    this.barcodeScanner = const BarcodeScannerWrapper(),
    this.clipboard = const ClipboardWrapper(),
  });

  static const routeName = "/restoreViewOnlyWallet";

  final String walletName;
  final CryptoCurrency coin;
  final int restoreBlockHeight;
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

  late String _currentDropDownValue;

  bool _enableRestoreButton = false;
  bool _addressOnly = false;

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
    final Map<String, dynamic> otherDataJson = {
      WalletInfoKeys.isViewOnlyKey: true,
    };

    final ViewOnlyWalletType viewOnlyWalletType;
    if (widget.coin is Bip39HDCurrency) {
      if (widget.coin is Firo) {
        otherDataJson.addAll(
          {
            WalletInfoKeys.lelantusCoinIsarRescanRequired: false,
            WalletInfoKeys.enableLelantusScanning:
                widget.enableLelantusScanning,
          },
        );
      }
      viewOnlyWalletType = _addressOnly
          ? ViewOnlyWalletType.addressOnly
          : ViewOnlyWalletType.xPub;
    } else if (widget.coin is CryptonoteCurrency) {
      viewOnlyWalletType = ViewOnlyWalletType.cryptonote;
    } else {
      throw Exception(
        "Unsupported view only wallet currency type found: ${widget.coin.runtimeType}",
      );
    }
    otherDataJson[WalletInfoKeys.viewOnlyTypeIndexKey] =
        viewOnlyWalletType.index;

    if (!Platform.isLinux && !Util.isDesktop) await WakelockPlus.enable();

    try {
      final info = WalletInfo.createNew(
        coin: widget.coin,
        name: widget.walletName,
        restoreHeight: widget.restoreBlockHeight,
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

      final ViewOnlyWalletData viewOnlyData;
      switch (viewOnlyWalletType) {
        case ViewOnlyWalletType.cryptonote:
          if (addressController.text.isEmpty ||
              viewKeyController.text.isEmpty) {
            throw Exception("Missing address and/or private view key fields");
          }
          viewOnlyData = CryptonoteViewOnlyWalletData(
            walletId: info.walletId,
            address: addressController.text,
            privateViewKey: viewKeyController.text,
          );
          break;

        case ViewOnlyWalletType.addressOnly:
          if (addressController.text.isEmpty) {
            throw Exception("Address is empty");
          }
          viewOnlyData = AddressViewOnlyWalletData(
            walletId: info.walletId,
            address: addressController.text,
          );
          break;

        case ViewOnlyWalletType.xPub:
          viewOnlyData = ExtendedKeysViewOnlyWalletData(
            walletId: info.walletId,
            xPubs: [
              XPub(
                path: _currentDropDownValue,
                encoded: viewKeyController.text,
              ),
            ],
          );
          break;
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
          viewOnlyData: viewOnlyData,
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

          case const (XelisWallet):
            await (wallet as XelisWallet).init(isRestore: true);
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

    if (widget.coin is Bip39HDCurrency) {
      _currentDropDownValue = (widget.coin as Bip39HDCurrency)
          .supportedHardenedDerivationPaths
          .last;
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    viewKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    final isElectrumX = widget.coin is ElectrumXCurrencyInterface;

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
                        if (isElectrumX)
                          SizedBox(
                            height: isDesktop ? 24 : 16,
                          ),
                        if (isElectrumX)
                          SizedBox(
                            height: isDesktop ? 56 : 48,
                            width: isDesktop ? 490 : null,
                            child: Toggle(
                              key: UniqueKey(),
                              onText: "Extended pub key",
                              offText: "Single address",
                              onColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .popupBG,
                              offColor: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFieldDefaultBG,
                              isOn: _addressOnly,
                              onValueChanged: (value) {
                                setState(() {
                                  _addressOnly = value;
                                });
                              },
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: isDesktop ? 24 : 16,
                        ),
                        if (!isElectrumX || _addressOnly)
                          FullTextField(
                            key: const Key("viewOnlyAddressRestoreFieldKey"),
                            label: "Address",
                            controller: addressController,
                            onChanged: (newValue) {
                              if (isElectrumX) {
                                viewKeyController.text = "";
                                setState(() {
                                  _enableRestoreButton = newValue.isNotEmpty;
                                });
                              } else {
                                setState(() {
                                  _enableRestoreButton = newValue.isNotEmpty &&
                                      viewKeyController.text.isNotEmpty;
                                });
                              }
                            },
                          ),
                        if (!isElectrumX)
                          SizedBox(
                            height: isDesktop ? 16 : 12,
                          ),
                        if (isElectrumX && !_addressOnly)
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: _currentDropDownValue,
                              items: [
                                ...(widget.coin as Bip39HDCurrency)
                                    .supportedHardenedDerivationPaths
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: STextStyles.w500_14(context),
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: (value) {
                                if (value is String) {
                                  setState(() {
                                    _currentDropDownValue = value;
                                  });
                                }
                              },
                              isExpanded: true,
                              buttonStyleData: ButtonStyleData(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultBG,
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                              ),
                              iconStyleData: IconStyleData(
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: SvgPicture.asset(
                                    Assets.svg.chevronDown,
                                    width: 12,
                                    height: 6,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldActiveSearchIconRight,
                                  ),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                offset: const Offset(0, -10),
                                elevation: 0,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textFieldDefaultBG,
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        if (isElectrumX && !_addressOnly)
                          SizedBox(
                            height: isDesktop ? 16 : 12,
                          ),
                        if (!isElectrumX || !_addressOnly)
                          FullTextField(
                            key: const Key("viewOnlyKeyRestoreFieldKey"),
                            label:
                                "${isElectrumX ? "Extended" : "Private View"} Key",
                            controller: viewKeyController,
                            onChanged: (value) {
                              if (isElectrumX) {
                                addressController.text = "";
                                setState(() {
                                  _enableRestoreButton = value.isNotEmpty;
                                });
                              } else {
                                setState(() {
                                  _enableRestoreButton = value.isNotEmpty &&
                                      addressController.text.isNotEmpty;
                                });
                              }
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

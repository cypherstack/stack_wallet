import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../models/keys/view_only_wallet_data.dart';
import '../../../pages_desktop_specific/desktop_home_view.dart';
import '../../../pages_desktop_specific/my_stack_view/exit_to_my_stack_button.dart';
import '../../../providers/global/secure_store_provider.dart';
import '../../../providers/providers.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/clipboard_interface.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/extended_keys/slip132.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../wallets/crypto_currency/crypto_currency.dart';
import '../../../wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../../wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import '../../../wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import '../../../wallets/isar/models/wallet_info.dart';
import '../../../wallets/wallet/impl/epiccash_wallet.dart';
import '../../../wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import '../../../wallets/wallet/impl/xelis_wallet.dart';
import '../../../wallets/wallet/intermediate/cryptonote_wallet.dart';
import '../../../wallets/wallet/wallet.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import '../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../widgets/desktop/desktop_app_bar.dart';
import '../../../widgets/desktop/desktop_scaffold.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/options.dart';
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
    required this.restoreBlockHeight,
    this.clipboard = const ClipboardWrapper(),
  });

  static const routeName = "/restoreViewOnlyWallet";

  final String walletName;
  final CryptoCurrency coin;
  final int restoreBlockHeight;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<RestoreViewOnlyWalletView> createState() =>
      _RestoreViewOnlyWalletViewState();
}

class _RestoreViewOnlyWalletViewState
    extends ConsumerState<RestoreViewOnlyWalletView> {
  late final TextEditingController addressController;
  late final TextEditingController viewKeyController;
  late final TextEditingController sparkViewKeyController;

  late ViewOnlyWalletType _walletType;

  bool _enableRestoreButton = false;
  bool _buttonLock = false;
  late String _currentDropDownValue;

  /// The initial (unlocked) dropdown selection. Used to restore a sane default
  /// when a previously auto-detected SLIP-0132 prefix is cleared, so a stale
  /// detected script type is never silently reused for a later plain xpub.
  late String _defaultDropDownValue;

  /// When a pasted extended key carries an unambiguous SLIP-0132 prefix
  /// (e.g. `zpub`/`ypub`/`vpub`), the derivation path is determined by that
  /// prefix, not the dropdown. Non-null here means the dropdown is locked to
  /// the detected path so a `zpub` can't be imported as the wrong script type
  /// (which would derive empty addresses and hide the user's funds).
  String? _detectedPathFromKey;

  /// The derivation path implied by [extendedKey]'s SLIP-0132 prefix, matched
  /// to one of the coin's supported hardened paths, or `null` for a plain
  /// `xpub`/`tpub` (ambiguous) or unparseable input — leaving the user's
  /// dropdown selection in place.
  String? _autoPathForExtendedKey(String extendedKey) {
    final coin = widget.coin;
    if (coin is! Bip39HDCurrency) return null;

    final version = Bip39HDCurrency.extendedKeyVersion(extendedKey);
    if (version == null) return null;

    final detected = coin.derivePathTypeForExtendedKeyVersion(version);
    if (detected == null) return null;

    final types = coin.supportedDerivationPathTypes;
    final paths = coin.supportedHardenedDerivationPaths;
    final index = types.indexOf(detected);
    if (index < 0 || index >= paths.length) return null;
    return paths[index];
  }

  /// A human-readable dropdown label for a hardened derivation [path], e.g.
  /// `"zpub — m/84'/0'/0'"`.
  String _labelForPath(String path) {
    final coin = widget.coin;
    if (coin is! Bip39HDCurrency) return path;

    final paths = coin.supportedHardenedDerivationPaths;
    final types = coin.supportedDerivationPathTypes;
    final index = paths.indexOf(path);
    if (index < 0 || index >= types.length) return path;

    final prefix = Slip132.humanPubPrefix(coin.slip132PubVersion(types[index]));
    // Coins with their own HD prefix (e.g. Dogecoin dgub, Particl PPAR) have no
    // known SLIP-0132 human prefix; show the bare path rather than a wrong one.
    return prefix == null ? path : "$prefix — $path";
  }

  /// Handles edits to the pasted extended key: auto-detects the SLIP-0132
  /// script type and keeps [_currentDropDownValue]/[_detectedPathFromKey] in
  /// sync, reverting to [_defaultDropDownValue] when a previously detected
  /// prefix is cleared so a stale script type is never reused on restore.
  void _onExtendedKeyChanged(String value) {
    addressController.text = "";
    final autoPath = _autoPathForExtendedKey(value);
    setState(() {
      _enableRestoreButton = value.isNotEmpty;
      if (autoPath != null) {
        // Unambiguous SLIP-0132 prefix: lock the dropdown to it.
        _currentDropDownValue = autoPath;
      } else if (_detectedPathFromKey != null) {
        // Was locked to a detected prefix; key is now ambiguous/cleared.
        _currentDropDownValue = _defaultDropDownValue;
      }
      _detectedPathFromKey = autoPath;
    });
  }

  Future<void> _requestRestore() async {
    if (_buttonLock) return;
    _buttonLock = true;

    try {
      if (!Util.isDesktop) {
        // wait for keyboard to disappear
        FocusScope.of(context).unfocus();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) {
            return ConfirmRecoveryDialog(onConfirm: _attemptRestore);
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

    ViewOnlyWalletType viewOnlyWalletType = _walletType;
    if (widget.coin is Bip39HDCurrency) {
      // already set above
    } else if (widget.coin is CryptonoteCurrency) {
      viewOnlyWalletType = ViewOnlyWalletType.cryptonote;
    } else if (widget.coin is Xrp) {
      // Account-based watch-only: a single r-address, no view key.
      viewOnlyWalletType = ViewOnlyWalletType.addressOnly;
    } else {
      throw Exception(
        "Unsupported view only wallet currency type found: ${widget.coin.runtimeType}",
      );
    }
    otherDataJson[WalletInfoKeys.viewOnlyTypeIndexKey] = _walletType.index;

    if (!Platform.isLinux && !Util.isDesktop) await WakelockPlus.enable();

    try {
      final info = WalletInfo.createNew(
        coin: widget.coin,
        name: widget.walletName,
        restoreHeight: widget.restoreBlockHeight,
        otherDataJsonString: jsonEncode(otherDataJson),
        overrideAddressType: viewOnlyWalletType == .spark ? .spark : null,
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

                  await ref
                      .read(pWallets)
                      .deleteWallet(info, ref.read(secureStoreProvider));
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
          final pastedKey = viewKeyController.text.trim();
          // The SLIP-0132 prefix, when unambiguous, is authoritative for the
          // script type — override the dropdown so a pasted zpub/ypub/vpub is
          // always stored under the matching path. A plain xpub/tpub is
          // ambiguous, so fall back to the user's dropdown selection.
          final path =
              _autoPathForExtendedKey(pastedKey) ?? _currentDropDownValue;
          viewOnlyData = ExtendedKeysViewOnlyWalletData(
            walletId: info.walletId,
            xPubs: [XPub(path: path, encoded: pastedKey)],
          );
          break;

        case ViewOnlyWalletType.spark:
          if (sparkViewKeyController.text.isEmpty) {
            throw Exception("Spark View Key is empty");
          }
          viewOnlyData = SparkViewOnlyWalletData(
            walletId: info.walletId,
            viewKey: sparkViewKeyController.text,
          );
          break;
      }

      var node = ref
          .read(nodeServiceChangeNotifierProvider)
          .getPrimaryNodeFor(currency: widget.coin);

      if (node == null) {
        node = widget.coin.defaultNode(isPrimary: true);
        await ref
            .read(nodeServiceChangeNotifierProvider)
            .save(node, null, false);
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
        switch (wallet) {
          case EpiccashWallet():
            await wallet.init(isRestore: true);
            break;

          case MimblewimblecoinWallet():
            await wallet.init(isRestore: true);
            break;

          case CryptonoteWallet():
            await wallet.init(isRestore: true);
            break;

          case XelisWallet():
            await wallet.init(isRestore: true);
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

          if (ref.read(pDuress)) {
            await wallet.info.updateDuressVisibilityStatus(
              isDuressVisible: true,
              isar: ref.read(mainDBProvider).isar,
            );
          }

          ref.read(pWallets).addWallet(wallet);

          if (mounted) {
            if (Util.isDesktop) {
              Navigator.of(
                context,
              ).popUntil(ModalRoute.withName(DesktopHomeView.routeName));
            } else {
              unawaited(
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(HomeView.routeName, (route) => false),
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
    sparkViewKeyController = TextEditingController();

    if (widget.coin is Bip39HDCurrency) {
      _currentDropDownValue = (widget.coin as Bip39HDCurrency)
          .supportedHardenedDerivationPaths
          .last;
      _defaultDropDownValue = _currentDropDownValue;
      _walletType = ViewOnlyWalletType.xPub;
    } else if (widget.coin is CryptonoteCurrency) {
      _walletType = ViewOnlyWalletType.cryptonote;
    } else if (widget.coin is Xrp) {
      // Account-based: watch a single r-address (no view key).
      _walletType = ViewOnlyWalletType.addressOnly;
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    viewKeyController.dispose();
    sparkViewKeyController.dispose();
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
                        if (isDesktop) const Spacer(flex: 10),
                        if (!isDesktop)
                          Text(
                            widget.walletName,
                            style: STextStyles.itemSubtitle(context),
                          ),
                        SizedBox(height: isDesktop ? 0 : 4),
                        Text(
                          "Enter view only details",
                          style: isDesktop
                              ? STextStyles.desktopH2(context)
                              : STextStyles.pageTitleH1(context),
                        ),
                        if (isElectrumX) SizedBox(height: isDesktop ? 24 : 16),
                        if (isElectrumX)
                          SizedBox(
                            height: isDesktop ? 56 : 48,
                            width: isDesktop ? 490 : double.infinity,
                            child: Options(
                              key: UniqueKey(),
                              texts: [
                                "Single address",
                                "Extended pub key",
                                if (widget.coin is Firo)
                                  isDesktop ? "Spark View Key" : "View Key",
                              ],
                              onColor: Theme.of(
                                context,
                              ).extension<StackColors>()!.popupBG,
                              offColor: Theme.of(
                                context,
                              ).extension<StackColors>()!.textFieldDefaultBG,
                              selectedIndex: _walletType.index - 1,
                              onValueChanged: (value) {
                                setState(() {
                                  _walletType =
                                      ViewOnlyWalletType.values[value + 1];
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
                        SizedBox(height: isDesktop ? 24 : 16),
                        if (!isElectrumX ||
                            _walletType == ViewOnlyWalletType.addressOnly)
                          FullTextField(
                            key: const Key("viewOnlyAddressRestoreFieldKey"),
                            label: "Address",
                            controller: addressController,
                            onChanged: (newValue) {
                              if (isElectrumX) {
                                viewKeyController.text = "";
                                setState(() {
                                  _enableRestoreButton = newValue.isNotEmpty;
                                  // Key field cleared: drop detection, unlock.
                                  _detectedPathFromKey = null;
                                  _currentDropDownValue = _defaultDropDownValue;
                                });
                              } else {
                                setState(() {
                                  // addressOnly (e.g. XRP): only a valid
                                  // address is required. cryptonote also needs
                                  // a view key.
                                  _enableRestoreButton =
                                      _walletType ==
                                          ViewOnlyWalletType.addressOnly
                                      ? (newValue.isNotEmpty &&
                                            widget.coin.validateAddress(
                                              newValue,
                                            ))
                                      : (newValue.isNotEmpty &&
                                            viewKeyController.text.isNotEmpty);
                                });
                              }
                            },
                          ),
                        if (!isElectrumX) SizedBox(height: isDesktop ? 16 : 12),
                        if (isElectrumX &&
                            _walletType == ViewOnlyWalletType.xPub)
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
                                          _labelForPath(e),
                                          style: STextStyles.w500_14(context),
                                        ),
                                      ),
                                    ),
                              ],
                              // Locked when the pasted key's SLIP-0132 prefix
                              // already determines the script type.
                              onChanged: _detectedPathFromKey != null
                                  ? null
                                  : (value) {
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
                        if (isElectrumX &&
                            _walletType == ViewOnlyWalletType.xPub)
                          SizedBox(height: isDesktop ? 16 : 12),
                        // View key: cryptonote (private view key) or the
                        // ElectrumX xpub. Not shown for address-only (XRP).
                        if (_walletType == ViewOnlyWalletType.cryptonote ||
                            (isElectrumX &&
                                _walletType == ViewOnlyWalletType.xPub))
                          FullTextField(
                            key: const Key("viewOnlyKeyRestoreFieldKey"),
                            label:
                                "${isElectrumX ? "Extended" : "Private View"} Key",
                            controller: viewKeyController,
                            onChanged: (value) {
                              if (isElectrumX) {
                                _onExtendedKeyChanged(value);
                              } else {
                                setState(() {
                                  _enableRestoreButton =
                                      value.isNotEmpty &&
                                      addressController.text.isNotEmpty;
                                });
                              }
                            },
                          ),
                        if (_walletType == ViewOnlyWalletType.spark)
                          SizedBox(height: isDesktop ? 16 : 12),
                        if (_walletType == ViewOnlyWalletType.spark)
                          FullTextField(
                            key: const Key(
                              "viewOnlySparkViewKeyRestoreFieldKey",
                            ),
                            label: "Spark View Key",
                            controller: sparkViewKeyController,
                            onChanged: (value) {
                              setState(() {
                                _enableRestoreButton = value.isNotEmpty;
                              });
                            },
                          ),
                        if (!isDesktop) const Spacer(),
                        SizedBox(height: isDesktop ? 24 : 16),
                        PrimaryButton(
                          enabled: _enableRestoreButton,
                          onPressed: _requestRestore,
                          width: isDesktop ? 480 : null,
                          label: "Restore",
                        ),
                        if (isDesktop) const Spacer(flex: 15),
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

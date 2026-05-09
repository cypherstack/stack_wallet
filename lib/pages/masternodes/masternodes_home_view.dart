import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:tuple/tuple.dart';

import '../../models/send_view_auto_fill_data.dart';
import '../../models/isar/models/blockchain_data/utxo.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/isar/models/wallet_info.dart';
import '../../wallets/wallet/impl/firo_wallet.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stack_dialog.dart';
import '../send_view/send_view.dart';
import 'create_masternode_view.dart';
import 'sub_widgets/masternodes_list.dart';
import 'sub_widgets/masternodes_table_desktop.dart';

class MasternodesHomeView extends ConsumerStatefulWidget {
  const MasternodesHomeView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/masternodesHomeView";

  @override
  ConsumerState<MasternodesHomeView> createState() =>
      _MasternodesHomeViewState();
}

class _MasternodesHomeViewState extends ConsumerState<MasternodesHomeView> {
  static final BigInt _masternodeCollateralRaw = Amount.fromDecimal(
    kMasterNodeValue,
    fractionDigits: 8,
  ).raw;

  late Future<List<MasternodeInfo>> _masternodesFuture;
  bool _hasPromptedForCollateral = false;
  bool _isCheckingForCollateral = false;

  Set<String> _dismissedCollateral(FiroWallet wallet) {
    final raw =
        wallet.info.otherData[WalletInfoKeys.firoMasternodeCollateralDismissed];
    if (raw is! List) {
      return {};
    }
    return raw.whereType<String>().toSet();
  }

  Future<void> _persistDismissedCollateral(
    FiroWallet wallet,
    String txid,
    int vout,
  ) async {
    final set = _dismissedCollateral(wallet);
    set.add("$txid:$vout");
    await wallet.info.updateOtherData(
      newEntries: {
        WalletInfoKeys.firoMasternodeCollateralDismissed: set.toList(),
      },
      isar: wallet.mainDB.isar,
    );
  }

  Future<({String txid, int vout, String address})?>
  _findCollateralUtxo() async {
    final wallet = ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
    final List<UTXO> utxos = await wallet.mainDB
        .getUTXOs(widget.walletId)
        .findAll();
    final currentChainHeight = await wallet.chainHeight;
    final masternodeRaw = Amount.fromDecimal(
      kMasterNodeValue,
      fractionDigits: wallet.cryptoCurrency.fractionDigits,
    ).raw.toInt();

    for (final utxo in utxos) {
      if (utxo.value == masternodeRaw &&
          !utxo.isBlocked &&
          utxo.used != true &&
          utxo.isConfirmed(
            currentChainHeight,
            wallet.cryptoCurrency.minConfirms,
            wallet.cryptoCurrency.minCoinbaseConfirms,
          ) &&
          utxo.address != null) {
        return (txid: utxo.txid, vout: utxo.vout, address: utxo.address!);
      }
    }
    return null;
  }

  Future<
    ({String txid, int vout, String address, int confirmations, int required})?
  >
  _findPendingCollateralUtxo() async {
    final wallet = ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
    final List<UTXO> utxos = await wallet.mainDB
        .getUTXOs(widget.walletId)
        .findAll();
    final currentChainHeight = await wallet.chainHeight;
    final requiredConfirms = wallet.cryptoCurrency.minConfirms;
    final masternodeRaw = Amount.fromDecimal(
      kMasterNodeValue,
      fractionDigits: wallet.cryptoCurrency.fractionDigits,
    ).raw.toInt();

    ({String txid, int vout, String address, int confirmations, int required})?
    bestPending;

    for (final utxo in utxos) {
      if (utxo.value != masternodeRaw ||
          utxo.isBlocked ||
          utxo.used == true ||
          utxo.address == null) {
        continue;
      }

      final confirmations = utxo.getConfirmations(currentChainHeight);
      final isConfirmed = utxo.isConfirmed(
        currentChainHeight,
        wallet.cryptoCurrency.minConfirms,
        wallet.cryptoCurrency.minCoinbaseConfirms,
      );

      if (isConfirmed) {
        continue;
      }

      final candidate = (
        txid: utxo.txid,
        vout: utxo.vout,
        address: utxo.address!,
        confirmations: confirmations,
        required: requiredConfirms,
      );

      if (bestPending == null ||
          candidate.confirmations > bestPending.confirmations) {
        bestPending = candidate;
      }
    }

    return bestPending;
  }

  Future<void> _createMasternode() async {
    final wallet = ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
    final collateral = await _findCollateralUtxo();
    if (!mounted) {
      return;
    }

    if (collateral == null) {
      final pendingCollateral = await _findPendingCollateralUtxo();
      if (!mounted) {
        return;
      }
      if (pendingCollateral != null) {
        final message =
            "Your 1000 FIRO collateral is on its way.\n\n"
            "Waiting for confirmations...\n"
            "Once confirmed, click Create Masternode again to continue.";
        await showDialog<void>(
          context: context,
          builder: (ctx) => StackOkDialog(
            title: "Waiting for collateral confirmation",
            message: message,
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 420 : null,
          ),
        );
        return;
      }

      final spendableBalance = wallet.info.cachedBalance.spendable.raw;
      if (spendableBalance < _masternodeCollateralRaw) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => StackOkDialog(
            title: "Not enough FIRO to create the collateral",
            message:
                "A masternode collateral is exactly 1000 FIRO on your transparent balance, plus a "
                "small network fee to send it. Your spendable transparent balance is "
                "below this amount.\n\n"
                "Add more FIRO to your wallet, then click Create "
                "Masternode again to continue.",
            desktopPopRootNavigator: Util.isDesktop,
            maxWidth: Util.isDesktop ? 420 : null,
          ),
        );
        return;
      }

      if (Util.isDesktop) {
        final shouldOpenSend = await showDialog<bool>(
          context: context,
          builder: (ctx) => StackDialog(
            title: "Set up your 1000 FIRO masternode collateral?",
            message:
                "Registering a masternode requires a 1000 FIRO collateral: "
                "a single confirmed amount sitting in your wallet. We didn't "
                "find one, but you have enough FIRO to create it.\n\n"
                "We can help by opening the Send window with a new address "
                "you own pre-filled, ready for you to send 1000 FIRO to it. "
                "This consolidates your smaller amounts into the single 1000 "
                "FIRO collateral you need. The network fee is paid from your "
                "remaining balance.\n\n"
                "Once you have sent it, wait for the transaction to confirm, "
                "then click Create Masternode again to continue.",
            leftButton: TextButton(
              style: Theme.of(
                ctx,
              ).extension<StackColors>()!.getSecondaryEnabledButtonStyle(ctx),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "Cancel",
                style: STextStyles.button(ctx).copyWith(
                  color: Theme.of(
                    ctx,
                  ).extension<StackColors>()!.accentColorDark,
                ),
              ),
            ),
            rightButton: TextButton(
              style: Theme.of(
                ctx,
              ).extension<StackColors>()!.getPrimaryEnabledButtonStyle(ctx),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text("Open Send", style: STextStyles.button(ctx)),
            ),
          ),
        );
        if (shouldOpenSend == true && mounted) {
          await _openCreateCollateralSendFlow(wallet);
        }
      } else {
        await _openCreateCollateralSendFlow(wallet);
      }
      return;
    }

    if (Util.isDesktop) {
      final txid = await showDialog<Object>(
        context: context,
        barrierDismissible: true,
        builder: (context) => SDialog(
          child: CreateMasternodeView(
            firoWalletId: widget.walletId,
            collateralTxid: collateral.txid,
            collateralVout: collateral.vout,
            collateralAddress: collateral.address,
          ),
        ),
      );
      _handleSuccessTxid(txid);
    } else {
      final txid = await Navigator.of(context).pushNamed(
        CreateMasternodeView.routeName,
        arguments: {
          'walletId': widget.walletId,
          'collateralTxid': collateral.txid,
          'collateralVout': collateral.vout,
          'collateralAddress': collateral.address,
        },
      );
      _handleSuccessTxid(txid);
    }
  }

  Future<void> _openCreateCollateralSendFlow(FiroWallet wallet) async {
    var selfAddress = await wallet.getCurrentReceivingAddress();
    if (selfAddress == null) {
      await wallet.generateNewReceivingAddress();
      selfAddress = await wallet.getCurrentReceivingAddress();
    }
    if (!mounted || selfAddress == null) {
      return;
    }

    await Navigator.of(context).pushNamed(
      SendView.routeName,
      arguments: Tuple3(
        widget.walletId,
        wallet.cryptoCurrency,
        SendViewAutoFillData(
          address: selfAddress.value,
          contactLabel: "My FIRO address",
          amount: kMasterNodeValue,
          note: "Masternode collateral prep (1000 FIRO self-send).",
        ),
      ),
    );
  }

  Future<void> _maybePromptForExistingCollateral() async {
    if (_hasPromptedForCollateral || _isCheckingForCollateral || !mounted) {
      return;
    }
    _isCheckingForCollateral = true;

    try {
      final collateral = await _findCollateralUtxo();
      if (collateral == null || !mounted) {
        return;
      }

      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
      final dismissed = _dismissedCollateral(wallet);
      final collateralKey = "${collateral.txid}:${collateral.vout}";
      if (dismissed.contains(collateralKey)) {
        return;
      }

      _hasPromptedForCollateral = true;

      final wantsMN = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => StackDialog(
          title: "Register Masternode?",
          message:
              "A 1000 FIRO collateral UTXO was found in your wallet. "
              "Would you like to register a masternode now?",
          leftButton: TextButton(
            style: Theme.of(
              ctx,
            ).extension<StackColors>()!.getSecondaryEnabledButtonStyle(ctx),
            child: Text(
              "Later",
              style: STextStyles.button(ctx).copyWith(
                color: Theme.of(ctx).extension<StackColors>()!.accentColorDark,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          rightButton: TextButton(
            style: Theme.of(
              ctx,
            ).extension<StackColors>()!.getPrimaryEnabledButtonStyle(ctx),
            child: Text("Register", style: STextStyles.button(ctx)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ),
      );

      if (wantsMN == false || wantsMN == null) {
        await _persistDismissedCollateral(
          wallet,
          collateral.txid,
          collateral.vout,
        );
      }

      if (wantsMN != true || !mounted) {
        return;
      }

      if (Util.isDesktop) {
        final txid = await showDialog<Object>(
          context: context,
          barrierDismissible: true,
          builder: (context) => SDialog(
            child: CreateMasternodeView(
              firoWalletId: widget.walletId,
              collateralTxid: collateral.txid,
              collateralVout: collateral.vout,
              collateralAddress: collateral.address,
            ),
          ),
        );
        _handleSuccessTxid(txid);
      } else {
        final txid = await Navigator.of(context).pushNamed(
          CreateMasternodeView.routeName,
          arguments: {
            'walletId': widget.walletId,
            'collateralTxid': collateral.txid,
            'collateralVout': collateral.vout,
            'collateralAddress': collateral.address,
          },
        );
        _handleSuccessTxid(txid);
      }
    } finally {
      _isCheckingForCollateral = false;
    }
  }

  void _handleSuccessTxid(Object? txid) {
    Logging.instance.i(
      "$runtimeType _handleSuccessTxid($txid) called where mounted=$mounted",
    );
    if (mounted && txid is String) {
      setState(() {
        _masternodesFuture =
            (ref.read(pWallets).getWallet(widget.walletId) as FiroWallet)
                .getMyMasternodes();
      });

      showDialog<void>(
        context: context,
        builder: (_) => StackOkDialog(
          title: "Masternode Registration Submitted",
          message:
              "Masternode registration submitted, your masternode will "
              "appear in the list after the tx is confirmed.\n\nTransaction"
              " ID: $txid",
          desktopPopRootNavigator: Util.isDesktop,
          maxWidth: Util.isDesktop ? 400 : null,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _masternodesFuture =
        (ref.read(pWallets).getWallet(widget.walletId) as FiroWallet)
            .getMyMasternodes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePromptForExistingCollateral());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 20),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.topNavIconPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.robotHead,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).extension<StackColors>()!.textDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("Masternodes", style: STextStyles.desktopH3(context)),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: PrimaryButton(
                  label: "Create Masternode",
                  buttonHeight: .l,
                  horizontalContentPadding: 10,
                  icon: SvgPicture.asset(
                    Assets.svg.circlePlus,
                    colorFilter: ColorFilter.mode(
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.buttonTextPrimary,
                      .srcIn,
                    ),
                  ),
                  onPressed: _createMasternode,
                ),
              ),
            )
          : AppBar(
              leading: AppBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              titleSpacing: 0,
              title: Text(
                "Masternodes",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
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
                      key: const Key("createNewMasterNodeButton"),
                      size: 36,
                      shadows: const [],
                      color: Theme.of(
                        context,
                      ).extension<StackColors>()!.background,
                      icon: SvgPicture.asset(
                        Assets.svg.plus,
                        colorFilter: ColorFilter.mode(
                          Theme.of(
                            context,
                          ).extension<StackColors>()!.accentColorDark,
                          .srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                      onPressed: _createMasternode,
                    ),
                  ),
                ),
              ],
            ),
      body: FutureBuilder<List<MasternodeInfo>>(
        future: _masternodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator(height: 50, width: 50));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load masternodes",
                style: STextStyles.w600_14(context),
              ),
            );
          }
          final nodes = snapshot.data ?? const <MasternodeInfo>[];
          if (nodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No masternodes found",
                    style: STextStyles.w600_14(context),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    children: [
                      PrimaryButton(
                        label: "Create Your First Masternode",
                        horizontalContentPadding: 16,
                        buttonHeight: Util.isDesktop ? .l : null,
                        onPressed: _createMasternode,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (Util.isDesktop) {
            return MasternodesTableDesktop(nodes: nodes);
          } else {
            return MasternodesList(nodes: nodes);
          }
        },
      ),
    );
  }
}

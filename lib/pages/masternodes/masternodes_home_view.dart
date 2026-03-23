import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import '../../providers/global/wallets_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../wallets/wallet/impl/firo_wallet.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stack_dialog.dart';
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

class _MasternodesHomeViewState extends ConsumerState<MasternodesHomeView>
    with WidgetsBindingObserver {
  late Future<List<MasternodeInfo>> _masternodesFuture;
  bool _hasPromptedForCollateral = false;
  bool _isCheckingForCollateral = false;

  Future<({String txid, int vout, String address})?> _findCollateralUtxo()
      async {
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as FiroWallet;
    final utxos = await wallet.mainDB.getUTXOs(widget.walletId).findAll();
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

  Future<void> _createMasternode() async {
    final collateral = await _findCollateralUtxo();
    if (!mounted) {
      return;
    }

    if (collateral == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => StackOkDialog(
          title: "No collateral found",
          message:
              "A masternode needs one confirmed, unblocked transparent "
              "UTXO of exactly 1000 FIRO.\n\n"
              "Total balance above 1000 FIRO is not enough if no single "
              "1000 output exists. Also ensure fee is not subtracted from "
              "the recipient amount when sending to yourself.",
          desktopPopRootNavigator: Util.isDesktop,
          maxWidth: Util.isDesktop ? 400 : null,
        ),
      );
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
            style: Theme.of(ctx)
                .extension<StackColors>()!
                .getSecondaryEnabledButtonStyle(ctx),
            child: Text(
              "Later",
              style: STextStyles.button(
                ctx,
              ).copyWith(
                color: Theme.of(ctx).extension<StackColors>()!.accentColorDark,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          rightButton: TextButton(
            style: Theme.of(ctx)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonStyle(ctx),
            child: Text(
              "Register",
              style: STextStyles.button(ctx),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ),
      );

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
    WidgetsBinding.instance.addObserver(this);

    // TODO polling and update on successful registration
    _masternodesFuture =
        (ref.read(pWallets).getWallet(widget.walletId) as FiroWallet)
            .getMyMasternodes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePromptForExistingCollateral());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybePromptForExistingCollateral());
    }
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

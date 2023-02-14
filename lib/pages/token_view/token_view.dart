import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/tokens/ethereum/ethereum_token.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

/// [eventBus] should only be set during testing
class TokenView extends ConsumerStatefulWidget {
  const TokenView({
    Key? key,
    required this.walletId,
    required this.tokenData,
    required this.managerProvider,
    required this.token,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/token";
  static const double navBarHeight = 65.0;

  final String walletId;
  final Map<dynamic, dynamic> tokenData;
  final ChangeNotifierProvider<Manager> managerProvider;
  final EthereumToken token;
  final EventBus? eventBus;

  @override
  ConsumerState<TokenView> createState() => _TokenViewState();
}

class _TokenViewState extends ConsumerState<TokenView> {
  late final EventBus eventBus;
  late final String walletId;
  late final ChangeNotifierProvider<Manager> managerProvider;

  late final bool _shouldDisableAutoSyncOnLogOut;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;

    ref.read(managerProvider).isActiveWallet = true;
    if (!ref.read(managerProvider).shouldAutoSync) {
      // enable auto sync if it wasn't enabled when loading wallet
      ref.read(managerProvider).shouldAutoSync = true;
      _shouldDisableAutoSyncOnLogOut = true;
    } else {
      _shouldDisableAutoSyncOnLogOut = false;
    }

    ref.read(managerProvider).refresh();

    if (ref.read(managerProvider).isRefreshing) {
      _currentSyncStatus = WalletSyncStatus.syncing;
      _currentNodeStatus = NodeConnectionStatus.connected;
    } else {
      _currentSyncStatus = WalletSyncStatus.synced;
      if (ref.read(managerProvider).isConnected) {
        _currentNodeStatus = NodeConnectionStatus.connected;
      } else {
        _currentNodeStatus = NodeConnectionStatus.disconnected;
        _currentSyncStatus = WalletSyncStatus.unableToSync;
      }
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

    _syncStatusSubscription =
        eventBus.on<WalletSyncStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          // switch (event.newStatus) {
          //   case WalletSyncStatus.unableToSync:
          //     break;
          //   case WalletSyncStatus.synced:
          //     break;
          //   case WalletSyncStatus.syncing:
          //     break;
          // }
          setState(() {
            _currentSyncStatus = event.newStatus;
          });
        }
      },
    );

    _nodeStatusSubscription =
        eventBus.on<NodeConnectionStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          // switch (event.newStatus) {
          //   case NodeConnectionStatus.disconnected:
          //     break;
          //   case NodeConnectionStatus.connected:
          //     break;
          // }
          setState(() {
            _currentNodeStatus = event.newStatus;
          });
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _nodeStatusSubscription.cancel();
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  DateTime? _cachedTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const timeout = Duration(milliseconds: 1500);
    if (_cachedTime == null || now.difference(_cachedTime!) > timeout) {
      _cachedTime = now;
      unawaited(showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async {
            Navigator.of(context).popUntil(
              ModalRoute.withName(HomeView.routeName),
            );
            _logout();
            return false;
          },
          child: const StackDialog(title: "Tap back again to exit wallet"),
        ),
      ).timeout(
        timeout,
        onTimeout: () => Navigator.of(context).popUntil(
          ModalRoute.withName(TokenView.routeName),
        ),
      ));
    }
    return false;
  }

  void _logout() async {
    if (_shouldDisableAutoSyncOnLogOut) {
      // disable auto sync if it was enabled only when loading wallet
      ref.read(managerProvider).shouldAutoSync = false;
    }
    ref.read(managerProvider.notifier).isActiveWallet = false;
    ref.read(transactionFilterProvider.state).state = null;
    if (ref.read(prefsChangeNotifierProvider).isAutoBackupEnabled &&
        ref.read(prefsChangeNotifierProvider).backupFrequencyType ==
            BackupFrequencyType.afterClosingAWallet) {
      unawaited(ref.read(autoSWBServiceProvider).doBackup());
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    widget.token.initializeExisting();
    // print("MY TOTAL BALANCE IS ${widget.token.totalBalance}");

    final coin = ref.watch(managerProvider.select((value) => value.coin));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.iconFor(coin: coin),
                  // color: Theme.of(context).extension<StackColors>()!.accentColorDark
                  width: 24,
                  height: 24,
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Text(
                    widget.tokenData["name"] as String,
                    style: STextStyles.navBarTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    ref.watch(
                        managerProvider.select((value) => value.coin.ticker)),
                    style: STextStyles.navBarTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          body: SafeArea(
            child: Container(
              color: Theme.of(context).extension<StackColors>()!.background,
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TokenSummary(
                        walletId: walletId,
                        managerProvider: managerProvider,
                        initialSyncStatus: ref.watch(managerProvider
                                .select((value) => value.isRefreshing))
                            ? WalletSyncStatus.syncing
                            : WalletSyncStatus.synced,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transactions",
                          style: STextStyles.itemSubtitle(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark3,
                          ),
                        ),
                        CustomTextButton(
                          text: "See all",
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AllTransactionsView.routeName,
                              arguments: walletId,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                                bottom: Radius.circular(
                                  // TokenView.navBarHeight / 2.0,
                                  Constants.size.circularBorderRadius,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Constants.size.circularBorderRadius,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: TransactionsList(
                                        managerProvider: managerProvider,
                                        walletId: walletId,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Padding(
                                //   padding: const EdgeInsets.only(
                                //     bottom: 14,
                                //     left: 16,
                                //     right: 16,
                                //   ),
                                //   child: SizedBox(
                                //     height: TokenView.navBarHeight,
                                //     child: WalletNavigationBar(
                                //       enableExchange:
                                //           Constants.enableExchange &&
                                //               ref.watch(managerProvider.select(
                                //                       (value) => value.coin)) !=
                                //                   Coin.epicCash,
                                //       height: TokenView.navBarHeight,
                                //       onExchangePressed: () =>
                                //           _onExchangePressed(context),
                                //       onReceivePressed: () async {
                                //         final coin =
                                //             ref.read(managerProvider).coin;
                                //         if (mounted) {
                                //           unawaited(
                                //               Navigator.of(context).pushNamed(
                                //             ReceiveView.routeName,
                                //             arguments: Tuple2(
                                //               walletId,
                                //               coin,
                                //             ),
                                //           ));
                                //         }
                                //       },
                                //       onSendPressed: () {
                                //         final walletId =
                                //             ref.read(managerProvider).walletId;
                                //         final coin =
                                //             ref.read(managerProvider).coin;
                                //         switch (ref
                                //             .read(
                                //                 walletBalanceToggleStateProvider
                                //                     .state)
                                //             .state) {
                                //           case WalletBalanceToggleState.full:
                                //             ref
                                //                 .read(
                                //                     publicPrivateBalanceStateProvider
                                //                         .state)
                                //                 .state = "Public";
                                //             break;
                                //           case WalletBalanceToggleState
                                //               .available:
                                //             ref
                                //                 .read(
                                //                     publicPrivateBalanceStateProvider
                                //                         .state)
                                //                 .state = "Private";
                                //             break;
                                //         }
                                //         Navigator.of(context).pushNamed(
                                //           SendView.routeName,
                                //           arguments: Tuple2(
                                //             walletId,
                                //             coin,
                                //           ),
                                //         );
                                //       },
                                //       onBuyPressed: () {},
                                //       onTokensPressed: () async {
                                //         final walletAddress = await ref
                                //             .read(managerProvider)
                                //             .currentReceivingAddress;
                                //
                                //         List<dynamic> tokens =
                                //             await getWalletTokens(await ref
                                //                 .read(managerProvider)
                                //                 .currentReceivingAddress);
                                //
                                //         await Navigator.of(context).pushNamed(
                                //           MyTokensView.routeName,
                                //           arguments: Tuple4(managerProvider,
                                //               walletId, walletAddress, tokens),
                                //         );
                                //       },
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

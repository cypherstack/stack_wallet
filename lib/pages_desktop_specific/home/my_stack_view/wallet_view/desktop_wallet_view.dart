import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/wallet_initiated_exchange_view.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_network_settings_view/wallet_network_settings_view.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/desktop_wallet_summary.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/receive/desktop_receive.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/send/desktop_send.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/transaction_filter_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

/// [eventBus] should only be set during testing
class DesktopWalletView extends ConsumerStatefulWidget {
  const DesktopWalletView({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  static const String routeName = "/desktopWalletView";

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<DesktopWalletView> createState() => _DesktopWalletViewState();
}

class _DesktopWalletViewState extends ConsumerState<DesktopWalletView> {
  late final String walletId;
  late final EventBus eventBus;

  late final bool _shouldDisableAutoSyncOnLogOut;

  final _cnLoadingService = ExchangeDataLoadingService();

  Future<void> onBackPressed() async {
    await _logout();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);
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

  void _loadCNData() {
    // unawaited future
    if (ref.read(prefsChangeNotifierProvider).externalCalls) {
      _cnLoadingService.loadAll(ref,
          coin: ref
              .read(walletsChangeNotifierProvider)
              .getManager(walletId)
              .coin);
    } else {
      Logging.instance.log("User does not want to use external calls",
          level: LogLevel.Info);
    }
  }

  void _onExchangePressed(BuildContext context) async {
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);
    unawaited(_cnLoadingService.loadAll(ref));

    final coin = ref.read(managerProvider).coin;

    if (coin == Coin.epicCash) {
      await showDialog<void>(
        context: context,
        builder: (_) => const StackOkDialog(
          title: "Exchange not available for Epic Cash",
        ),
      );
    } else if (coin.name.endsWith("TestNet")) {
      await showDialog<void>(
        context: context,
        builder: (_) => const StackOkDialog(
          title: "Exchange not available for test net coins",
        ),
      );
    } else {
      ref.read(currentExchangeNameStateProvider.state).state =
          ChangeNowExchange.exchangeName;
      final walletId = ref.read(managerProvider).walletId;
      ref.read(prefsChangeNotifierProvider).exchangeRateType =
          ExchangeRateType.estimated;

      ref.read(exchangeFormStateProvider).exchange = ref.read(exchangeProvider);
      ref.read(exchangeFormStateProvider).exchangeType =
          ExchangeRateType.estimated;

      final currencies = ref
          .read(availableChangeNowCurrenciesProvider)
          .currencies
          .where((element) =>
              element.ticker.toLowerCase() == coin.ticker.toLowerCase());

      if (currencies.isNotEmpty) {
        ref.read(exchangeFormStateProvider).setCurrencies(
              currencies.first,
              ref
                  .read(availableChangeNowCurrenciesProvider)
                  .currencies
                  .firstWhere(
                    (element) =>
                        element.ticker.toLowerCase() !=
                        coin.ticker.toLowerCase(),
                  ),
            );
      }

      if (mounted) {
        unawaited(
          Navigator.of(context).pushNamed(
            WalletInitiatedExchangeView.routeName,
            arguments: Tuple3(
              walletId,
              coin,
              _loadCNData,
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

    ref.read(managerProvider).isActiveWallet = true;
    if (!ref.read(managerProvider).shouldAutoSync) {
      // enable auto sync if it wasn't enabled when loading wallet
      ref.read(managerProvider).shouldAutoSync = true;
      _shouldDisableAutoSyncOnLogOut = true;
    } else {
      _shouldDisableAutoSyncOnLogOut = false;
    }

    ref.read(managerProvider).refresh();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));
    final coin = manager.coin;
    final managerProvider = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManagerProvider(walletId)));

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Row(
          children: [
            const SizedBox(
              width: 32,
            ),
            AppBarIconButton(
              size: 32,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldDefaultBG,
              shadows: const [],
              icon: SvgPicture.asset(
                Assets.svg.arrowLeft,
                width: 18,
                height: 18,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .topNavIconPrimary,
              ),
              onPressed: onBackPressed,
            ),
            const SizedBox(
              width: 15,
            ),
            SvgPicture.asset(
              Assets.svg.iconFor(coin: coin),
              width: 32,
              height: 32,
            ),
            const SizedBox(
              width: 12,
            ),
            Text(
              manager.walletName,
              style: STextStyles.desktopH3(context),
            ),
          ],
        ),
        trailing: Row(
          children: [
            NetworkInfoButton(
              walletId: walletId,
              eventBus: eventBus,
            ),
            const SizedBox(
              width: 32,
            ),
            const WalletKeysButton(),
            const SizedBox(
              width: 32,
            ),
          ],
        ),
        isCompactHeight: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.iconFor(coin: coin),
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  DesktopWalletSummary(
                    walletId: walletId,
                    managerProvider: managerProvider,
                    initialSyncStatus: ref.watch(managerProvider
                            .select((value) => value.isRefreshing))
                        ? WalletSyncStatus.syncing
                        : WalletSyncStatus.synced,
                  ),
                  const Spacer(),
                  SecondaryButton(
                    width: 180,
                    desktopMed: true,
                    onPressed: () {
                      _onExchangePressed(context);
                    },
                    label: "Exchange",
                    icon: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackPrimary
                            .withOpacity(0.2),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          Assets.svg.arrowRotate2,
                          width: 14,
                          height: 14,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 450,
                    child: MyWallet(
                      walletId: walletId,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: RecentDesktopTransactions(
                      walletId: walletId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyWallet extends StatefulWidget {
  const MyWallet({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  State<MyWallet> createState() => _MyWalletState();
}

class _MyWalletState extends State<MyWallet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          "My wallet",
          style: STextStyles.desktopTextExtraSmall(context).copyWith(
            color: Theme.of(context)
                .extension<StackColors>()!
                .textFieldActiveSearchIconLeft,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
          ),
          child: SendReceiveTabMenu(
            onChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
          ),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              Padding(
                key: const Key("desktopSendViewPortKey"),
                padding: const EdgeInsets.all(20),
                child: DesktopSend(
                  walletId: widget.walletId,
                ),
              ),
              Padding(
                key: const Key("desktopReceiveViewPortKey"),
                padding: const EdgeInsets.all(20),
                child: DesktopReceive(
                  walletId: widget.walletId,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SendReceiveTabMenu extends StatefulWidget {
  const SendReceiveTabMenu({
    Key? key,
    this.initialIndex = 0,
    this.onChanged,
  }) : super(key: key);

  final int initialIndex;
  final void Function(int)? onChanged;

  @override
  State<SendReceiveTabMenu> createState() => _SendReceiveTabMenuState();
}

class _SendReceiveTabMenuState extends State<SendReceiveTabMenu> {
  late int _selectedIndex;

  void _onChanged(int newIndex) {
    if (_selectedIndex != newIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      widget.onChanged?.call(_selectedIndex);
    }
  }

  @override
  void initState() {
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onChanged(0),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    "Send",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: _selectedIndex == 0
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                  ),
                  const SizedBox(
                    height: 19,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _onChanged(1),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    "Receive",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color: _selectedIndex == 1
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                    ),
                  ),
                  const SizedBox(
                    height: 19,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .accentColorBlue
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecentDesktopTransactions extends ConsumerStatefulWidget {
  const RecentDesktopTransactions({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<RecentDesktopTransactions> createState() =>
      _RecentDesktopTransactionsState();
}

class _RecentDesktopTransactionsState
    extends ConsumerState<RecentDesktopTransactions> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent transactions",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveSearchIconLeft,
              ),
            ),
            BlueTextButton(
              text: "See all",
              onTap: () {
                Navigator.of(context).pushNamed(
                  AllTransactionsView.routeName,
                  arguments: widget.walletId,
                );
              },
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Expanded(
          child: TransactionsList(
            managerProvider: ref.watch(walletsChangeNotifierProvider
                .select((value) => value.getManagerProvider(widget.walletId))),
            walletId: widget.walletId,
          ),
        ),
      ],
    );
  }
}

class NetworkInfoButton extends ConsumerStatefulWidget {
  const NetworkInfoButton({
    Key? key,
    required this.walletId,
    this.eventBus,
  }) : super(key: key);

  final String walletId;
  final EventBus? eventBus;

  @override
  ConsumerState<NetworkInfoButton> createState() => _NetworkInfoButtonState();
}

class _NetworkInfoButtonState extends ConsumerState<NetworkInfoButton> {
  late final String walletId;
  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;
  late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _syncStatusSubscription;
  late StreamSubscription<dynamic> _nodeStatusSubscription;

  @override
  void initState() {
    walletId = widget.walletId;
    final managerProvider =
        ref.read(walletsChangeNotifierProvider).getManagerProvider(walletId);

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

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

    _syncStatusSubscription =
        eventBus.on<WalletSyncStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
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

  Widget _buildNetworkIcon(WalletSyncStatus status, BuildContext context) {
    const size = 24.0;
    switch (status) {
      case WalletSyncStatus.unableToSync:
        return SvgPicture.asset(
          Assets.svg.radioProblem,
          color: Theme.of(context).extension<StackColors>()!.accentColorRed,
          width: size,
          height: size,
        );
      case WalletSyncStatus.synced:
        return SvgPicture.asset(
          Assets.svg.radio,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
          width: size,
          height: size,
        );
      case WalletSyncStatus.syncing:
        return SvgPicture.asset(
          Assets.svg.radioSyncing,
          color: Theme.of(context).extension<StackColors>()!.accentColorYellow,
          width: size,
          height: size,
        );
    }
  }

  Widget _buildText(WalletSyncStatus status, BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case WalletSyncStatus.unableToSync:
        label = "Unable to sync";
        color = Theme.of(context).extension<StackColors>()!.accentColorRed;
        break;
      case WalletSyncStatus.synced:
        label = "Synchronised";
        color = Theme.of(context).extension<StackColors>()!.accentColorGreen;
        break;
      case WalletSyncStatus.syncing:
        label = "Synchronising";
        color = Theme.of(context).extension<StackColors>()!.accentColorYellow;
        break;
    }

    return Text(
      label,
      style: STextStyles.desktopMenuItemSelected(context).copyWith(
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          WalletNetworkSettingsView.routeName,
          arguments: Tuple3(
            walletId,
            _currentSyncStatus,
            _currentNodeStatus,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            _buildNetworkIcon(_currentSyncStatus, context),
            const SizedBox(
              width: 6,
            ),
            _buildText(_currentSyncStatus, context),
          ],
        ),
      ),
    );
  }
}

class WalletKeysButton extends StatelessWidget {
  const WalletKeysButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.key,
              width: 20,
              height: 20,
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextSecondary,
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              "Wallet keys",
              style: STextStyles.desktopMenuItemSelected(context),
            )
          ],
        ),
      ),
    );
  }
}

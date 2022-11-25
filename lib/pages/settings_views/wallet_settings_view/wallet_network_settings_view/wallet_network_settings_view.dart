import 'dart:async';
import 'dart:io';

import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicmobile/pages/settings_views/sub_widgets/nodes_list.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_network_settings_view/sub_widgets/confirm_full_rescan.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_network_settings_view/sub_widgets/rescanning_dialog.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart';
import 'package:epicmobile/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:epicmobile/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/global_event_bus.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/utilities/util.dart';
import 'package:epicmobile/widgets/animated_text.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/conditional_parent.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/custom_buttons/blue_text_button.dart';
import 'package:epicmobile/widgets/expandable.dart';
import 'package:epicmobile/widgets/progress_bar.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';
import 'package:wakelock/wakelock.dart';

/// [eventBus] should only be set during testing
class WalletNetworkSettingsView extends ConsumerStatefulWidget {
  const WalletNetworkSettingsView({
    Key? key,
    required this.walletId,
    required this.initialSyncStatus,
    required this.initialNodeStatus,
    this.eventBus,
  }) : super(key: key);

  final String walletId;
  final WalletSyncStatus initialSyncStatus;
  final NodeConnectionStatus initialNodeStatus;
  final EventBus? eventBus;

  static const String routeName = "/walletNetworkSettings";

  @override
  ConsumerState<WalletNetworkSettingsView> createState() =>
      _WalletNetworkSettingsViewState();
}

class _WalletNetworkSettingsViewState
    extends ConsumerState<WalletNetworkSettingsView> {
  final double _padding = 16;
  final double _boxPadding = 12;
  final double _iconSize = Util.isDesktop ? 40 : 28;

  late final EventBus eventBus;

  late WalletSyncStatus _currentSyncStatus;
  // late NodeConnectionStatus _currentNodeStatus;

  late StreamSubscription<dynamic> _refreshSubscription;
  late StreamSubscription<dynamic> _syncStatusSubscription;
  StreamSubscription<dynamic>? _blocksRemainingSubscription;
  // late StreamSubscription _nodeStatusSubscription;

  late double _percent;
  late int _blocksRemaining;
  bool _advancedIsExpanded = true;

  Future<void> _attemptRescan() async {
    if (!Platform.isLinux) await Wakelock.enable();

    int maxUnusedAddressGap = 20;

    const int maxNumberOfIndexesToCheck = 1000;

    unawaited(
      showDialog<dynamic>(
        context: context,
        useSafeArea: false,
        barrierDismissible: false,
        builder: (context) => const RescanningDialog(),
      ),
    );

    try {
      await ref
          .read(walletsChangeNotifierProvider)
          .getManager(widget.walletId)
          .fullRescan(
            maxUnusedAddressGap,
            maxNumberOfIndexesToCheck,
          );

      if (mounted) {
        // pop rescanning dialog
        Navigator.pop(context);

        // show success
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) => StackDialog(
            title: "Rescan completed",
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonColor(context),
              child: Text(
                "Ok",
                style: STextStyles.itemSubtitle12(context),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!Platform.isLinux) await Wakelock.disable();

      if (mounted) {
        // pop rescanning dialog
        Navigator.pop(context);

        // show error
        await showDialog<dynamic>(
          context: context,
          useSafeArea: false,
          barrierDismissible: true,
          builder: (context) => StackDialog(
            title: "Rescan failed",
            message: e.toString(),
            rightButton: TextButton(
              style: Theme.of(context)
                  .extension<StackColors>()!
                  .getSecondaryEnabledButtonColor(context),
              child: Text(
                "Ok",
                style: STextStyles.itemSubtitle12(context),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    }

    if (!Platform.isLinux) await Wakelock.disable();
  }

  String _percentString(double value) {
    double realPercent = (value * 10000).ceil().clamp(0, 10000) / 100.0;
    if (realPercent > 99.99 && _currentSyncStatus == WalletSyncStatus.syncing) {
      return "99.99%";
    }
    return "${realPercent.toStringAsFixed(2)}%";
  }

  @override
  void initState() {
    _currentSyncStatus = widget.initialSyncStatus;
    // _currentNodeStatus = widget.initialNodeStatus;
    if (_currentSyncStatus == WalletSyncStatus.synced) {
      _percent = 1;
      _blocksRemaining = 0;
    } else {
      _percent = 0;
      _blocksRemaining = -1;
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

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

    _refreshSubscription = eventBus.on<RefreshPercentChangedEvent>().listen(
      (event) async {
        if (event.walletId == widget.walletId) {
          setState(() {
            _percent = event.percent.clamp(0.0, 1.0);
          });
        }
      },
    );

    final coin = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .coin;

    if (coin == Coin.epicCash) {
      _blocksRemainingSubscription = eventBus.on<BlocksRemainingEvent>().listen(
        (event) async {
          if (event.walletId == widget.walletId) {
            setState(() {
              _blocksRemaining = event.blocksRemaining;
            });
          }
        },
      );
    }

    // _nodeStatusSubscription =
    //     eventBus.on<NodeConnectionStatusChangedEvent>().listen(
    //   (event) async {
    //     if (event.walletId == widget.walletId) {
    //       switch (event.newStatus) {
    //         case NodeConnectionStatus.disconnected:
    //           // TODO: Handle this case.
    //           break;
    //         case NodeConnectionStatus.connected:
    //           // TODO: Handle this case.
    //           break;
    //         case NodeConnectionStatus.connecting:
    //           // TODO: Handle this case.
    //           break;
    //       }
    //       setState(() {
    //         _currentNodeStatus = event.newStatus;
    //       });
    //     }
    //   },
    // );
    super.initState();
  }

  @override
  void dispose() {
    // _nodeStatusSubscription.cancel();
    _syncStatusSubscription.cancel();
    _refreshSubscription.cancel();
    _blocksRemainingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = Util.isDesktop;

    final progressLength = isDesktop
        ? 430.0
        : screenWidth - (_padding * 2) - (_boxPadding * 3) - _iconSize;

    final coin = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .coin;

    if (coin == Coin.epicCash) {
      double highestPercent = (ref
              .read(walletsChangeNotifierProvider)
              .getManager(widget.walletId)
              .wallet as EpicCashWallet)
          .highestPercent;
      if (_percent < highestPercent) {
        _percent = highestPercent.clamp(0.0, 1.0);
      }
    }

    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
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
                "Network",
                style: STextStyles.navBarTitle(context),
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
                      key: const Key(
                          "walletNetworkSettingsAddNewNodeViewButton"),
                      size: 36,
                      shadows: const [],
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .background,
                      icon: SvgPicture.asset(
                        Assets.svg.verticalEllipsis,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                        width: 20,
                        height: 20,
                      ),
                      onPressed: () {
                        showDialog<dynamic>(
                          barrierColor: Colors.transparent,
                          barrierDismissible: true,
                          context: context,
                          builder: (_) {
                            return Stack(
                              children: [
                                Positioned(
                                  top: 9,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .popupBG,
                                      borderRadius: BorderRadius.circular(
                                          Constants.size.circularBorderRadius),
                                      // boxShadow: [CFColors.standardBoxShadow],
                                      boxShadow: const [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            showDialog<void>(
                                              context: context,
                                              useSafeArea: false,
                                              barrierDismissible: true,
                                              builder: (context) {
                                                return ConfirmFullRescanDialog(
                                                  onConfirm: _attemptRescan,
                                                );
                                              },
                                            );
                                          },
                                          child: RoundedWhiteContainer(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Text(
                                                "Rescan blockchain",
                                                style:
                                                    STextStyles.baseXS(context),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: _padding,
                right: _padding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Blockchain status",
                textAlign: TextAlign.left,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.smallMed12(context),
              ),
              GestureDetector(
                onTap: () {
                  ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(widget.walletId)
                      .refresh();
                },
                child: Text(
                  "Resync",
                  style: STextStyles.link2(context),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isDesktop ? 12 : 9,
          ),
          if (_currentSyncStatus == WalletSyncStatus.synced)
            RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(context).extension<StackColors>()!.background
                  : null,
              padding: isDesktop
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorGreen
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(_iconSize),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.svg.radio,
                        height: isDesktop ? 19 : 14,
                        width: isDesktop ? 19 : 14,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorGreen,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _boxPadding,
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: progressLength,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Synchronized",
                              style: STextStyles.w600_10(context),
                            ),
                            Text(
                              "100%",
                              style: STextStyles.syncPercent(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      ProgressBar(
                        width: progressLength,
                        height: 5,
                        fillColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorGreen,
                        backgroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultBG,
                        percent: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_currentSyncStatus == WalletSyncStatus.syncing)
            RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(context).extension<StackColors>()!.background
                  : null,
              padding: isDesktop
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorYellow
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(_iconSize),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.svg.radioSyncing,
                        height: 14,
                        width: 14,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorYellow,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _boxPadding,
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: progressLength,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedText(
                              style: STextStyles.w600_10(context),
                              stringsToLoopThrough: const [
                                "Synchronizing",
                                "Synchronizing.",
                                "Synchronizing..",
                                "Synchronizing...",
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  _percentString(_percent),
                                  style:
                                      STextStyles.syncPercent(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorYellow,
                                  ),
                                ),
                                if (coin == Coin.epicCash)
                                  Text(
                                    " (Blocks to go: ${_blocksRemaining == -1 ? "?" : _blocksRemaining})",
                                    style: STextStyles.syncPercent(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .accentColorYellow,
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      ProgressBar(
                        width: progressLength,
                        height: 5,
                        fillColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorYellow,
                        backgroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultBG,
                        percent: _percent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_currentSyncStatus == WalletSyncStatus.unableToSync)
            RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(context).extension<StackColors>()!.background
                  : null,
              padding: isDesktop
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorRed
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(_iconSize),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.svg.radioProblem,
                        height: 14,
                        width: 14,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorRed,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _boxPadding,
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: progressLength,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Unable to synchronize",
                              style: STextStyles.w600_10(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorRed,
                              ),
                            ),
                            Text(
                              "0%",
                              style: STextStyles.syncPercent(context).copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      ProgressBar(
                        width: progressLength,
                        height: 5,
                        fillColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorRed,
                        backgroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .textFieldDefaultBG,
                        percent: 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_currentSyncStatus == WalletSyncStatus.unableToSync)
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
              ),
              child: RoundedContainer(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .warningBackground,
                child: Text(
                  "Please check your internet connection and make sure your current node is not having issues.",
                  style: STextStyles.baseXS(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .warningForeground,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: isDesktop ? 32 : 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${ref.watch(walletsChangeNotifierProvider.select((value) => value.getManager(widget.walletId).coin)).prettyName} nodes",
                textAlign: TextAlign.left,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context)
                    : STextStyles.smallMed12(context),
              ),
              BlueTextButton(
                text: "Add new node",
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AddEditNodeView.routeName,
                    arguments: Tuple4(
                      AddEditNodeViewType.add,
                      ref
                          .read(walletsChangeNotifierProvider)
                          .getManager(widget.walletId)
                          .coin,
                      null,
                      WalletNetworkSettingsView.routeName,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(
            height: isDesktop ? 12 : 8,
          ),
          NodesList(
            coin: ref.watch(walletsChangeNotifierProvider
                .select((value) => value.getManager(widget.walletId).coin)),
            popBackToRoute: WalletNetworkSettingsView.routeName,
          ),
          if (isDesktop)
            const SizedBox(
              height: 32,
            ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Advanced",
                    textAlign: TextAlign.left,
                    style: STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                ],
              ),
            ),
          if (isDesktop)
            RoundedWhiteContainer(
              borderColor: isDesktop
                  ? Theme.of(context).extension<StackColors>()!.background
                  : null,
              padding: isDesktop
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              child: Expandable(
                onExpandChanged: (state) {
                  setState(() {
                    _advancedIsExpanded = state == ExpandableState.expanded;
                  });
                },
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: _iconSize,
                          height: _iconSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textFieldDefaultBG,
                            borderRadius: BorderRadius.circular(_iconSize),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              Assets.svg.networkWired,
                              width: 24,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textDark,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Advanced",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textDark,
                              ),
                            ),
                            Text(
                              "Rescan blockchain",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        )
                      ],
                    ),
                    SvgPicture.asset(
                      _advancedIsExpanded
                          ? Assets.svg.chevronDown
                          : Assets.svg.chevronUp,
                      width: 12,
                      height: 6,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    ),
                  ],
                ),
                body: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 50,
                        top: 16,
                        bottom: 6,
                      ),
                      child: BlueTextButton(
                        text: "Rescan",
                        onTap: () async {
                          await Navigator.of(context).push(
                            FadePageRoute<void>(
                              ConfirmFullRescanDialog(
                                onConfirm: _attemptRescan,
                              ),
                              const RouteSettings(),
                            ),
                          );
                          // await showDialog<dynamic>(
                          //   context: context,
                          //   builder: (context) {
                          //     return ConfirmFullRescanDialog(
                          //       onConfirm: _attemptRescan,
                          //     );
                          //   },
                          // );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

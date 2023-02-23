import 'dart:async';
import 'dart:math';

import 'package:epicpay/models/epicbox_model.dart';
import 'package:epicpay/pages/settings_views/epicbox_settings_view/epicbox_settings_view.dart';
import 'package:epicpay/pages/settings_views/epicbox_settings_view/manage_epicbox_views/add_edit_epicbox_view.dart';
import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/services/event_bus/events/global/epicbox_status_changed_event.dart';
import 'package:epicpay/services/event_bus/global_event_bus.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/conditional_parent.dart';
import 'package:epicpay/widgets/rounded_container.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

class EpicBoxCard extends ConsumerStatefulWidget {
  const EpicBoxCard({
    Key? key,
    required this.epicBoxId,
    required this.popBackToRoute,
    this.eventBus,
  }) : super(key: key);

  final String epicBoxId;
  final String popBackToRoute;
  final EventBus? eventBus;

  @override
  ConsumerState<EpicBoxCard> createState() => _EpicBoxCardState();
}

class _EpicBoxCardState extends ConsumerState<EpicBoxCard> {
  late final EventBus eventBus;

  late EpicBoxStatus? _currentEpicBoxStatus;

  late StreamSubscription<dynamic>? _epicBoxSubscription;

  bool _isCurrentEpicBox = false;

  void showContextMenu(
      EpicBoxModel epicBox, bool isConnected, Offset tapPosition) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => EpicBoxMenu(
        epicBox: epicBox,
        popBackToRoute: widget.popBackToRoute,
        isConnected: isConnected,
        tapPosition: tapPosition,
      ),
    );
  }

  @override
  void initState() {
    if (ref.read(walletProvider)!.isEpicBoxConnected) {
      _currentEpicBoxStatus = EpicBoxStatus.connected;
      // } else if (ref.read(epicBoxListenerProvider)!.isListening) { // Example if a listener provider is added
      //   _currentEpicBoxStatus = EpicBoxStatus.listening;
    } else {
      _currentEpicBoxStatus = EpicBoxStatus.unableToConnect;
    }

    eventBus =
        widget.eventBus != null ? widget.eventBus! : GlobalEventBus.instance;

    _epicBoxSubscription = eventBus.on<EpicBoxStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == ref.read(walletProvider)!.walletId) {
          setState(() {
            _currentEpicBoxStatus = event.newStatus;
          });
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _epicBoxSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final epicBox = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getPrimaryEpicBox()));
    final _epicBox = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getEpicBoxById(id: widget.epicBoxId)))!;

    _isCurrentEpicBox = epicBox?.name == _epicBox.name;

    if (epicBox?.name == '' || epicBox?.name == null) {
      _isCurrentEpicBox = (_epicBox.name == 'americas');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTapDown: (tapDetails) async {
              if (_isCurrentEpicBox &&
                  _currentEpicBoxStatus == EpicBoxStatus.connected) {
                // if this is the current epic box server and we're connected, ignore tap
                return;
              }

              // TODO re-enable for editing non-default nodes
              // showContextMenu(
              //     _epicBox, _isCurrentEpicBox, tapDetails.globalPosition);

              if (!_isCurrentEpicBox) {
                // only set primary epic box if tapped on a different server than the current one
                await ref
                    .read(nodeServiceChangeNotifierProvider)
                    .setPrimaryEpicBox(
                      epicBox: _epicBox,
                    );
              }
              await ref.read(walletProvider)!.initializeExisting();

              if (mounted) {
                Navigator.of(context).pop();

                setState(() {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const EpicBoxSettingsView(),
                      transitionDuration: const Duration(seconds: 0),
                      reverseTransitionDuration: const Duration(seconds: 0),
                    ),
                  );
                });
              }
            },
            child: Container(
              height: 48,
              color: Colors.transparent,
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.networkWired,
                    color: _isCurrentEpicBox
                        ? _currentEpicBoxStatus == EpicBoxStatus.unableToConnect
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorRed
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .accentColorGreen
                        : Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    _epicBox.name,
                    style: STextStyles.bodyBold(context).copyWith(
                      color: _isCurrentEpicBox
                          ? _currentEpicBoxStatus ==
                                  EpicBoxStatus.unableToConnect
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorRed
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorGreen
                          : Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isCurrentEpicBox && _currentEpicBoxStatus != null)
          CurrentEpicBoxStatusIcon(
            status: _currentEpicBoxStatus!,
          ),
      ],
    );
  }
}

class CurrentEpicBoxStatusIcon extends ConsumerWidget {
  const CurrentEpicBoxStatusIcon({
    Key? key,
    required this.status,
  }) : super(key: key);

  final EpicBoxStatus status;

  Widget _getAsset(BuildContext context) {
    switch (status) {
      case EpicBoxStatus.unableToConnect:
        return SvgPicture.asset(
          Assets.svg.refresh,
          color: Theme.of(context).extension<StackColors>()!.accentColorRed,
        );
      case EpicBoxStatus.connected:
        /*case EpicBoxStatus.listening:*/
        return SvgPicture.asset(
          Assets.svg.check,
          color: Theme.of(context).extension<StackColors>()!.accentColorGreen,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConditionalParent(
      condition: status == EpicBoxStatus.unableToConnect,
      builder: (child) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            height: 48,
            child: IconButton(
              splashRadius: 24,
              icon: child,
              onPressed: ref.read(walletProvider)!.refresh,
            ),
          ),
        );
      },
      child: ConditionalParent(
        condition: status != EpicBoxStatus.unableToConnect,
        builder: (child) => Padding(
          padding: const EdgeInsets.only(
            right: 24,
          ),
          child: child,
        ),
        child: _getAsset(context),
      ),
    );
  }
}

class EpicBoxMenu extends ConsumerStatefulWidget {
  const EpicBoxMenu({
    Key? key,
    required this.epicBox,
    required this.popBackToRoute,
    required this.isConnected,
    required this.tapPosition,
  }) : super(key: key);

  final EpicBoxModel epicBox;
  final String popBackToRoute;
  final bool isConnected;
  final Offset tapPosition;

  @override
  ConsumerState<EpicBoxMenu> createState() => _EpicBoxMenuState();
}

class _EpicBoxMenuState extends ConsumerState<EpicBoxMenu> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Positioned(
          top: widget.tapPosition.dy - 40,
          left: min(
            widget.tapPosition.dx,
            // ensure popup doesn't go off screen on right
            MediaQuery.of(context).size.width - 200,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 160,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RoundedContainer(
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).extension<StackColors>()!.coal,
                  child: Column(
                    children: [
                      if (!widget.isConnected)
                        GestureDetector(
                          onTap: () async {
                            await ref
                                .read(nodeServiceChangeNotifierProvider)
                                .setPrimaryEpicBox(
                                  epicBox: widget.epicBox,
                                );

                            await ref
                                .read(walletProvider)!
                                .initializeExisting();
                            // await ref.read(walletProvider)!.updateEpicBox(true);

                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            width: constraints.minWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Connect",
                                style: STextStyles.body(context),
                              ),
                            ),
                          ),
                        ),
                      if (!widget.isConnected)
                        const SizedBox(
                          height: 16,
                        ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            AddEditEpicBoxView.routeName,
                            arguments: Tuple4(
                              AddEditEpicBoxViewType.edit,
                              Coin.epicCash,
                              widget.epicBox.id,
                              widget.popBackToRoute,
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: constraints.minWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Edit",
                              style: STextStyles.body(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 160,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return RoundedContainer(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).extension<StackColors>()!.coal,
                      child: Column(
                        children: [
                          if (!widget.isConnected)
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(nodeServiceChangeNotifierProvider)
                                    .setPrimaryEpicBox(
                                      epicBox: widget.epicBox,
                                    );
                                // await ref
                                //     .read(walletProvider)!
                                //     .updateEpicBox(true);
                                await ref
                                    .read(walletProvider)!
                                    .initializeExisting();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                width: constraints.minWidth,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Connect",
                                    style: STextStyles.body(context),
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.isConnected)
                            const SizedBox(
                              height: 16,
                            ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                AddEditEpicBoxView.routeName,
                                arguments: Tuple3(
                                  AddEditEpicBoxViewType.edit,
                                  widget.epicBox.id,
                                  widget.popBackToRoute,
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: constraints.minWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Edit",
                                  style: STextStyles.body(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
          ],
        ),
      ],
    );
  }
}

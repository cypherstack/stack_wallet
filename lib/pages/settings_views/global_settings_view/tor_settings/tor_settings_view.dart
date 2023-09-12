/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class TorSettingsView extends ConsumerStatefulWidget {
  const TorSettingsView({Key? key}) : super(key: key);

  static const String routeName = "/torSettings";

  @override
  ConsumerState<TorSettingsView> createState() => _TorSettingsViewState();
}

class _TorSettingsViewState extends ConsumerState<TorSettingsView> {
  late TorConnectionStatus _networkStatus;

  Widget _buildTorIcon(TorConnectionStatus status) {
    switch (status) {
      case TorConnectionStatus.disconnected:
        return GestureDetector(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SvgPicture.asset(
                  Assets.svg.tor,
                  color:
                      Theme.of(context).extension<StackColors>()!.textSubtitle3,
                  width: 200,
                  height: 200,
                ),
                Text(
                  "CONNECT",
                  style: STextStyles.smallMed14(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.popupBG),
                )
              ],
            ),
            onTap: () async {
              await connect();
            });
      case TorConnectionStatus.connected:
        return GestureDetector(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SvgPicture.asset(
                  Assets.svg.tor,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .accentColorGreen,
                  width: 200,
                  height: 200,
                ),
                Text(
                  "CONNECTED",
                  style: STextStyles.smallMed14(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.popupBG),
                )
              ],
            ),
            onTap: () async {
              // TODO we could make this sync.
              await disconnect(); // TODO we could do away with the Future here.
            });
      case TorConnectionStatus.connecting:
        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SvgPicture.asset(
              Assets.svg.tor,
              color:
                  Theme.of(context).extension<StackColors>()!.accentColorYellow,
              width: 200,
              height: 200,
            ),
            Text(
              "CONNECTING",
              style: STextStyles.smallMed14(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.popupBG),
            )
          ],
        );
    }
  }

  Widget _buildTorStatus(TorConnectionStatus status) {
    switch (status) {
      case TorConnectionStatus.disconnected:
        return Text(
          "Disconnected",
          style: STextStyles.itemSubtitle(context).copyWith(
              color: Theme.of(context).extension<StackColors>()!.textSubtitle3),
        );
      case TorConnectionStatus.connected:
        return Text(
          "Connected",
          style: STextStyles.itemSubtitle(context).copyWith(
              color:
                  Theme.of(context).extension<StackColors>()!.accentColorGreen),
        );
      case TorConnectionStatus.connecting:
        return Text(
          "Connecting",
          style: STextStyles.itemSubtitle(context).copyWith(
              color: Theme.of(context)
                  .extension<StackColors>()!
                  .accentColorYellow),
        );
    }
  }

  @override
  void initState() {
    _networkStatus = ref.read(pTorService).enabled
        ? TorConnectionStatus.connected
        : TorConnectionStatus.disconnected;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.backgroundAppBar,
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Tor settings",
            style: STextStyles.navBarTitle(context),
          ),
          actions: [
            AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                icon: SvgPicture.asset(
                  Assets.svg.circleQuestion,
                ),
                onPressed: () {
                  showDialog<dynamic>(
                    context: context,
                    useSafeArea: false,
                    barrierDismissible: true,
                    builder: (context) {
                      return const StackDialog(
                        title: "What is Tor?",
                        message:
                            "Short for \"The Onion Router\", is an open-source software that enables internet communication"
                            " to remain anonymous by routing internet traffic through a series of layered nodes,"
                            " to obscure the origin and destination of data.",
                        rightButton: SecondaryButton(
                          label: "Close",
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: _buildTorIcon(_networkStatus),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                  child: RoundedWhiteContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "Tor status",
                            style: STextStyles.titleBold12(context),
                          ),
                          const Spacer(),
                          _buildTorStatus(_networkStatus),
                        ],
                      ),
                    ),
                  ),
                  onTap: () async {
                    // Connect or disconnect when the user taps the status.
                    switch (_networkStatus) {
                      case TorConnectionStatus.disconnected:
                        // Update the UI.
                        setState(() {
                          _networkStatus = TorConnectionStatus.connecting;
                        });

                        try {
                          await connect();
                        } catch (e, s) {
                          Logging.instance.log(
                            "Error starting tor: $e\n$s",
                            level: LogLevel.Error,
                          );
                          rethrow;
                        }

                        // Update the UI.
                        setState(() {
                          _networkStatus = TorConnectionStatus.connected;
                        });
                        break;
                      case TorConnectionStatus.connected:
                        try {
                          await disconnect();
                        } catch (e, s) {
                          Logging.instance.log(
                            "Error stopping tor: $e\n$s",
                            level: LogLevel.Error,
                          );
                          rethrow;
                        }

                        // Update the UI.
                        setState(() {
                          _networkStatus = TorConnectionStatus.disconnected;
                        });
                        break;
                      case TorConnectionStatus.connecting:
                        // Do nothing.
                        break;
                    }
                  }),
              const SizedBox(
                height: 8,
              ),
              RoundedWhiteContainer(
                child: Consumer(
                  builder: (_, ref, __) {
                    return RawMaterialButton(
                      // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius,
                        ),
                      ),
                      onPressed: null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Tor killswitch",
                                  style: STextStyles.titleBold12(context),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    showDialog<dynamic>(
                                      context: context,
                                      useSafeArea: false,
                                      barrierDismissible: true,
                                      builder: (context) {
                                        return const StackDialog(
                                          title: "What is Tor killswitch?",
                                          message:
                                              "A security feature that protects your information from accidental exposure by"
                                              " disconnecting your device from the Tor network if your virtual private network (VPN)"
                                              " connection is disrupted or compromised.",
                                          rightButton: SecondaryButton(
                                            label: "Close",
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    Assets.svg.circleInfo,
                                    height: 16,
                                    width: 16,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .infoItemLabel,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                              width: 40,
                              child: DraggableSwitchButton(
                                isOn: ref.watch(
                                  prefsChangeNotifierProvider
                                      .select((value) => value.torKillswitch),
                                ),
                                onValueChanged: (newValue) {
                                  ref
                                      .read(prefsChangeNotifierProvider)
                                      .torKillswitch = newValue;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Connect to the Tor network.
  ///
  /// This method is called when the user taps the "Connect" button.
  ///
  /// Throws an exception if the Tor service fails to start.
  ///
  /// Returns a Future that completes when the Tor service has started.
  Future<void> connect() async {
    // Init the Tor service if it hasn't already been.
    ref.read(pTorService).init();

    // Start the Tor service.
    try {
      await ref.read(pTorService).start();

      // Toggle the useTor preference on success.
      ref.read(prefsChangeNotifierProvider).useTor = true;
    } catch (e, s) {
      Logging.instance.log(
        "Error starting tor: $e\n$s",
        level: LogLevel.Error,
      );
    }

    // Update the UI.
    setState(() {
      _networkStatus = TorConnectionStatus.connecting;
    });

    return;
  }

  /// Disconnect from the Tor network.
  ///
  /// This method is called when the user taps the "Disconnect" button.
  ///
  /// Throws an exception if the Tor service fails to stop.
  ///
  /// Returns a Future that completes when the Tor service has stopped.
  Future<void> disconnect() async {
    // Stop the Tor service.
    try {
      await ref.read(pTorService).stop();

      // Toggle the useTor preference on success.
      ref.read(prefsChangeNotifierProvider).useTor = false;
    } catch (e, s) {
      Logging.instance.log(
        "Error stopping tor: $e\n$s",
        level: LogLevel.Error,
      );
    }

    setState(() {
      _networkStatus = TorConnectionStatus.disconnected;
    });

    return;
  }
}
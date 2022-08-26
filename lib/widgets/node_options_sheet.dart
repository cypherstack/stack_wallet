import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class NodeOptionsSheet extends ConsumerWidget {
  const NodeOptionsSheet({
    Key? key,
    required this.nodeId,
    required this.coin,
    required this.popBackToRoute,
  }) : super(key: key);

  final String nodeId;
  final Coin coin;
  final String popBackToRoute;

  Future<void> _notifyWalletsOfUpdatedNode(WidgetRef ref) async {
    final managers = ref
        .read(walletsChangeNotifierProvider)
        .managers
        .where((e) => e.coin == coin);
    final prefs = ref.read(prefsChangeNotifierProvider);

    switch (prefs.syncType) {
      case SyncingType.currentWalletOnly:
        for (final manager in managers) {
          if (manager.isActiveWallet) {
            manager.updateNode(true);
          } else {
            manager.updateNode(false);
          }
        }
        break;
      case SyncingType.selectedWalletsAtStartup:
        final List<String> walletIdsToSync = prefs.walletIdsSyncOnStartup;
        for (final manager in managers) {
          if (walletIdsToSync.contains(manager.walletId)) {
            manager.updateNode(true);
          } else {
            manager.updateNode(false);
          }
        }
        break;
      case SyncingType.allWalletsOnStartup:
        for (final manager in managers) {
          manager.updateNode(true);
        }
        break;
    }
  }

  Future<bool> _testConnection(
      NodeModel node, BuildContext context, WidgetRef ref) async {
    bool testPassed = false;

    switch (coin) {
      case Coin.epicCash:
        try {
          final String uriString = "${node.host}:${node.port}/v1/version";

          testPassed = await testEpicBoxNodeConnection(Uri.parse(uriString));
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }
        break;

      case Coin.monero:
        try {
          final uri = Uri.parse(node.host);
          if (uri.scheme.startsWith("http")) {
            final String path = uri.path.isEmpty ? "/json_rpc" : uri.path;

            String uriString = "${uri.scheme}://${uri.host}:${node.port}$path";

            testPassed = await testMoneroNodeConnection(Uri.parse(uriString));
          }
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }

        break;

      case Coin.bitcoin:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.bitcoinTestNet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
        final client = ElectrumX(
          host: node.host,
          port: node.port,
          useSSL: node.useSSL,
          failovers: [],
          prefs: ref.read(prefsChangeNotifierProvider),
        );

        try {
          testPassed = await client.ping();
        } catch (_) {
          testPassed = false;
        }

        break;
    }

    if (testPassed) {
      // showFloatingFlushBar(
      //   type: FlushBarType.success,
      //   message: "Server ping success",
      //   context: context,
      // );
    } else {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        iconAsset: Assets.svg.circleAlert,
        message: "Could not connect to node",
        context: context,
      );
    }

    return testPassed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = MediaQuery.of(context).size.height * 0.60;
    final node = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getNodeById(id: nodeId)))!;

    final status = ref
                .watch(nodeServiceChangeNotifierProvider
                    .select((value) => value.getPrimaryNodeFor(coin: coin)))
                ?.id !=
            nodeId
        ? "Disconnected"
        : "Connected";

    return Container(
      decoration: const BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: LimitedBox(
        maxHeight: maxHeight,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: 0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CFColors.fieldGray,
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    width: 60,
                    height: 4,
                  ),
                ),
                const SizedBox(
                  height: 36,
                ),
                Text(
                  "Node options",
                  style: STextStyles.pageTitleH2,
                  textAlign: TextAlign.left,
                ),
                RoundedWhiteContainer(
                  padding: const EdgeInsets.symmetric(vertical: 38),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: node.name == DefaultNodes.defaultName
                              ? CFColors.buttonGray
                              : CFColors.link2.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            Assets.svg.node,
                            height: 15,
                            width: 19,
                            color: node.name == DefaultNodes.defaultName
                                ? CFColors.stackAccent
                                : CFColors.link2,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.name,
                            style: STextStyles.titleBold12,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            status,
                            style: STextStyles.label,
                          ),
                        ],
                      ),
                      const Spacer(),
                      SvgPicture.asset(
                        Assets.svg.network,
                        color: status == "Connected"
                            ? CFColors.stackGreen
                            : CFColors.buttonGray,
                        width: 18,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // if (!node.id.startsWith("default"))
                    Expanded(
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            CFColors.buttonGray,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed(
                            NodeDetailsView.routeName,
                            arguments: Tuple3(
                              coin,
                              node.id,
                              popBackToRoute,
                            ),
                          );
                        },
                        child: Text(
                          "Details",
                          style: STextStyles.button.copyWith(
                            color: CFColors.stackAccent,
                          ),
                        ),
                      ),
                    ),
                    // if (!node.id.startsWith("default"))
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            status == "Connected"
                                ? CFColors.disabledButton
                                : CFColors.stackAccent,
                          ),
                        ),
                        onPressed: status == "Connected"
                            ? null
                            : () async {
                                final canConnect =
                                    await _testConnection(node, context, ref);
                                if (!canConnect) {
                                  return;
                                }

                                ref
                                    .read(nodeServiceChangeNotifierProvider)
                                    .setPrimaryNodeFor(
                                      coin: coin,
                                      node: node,
                                      shouldNotifyListeners: true,
                                    );

                                _notifyWalletsOfUpdatedNode(ref);
                              },
                        child: Text(
                          // status == "Connected" ? "Disconnect" : "Connect",
                          "Connect",
                          style: STextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

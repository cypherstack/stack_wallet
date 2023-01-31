import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/node_details_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:tuple/tuple.dart';

class NodeCard extends ConsumerStatefulWidget {
  const NodeCard({
    Key? key,
    required this.nodeId,
    required this.coin,
    required this.popBackToRoute,
  }) : super(key: key);

  final Coin coin;
  final String nodeId;
  final String popBackToRoute;

  @override
  ConsumerState<NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends ConsumerState<NodeCard> {
  String _status = "Disconnected";
  late final String nodeId;
  bool _advancedIsExpanded = false;

  Future<void> _notifyWalletsOfUpdatedNode(WidgetRef ref) async {
    final managers = ref
        .read(walletsChangeNotifierProvider)
        .managers
        .where((e) => e.coin == widget.coin);
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
    NodeModel node,
    BuildContext context,
    WidgetRef ref,
  ) async {
    bool testPassed = false;

    switch (widget.coin) {
      case Coin.epicCash:
        try {
          testPassed = await testEpicNodeConnection(
                NodeFormData()
                  ..host = node.host
                  ..useSSL = node.useSSL
                  ..port = node.port,
              ) !=
              null;
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }
        break;

      case Coin.monero:
      case Coin.wownero:
        try {
          final uri = Uri.parse(node.host);
          if (uri.scheme.startsWith("http")) {
            final String path = uri.path.isEmpty ? "/json_rpc" : uri.path;

            String uriString = "${uri.scheme}://${uri.host}:${node.port}$path";

            final response = await testMoneroNodeConnection(
              Uri.parse(uriString),
              false,
            );

            if (response.cert != null) {
              if (mounted) {
                final shouldAllowBadCert = await showBadX509CertificateDialog(
                  response.cert!,
                  response.url!,
                  response.port!,
                  context,
                );

                if (shouldAllowBadCert) {
                  final response = await testMoneroNodeConnection(
                      Uri.parse(uriString), true);
                  testPassed = response.success;
                }
              }
            } else {
              testPassed = response.success;
            }
          }
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
        }

        break;

      case Coin.bitcoin:
      case Coin.litecoin:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.bitcoinTestNet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
      case Coin.bitcoincash:
      case Coin.litecoinTestNet:
      case Coin.namecoin:
      case Coin.bitcoincashTestnet:
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
      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          iconAsset: Assets.svg.circleAlert,
          message: "Could not connect to node",
          context: context,
        ),
      );
    }

    return testPassed;
  }

  @override
  void initState() {
    nodeId = widget.nodeId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final node = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getPrimaryNodeFor(coin: widget.coin)));
    final _node = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getNodeById(id: nodeId)))!;

    if (node?.name == _node.name) {
      _status = "Connected";
    } else {
      _status = "Disconnected";
    }

    final isDesktop = Util.isDesktop;

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.background
          : null,
      child: ConditionalParent(
        condition: !isDesktop,
        builder: (child) {
          return RawMaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Constants.size.circularBorderRadius,
              ),
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (_) => NodeOptionsSheet(
                  nodeId: nodeId,
                  coin: widget.coin,
                  popBackToRoute: widget.popBackToRoute,
                ),
              );
            },
            child: child,
          );
        },
        child: ConditionalParent(
          condition: isDesktop,
          builder: (child) {
            return Expandable(
              onExpandChanged: (state) {
                setState(() {
                  _advancedIsExpanded = state == ExpandableState.expanded;
                });
              },
              header: child,
              body: Padding(
                padding: const EdgeInsets.only(
                  bottom: 24,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 66,
                    ),
                    CustomTextButton(
                      text: "Connect",
                      enabled: _status == "Disconnected",
                      onTap: () async {
                        final canConnect =
                            await _testConnection(_node, context, ref);
                        if (!canConnect) {
                          return;
                        }

                        await ref
                            .read(nodeServiceChangeNotifierProvider)
                            .setPrimaryNodeFor(
                              coin: widget.coin,
                              node: _node,
                              shouldNotifyListeners: true,
                            );

                        await _notifyWalletsOfUpdatedNode(ref);
                      },
                    ),
                    const SizedBox(
                      width: 48,
                    ),
                    CustomTextButton(
                      text: "Details",
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          NodeDetailsView.routeName,
                          arguments: Tuple3(
                            widget.coin,
                            widget.nodeId,
                            widget.popBackToRoute,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 40 : 24,
                  height: isDesktop ? 40 : 24,
                  decoration: BoxDecoration(
                    color: _node.id.startsWith(DefaultNodes.defaultNodeIdPrefix)
                        ? Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackSecondary
                        : Theme.of(context)
                            .extension<StackColors>()!
                            .infoItemIcons
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      Assets.svg.node,
                      height: isDesktop ? 18 : 11,
                      width: isDesktop ? 20 : 14,
                      color:
                          _node.id.startsWith(DefaultNodes.defaultNodeIdPrefix)
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .infoItemIcons,
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
                      _node.name,
                      style: STextStyles.titleBold12(context),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      _status,
                      style: STextStyles.label(context),
                    ),
                  ],
                ),
                const Spacer(),
                if (!isDesktop)
                  SvgPicture.asset(
                    Assets.svg.network,
                    color: _status == "Connected"
                        ? Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorGreen
                        : Theme.of(context)
                            .extension<StackColors>()!
                            .buttonBackSecondary,
                    width: 20,
                    height: 20,
                  ),
                if (isDesktop)
                  SvgPicture.asset(
                    _advancedIsExpanded
                        ? Assets.svg.chevronUp
                        : Assets.svg.chevronDown,
                    width: 12,
                    height: 6,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle1,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

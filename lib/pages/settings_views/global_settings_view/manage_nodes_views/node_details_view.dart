import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/utilities/test_monero_node_connection.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:tuple/tuple.dart';

class NodeDetailsView extends ConsumerStatefulWidget {
  const NodeDetailsView({
    Key? key,
    required this.coin,
    required this.nodeId,
    required this.popRouteName,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const String routeName = "/nodeDetails";

  final FlutterSecureStorageInterface secureStore;
  final Coin coin;
  final String nodeId;
  final String popRouteName;

  @override
  ConsumerState<NodeDetailsView> createState() => _NodeDetailsViewState();
}

class _NodeDetailsViewState extends ConsumerState<NodeDetailsView> {
  late final FlutterSecureStorageInterface secureStore;
  late final Coin coin;
  late final String nodeId;
  late final String popRouteName;

  @override
  initState() {
    secureStore = widget.secureStore;
    coin = widget.coin;
    nodeId = widget.nodeId;
    popRouteName = widget.popRouteName;
    super.initState();
  }

  Future<void> _testConnection(WidgetRef ref, BuildContext context) async {
    final node =
        ref.watch(nodeServiceChangeNotifierProvider).getNodeById(id: nodeId);

    bool testPassed = false;

    switch (coin) {
      case Coin.epicCash:
        try {
          final uri = Uri.parse(node!.host);
          if (uri.scheme.startsWith("http")) {
            final String path = uri.path.isEmpty ? "/v1/version" : uri.path;

            String uriString = "${uri.scheme}://${uri.host}:${node.port}$path";

            testPassed = await testEpicBoxNodeConnection(Uri.parse(uriString));
          }
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Warning);
          testPassed = false;
        }
        break;

      case Coin.monero:
        try {
          final uri = Uri.parse(node!.host);
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
      case Coin.bitcoincash:
      case Coin.namecoin:
      case Coin.bitcoincashTestnet:
        final client = ElectrumX(
          host: node!.host,
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
      showFloatingFlushBar(
        type: FlushBarType.success,
        message: "Server ping success",
        context: context,
      );
    } else {
      showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Server unreachable",
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Node details",
          style: STextStyles.navBarTitle(context),
        ),
        actions: [
          if (!nodeId.startsWith("default"))
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppBarIconButton(
                  key: const Key("nodeDetailsEditNodeAppBarButtonKey"),
                  size: 36,
                  shadows: const [],
                  color: StackTheme.instance.color.background,
                  icon: SvgPicture.asset(
                    Assets.svg.pencil,
                    color: StackTheme.instance.color.accentColorDark,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AddEditNodeView.routeName,
                      arguments: Tuple4(
                        AddEditNodeViewType.edit,
                        coin,
                        nodeId,
                        popRouteName,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 12,
          left: 12,
          right: 12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final node = ref.watch(nodeServiceChangeNotifierProvider
                .select((value) => value.getNodeById(id: nodeId)));

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 8),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NodeForm(
                          node: node,
                          secureStore: secureStore,
                          readOnly: true,
                          coin: coin,
                        ),
                        const Spacer(),
                        TextButton(
                          style: StackTheme.instance
                              .getSecondaryEnabledButtonColor(context),
                          onPressed: () async {
                            await _testConnection(ref, context);
                          },
                          child: Text(
                            "Test connection",
                            style: STextStyles.button(context).copyWith(
                                color:
                                    StackTheme.instance.color.accentColorDark),
                          ),
                        ),
                        const SizedBox(height: 16),
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

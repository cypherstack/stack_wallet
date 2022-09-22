import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/node_options_sheet.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

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

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(0),
      child: RawMaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        onPressed: () {
          showModalBottomSheet<dynamic>(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (_) => NodeOptionsSheet(
              nodeId: nodeId,
              coin: widget.coin,
              popBackToRoute: widget.popBackToRoute,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _node.name == DefaultNodes.defaultName
                      ? StackTheme.instance.color.buttonBackSecondary
                      : StackTheme.instance.color.infoItemIcons
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    Assets.svg.node,
                    height: 11,
                    width: 14,
                    color: _node.name == DefaultNodes.defaultName
                        ? StackTheme.instance.color.accentColorDark
                        : StackTheme.instance.color.infoItemIcons,
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
              SvgPicture.asset(
                Assets.svg.network,
                color: _status == "Connected"
                    ? StackTheme.instance.color.accentColorGreen
                    : StackTheme.instance.color.buttonBackSecondary,
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

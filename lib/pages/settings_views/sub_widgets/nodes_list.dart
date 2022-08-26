import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/node_service_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/widgets/node_card.dart';

class NodesList extends ConsumerWidget {
  const NodesList({
    Key? key,
    required this.coin,
    required this.popBackToRoute,
  }) : super(key: key);

  final Coin coin;
  final String popBackToRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getNodesFor(coin)));

    return Column(
      children: [
        ...nodes
            .map(
              (node) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: NodeCard(
                  key: Key("${node.id}_card_key"),
                  nodeId: node.id,
                  coin: coin,
                  popBackToRoute: popBackToRoute,
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}

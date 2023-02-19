import 'package:epicpay/pages/settings_views/epicbox_settings_view/sub_widgets/epicbox_card.dart';
import 'package:epicpay/providers/global/node_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpicBoxList extends ConsumerWidget {
  const EpicBoxList({
    Key? key,
    required this.popBackToRoute,
  }) : super(key: key);

  final String popBackToRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epicBoxes = ref.watch(nodeServiceChangeNotifierProvider
        .select((value) => value.getEpicBoxes()));

    return Column(
      children: [
        ...epicBoxes
            .map(
              (epicBox) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: EpicBoxCard(
                  key: Key("${epicBox.id}_card_key"),
                  epicBoxId: epicBox.id,
                  popBackToRoute: popBackToRoute,
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}

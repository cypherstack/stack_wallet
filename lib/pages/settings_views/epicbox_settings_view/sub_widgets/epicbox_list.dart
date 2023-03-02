import 'package:epicpay/models/epicbox_server_model.dart';
import 'package:epicpay/pages/settings_views/epicbox_settings_view/sub_widgets/epicbox_card.dart';
import 'package:epicpay/providers/global/node_service_provider.dart';
import 'package:epicpay/utilities/default_epicboxes.dart';
import 'package:epicpay/utilities/text_styles.dart';
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

    final defaultEpicBoxes = DefaultEpicBoxes.all;
    List<EpicBoxServerModel> customEpicBoxes = epicBoxes;
    customEpicBoxes.removeWhere(
        (epicBox) => DefaultEpicBoxes.defaultIds.contains(epicBox.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "DEFAULT EPIC BOX SERVERS",
          textAlign: TextAlign.left,
          style: STextStyles.overLineBold(context),
        ),
        const SizedBox(
          height: 14,
        ),
        ...defaultEpicBoxes
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
        if (customEpicBoxes.length > 0)
          const SizedBox(
            height: 14,
          ),
        if (customEpicBoxes.length > 0)
          Text(
            "CUSTOM EPIC BOX SERVERS",
            textAlign: TextAlign.left,
            style: STextStyles.overLineBold(context),
          ),
        if (customEpicBoxes.length > 0)
          const SizedBox(
            height: 14,
          ),
        if (customEpicBoxes.length > 0)
          ...customEpicBoxes
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

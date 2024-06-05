import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../db/sqlite/firo_cache.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/background.dart';
import '../../../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../../../widgets/detail_item.dart';

class SparkInfoView extends ConsumerWidget {
  const SparkInfoView({
    super.key,
  });

  static const String routeName = "/sparkInfo";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Spark Info",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder(
                future: FiroCacheCoordinator.getSparkCacheSize(),
                builder: (_, snapshot) {
                  String detail = "Loading...";
                  if (snapshot.connectionState == ConnectionState.done) {
                    detail = snapshot.data ?? detail;
                  }

                  return DetailItem(
                    title: "Spark electrumx cache size",
                    detail: detail,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

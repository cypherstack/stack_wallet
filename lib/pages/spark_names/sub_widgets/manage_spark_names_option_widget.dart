import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/db/drift_provider.dart';
import '../../../utilities/util.dart';
import 'owned_spark_name_card.dart';

class ManageSparkNamesOptionWidget extends ConsumerStatefulWidget {
  const ManageSparkNamesOptionWidget({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<ManageSparkNamesOptionWidget> createState() =>
      _ManageSparkNamesWidgetState();
}

class _ManageSparkNamesWidgetState
    extends ConsumerState<ManageSparkNamesOptionWidget> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(pDrift(widget.walletId));
    return StreamBuilder(
      stream: db.select(db.sparkNames).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              ...snapshot.data!.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OwnedSparkNameCard(
                    key: ValueKey(e),
                    name: e,
                    walletId: widget.walletId,
                  ),
                ),
              ),
              SizedBox(height: Util.isDesktop ? 14 : 6),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }
}

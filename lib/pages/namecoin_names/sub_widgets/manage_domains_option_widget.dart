import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../widgets/rounded_white_container.dart';

class ManageDomainsOptionWidget extends ConsumerStatefulWidget {
  const ManageDomainsOptionWidget({
    super.key,
    required this.walletId,
  });

  final String walletId;

  @override
  ConsumerState<ManageDomainsOptionWidget> createState() =>
      _ManageDomainsWidgetState();
}

class _ManageDomainsWidgetState
    extends ConsumerState<ManageDomainsOptionWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ref.watch(
        mainDBProvider.select(
          (s) => s.isar.utxos
              .where()
              .walletIdEqualTo(widget.walletId)
              .filter()
              .otherDataIsNotNull()
              .watch(fireImmediately: true),
        ),
      ),
      builder: (context, snapshot) {
        List<UTXO> list = [];
        if (snapshot.hasData) {
          list = snapshot.data!;
        }

        return ListView.separated(
          itemCount: list.length,
          itemBuilder: (context, index) => RoundedWhiteContainer(
            child: Text(list[index].otherData!),
          ),
          separatorBuilder: (context, index) => const SizedBox(
            height: 10,
          ),
        );
      },
    );
  }
}

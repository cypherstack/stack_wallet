import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:namecoin/namecoin.dart';

import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../utilities/util.dart';
import '../../../wallets/isar/providers/wallet_info_provider.dart';
import 'owned_name_card.dart';

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
    final height = ref.watch(pWalletChainHeight(widget.walletId));
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
        List<(UTXO, OpNameData)> list = [];
        if (snapshot.hasData) {
          list = snapshot.data!.map((utxo) {
            final data = jsonDecode(utxo.otherData!) as Map;

            final nameData = jsonDecode(data["nameOpData"] as String) as Map;

            return (
              utxo,
              OpNameData(nameData.cast(), utxo.blockHeight ?? height)
            );
          }).toList(growable: false);
        }

        return Column(
          children: [
            ...list.map(
              (e) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: OwnedNameCard(
                  utxo: e.$1,
                  opNameData: e.$2,
                ),
              ),
            ),
            SizedBox(
              height: Util.isDesktop ? 14 : 6,
            ),
          ],
        );
      },
    );
  }
}

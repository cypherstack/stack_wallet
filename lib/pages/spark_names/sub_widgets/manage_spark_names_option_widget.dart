import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/wallets_provider.dart';
import '../../../utilities/util.dart';
import '../../../wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
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
  StreamSubscription<List<TransactionV2>>? _streamSubscription;
  final Set<({String address, String name})> _myNames = {};

  void _updateNames() async {
    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SparkInterface;
    final names = await wallet.electrumXClient.getSparkNames();
    final myAddresses =
        await wallet.mainDB.isar.addresses
            .where()
            .walletIdEqualTo(widget.walletId)
            .filter()
            .typeEqualTo(AddressType.spark)
            .and()
            .subTypeEqualTo(AddressSubType.receiving)
            .valueProperty()
            .findAll();

    names.retainWhere((e) => myAddresses.contains(e.name));

    if (names.length != _myNames.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _myNames.addAll(names);
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _streamSubscription = ref
        .read(mainDBProvider)
        .isar
        .transactionV2s
        .where()
        .walletIdEqualTo(widget.walletId)
        .watch(fireImmediately: true)
        .listen((event) {
          if (mounted) {
            _updateNames();
          }
        });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._myNames.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OwnedSparkNameCard(
              key: ValueKey(e),
              name: e.name,
              address: e.address,
              walletId: widget.walletId,
            ),
          ),
        ),
        SizedBox(height: Util.isDesktop ? 14 : 6),
      ],
    );
  }
}

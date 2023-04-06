import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/my_token_select_item.dart';

class MyTokensList extends StatelessWidget {
  const MyTokensList({
    Key? key,
    required this.walletId,
    required this.searchTerm,
    required this.tokenContracts,
  }) : super(key: key);

  final String walletId;
  final String searchTerm;
  final List<String> tokenContracts;

  List<EthContract> _filter(String searchTerm) {
    if (tokenContracts.isEmpty) {
      return [];
    }

    if (searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      return MainDB.instance
          .getEthContracts()
          .filter()
          .anyOf<String, EthContract>(
              tokenContracts, (q, e) => q.addressEqualTo(e))
          .and()
          .group(
            (q) => q
                .nameContains(term, caseSensitive: false)
                .or()
                .symbolContains(term, caseSensitive: false)
                .or()
                .addressContains(term, caseSensitive: false),
          )
          .findAllSync();
      // return tokens.toList();
    }
    //implement search/filter
    return MainDB.instance
        .getEthContracts()
        .filter()
        .anyOf<String, EthContract>(
            tokenContracts, (q, e) => q.addressEqualTo(e))
        .findAllSync();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        final tokens = _filter(searchTerm);
        return ListView.builder(
          itemCount: tokens.length,
          itemBuilder: (ctx, index) {
            final token = tokens[index];
            return Padding(
              key: Key(token.address),
              padding: const EdgeInsets.all(4),
              child: MyTokenSelectItem(
                walletId: walletId,
                token: token,
              ),
            );
          },
        );
      },
    );
  }
}
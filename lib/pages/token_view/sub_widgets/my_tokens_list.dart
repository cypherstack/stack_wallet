import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/my_token_select_item.dart';

class MyTokensList extends StatelessWidget {
  const MyTokensList({
    Key? key,
    required this.walletId,
    required this.tokens,
  }) : super(key: key);

  final String walletId;
  final List<EthContractInfo> tokens;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        return ListView.builder(
          itemCount: tokens.length,
          itemBuilder: (ctx, index) {
            final token = tokens[index];
            return Padding(
              key: Key(token.contractAddress),
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

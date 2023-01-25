import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/my_token_select_item.dart';
import 'package:stackwallet/services/coins/manager.dart';

class MyTokensList extends StatelessWidget {
  const MyTokensList({
    Key? key,
    required this.managerProvider,
    required this.walletId,
    required this.tokens,
    required this.walletAddress,
  }) : super(key: key);

  final ChangeNotifierProvider<Manager> managerProvider;
  final String walletId;
  final List<dynamic> tokens;
  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        print("TOKENS LENGTH IS ${tokens.length}");
        return ListView.builder(
          itemCount: tokens.length,
          itemBuilder: (ctx, index) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: MyTokenSelectItem(
                managerProvider: managerProvider,
                walletId: walletId,
                walletAddress: walletAddress,
                tokenData: tokens[index] as Map<dynamic, dynamic>,
              ),
            );
          },
        );
      },
    );
  }
}

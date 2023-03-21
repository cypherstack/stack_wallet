import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:stackduo/pages/wallet_view/transaction_views/all_transactions_view.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/custom_buttons/blue_text_button.dart';

class RecentDesktopTransactions extends ConsumerStatefulWidget {
  const RecentDesktopTransactions({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<RecentDesktopTransactions> createState() =>
      _RecentDesktopTransactionsState();
}

class _RecentDesktopTransactionsState
    extends ConsumerState<RecentDesktopTransactions> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent transactions",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveSearchIconLeft,
              ),
            ),
            CustomTextButton(
              text: "See all",
              onTap: () {
                Navigator.of(context).pushNamed(
                  AllTransactionsView.routeName,
                  arguments: widget.walletId,
                );
              },
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        Expanded(
          child: TransactionsList(
            managerProvider: ref.watch(walletsChangeNotifierProvider
                .select((value) => value.getManagerProvider(widget.walletId))),
            walletId: widget.walletId,
          ),
        ),
      ],
    );
  }
}

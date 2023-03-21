import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackduo/db/main_db.dart';
import 'package:stackduo/models/isar/models/isar_models.dart';
import 'package:stackduo/pages/receive_view/addresses/address_card.dart';
import 'package:stackduo/providers/global/wallets_provider.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/utilities/util.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/loading_indicator.dart';
import 'package:stackduo/widgets/toggle.dart';

class WalletAddressesView extends ConsumerStatefulWidget {
  const WalletAddressesView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/walletAddressesView";

  final String walletId;

  @override
  ConsumerState<WalletAddressesView> createState() =>
      _WalletAddressesViewState();
}

class _WalletAddressesViewState extends ConsumerState<WalletAddressesView> {
  final bool isDesktop = Util.isDesktop;

  bool _showChange = false;

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId).coin));
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) => Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.backgroundAppBar,
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: Text(
              "Wallet addresses",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: isDesktop ? 56 : 48,
            width: isDesktop ? 490 : null,
            child: Toggle(
              key: UniqueKey(),
              onColor: Theme.of(context).extension<StackColors>()!.popupBG,
              onText: "Receiving",
              offColor: Theme.of(context)
                  .extension<StackColors>()!
                  .textFieldDefaultBG,
              offText: "Change",
              isOn: _showChange,
              onValueChanged: (value) {
                setState(() {
                  _showChange = value;
                });
              },
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
            ),
          ),
          SizedBox(
            height: isDesktop ? 20 : 16,
          ),
          Expanded(
            child: FutureBuilder(
              future: MainDB.instance
                  .getAddresses(widget.walletId)
                  .filter()
                  .group(
                    (q) => _showChange
                        ? q.subTypeEqualTo(AddressSubType.change)
                        : q
                            .subTypeEqualTo(AddressSubType.receiving)
                            .or()
                            .subTypeEqualTo(AddressSubType.paynymReceive),
                  )
                  .and()
                  .not()
                  .typeEqualTo(AddressType.nonWallet)
                  .sortByDerivationIndex()
                  .idProperty()
                  .findAll(),
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  // listview
                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => Container(
                      height: 10,
                    ),
                    itemBuilder: (_, index) => AddressCard(
                      walletId: widget.walletId,
                      addressId: snapshot.data![index],
                      coin: coin,
                    ),
                  );
                } else {
                  return const Center(
                    child: LoadingIndicator(
                      height: 200,
                      width: 200,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

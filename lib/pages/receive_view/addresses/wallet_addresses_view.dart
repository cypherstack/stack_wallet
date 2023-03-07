import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_card.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/toggle.dart';

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ReceivingAddressesView extends ConsumerWidget {
  const ReceivingAddressesView({
    Key? key,
    required this.walletId,
    required this.isDesktop,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/receivingAddressesView";

  final String walletId;
  final bool isDesktop;
  final ClipboardInterface clipboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: Text(
              "Receiving addresses",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
      child: FutureBuilder(
        future: MainDB.instance
            .getAddresses(walletId)
            .filter()
            .subTypeEqualTo(AddressSubType.receiving)
            .and()
            .not()
            .typeEqualTo(AddressType.nonWallet)
            .sortByDerivationIndexDesc()
            .findAll(),
        builder: (context, AsyncSnapshot<List<Address>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            // listview
            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => Container(
                height: 10,
              ),
              itemBuilder: (_, index) => AddressCard(
                address: snapshot.data![index],
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
    );
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    Key? key,
    required this.address,
  }) : super(key: key);

  final Address address;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Row(
        children: [
          Text(
            address.value,
            style: STextStyles.itemSubtitle12(context),
          )
        ],
      ),
    );
  }
}

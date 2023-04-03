import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_details_view.dart';
import 'package:stackwallet/pages_desktop_specific/addresses/sub_widgets/desktop_address_list.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

final desktopSelectedAddressId = StateProvider.autoDispose<Id?>((ref) => null);

class DesktopWalletAddressesView extends ConsumerStatefulWidget {
  const DesktopWalletAddressesView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/desktopWalletAddressesView";

  final String walletId;

  @override
  ConsumerState<DesktopWalletAddressesView> createState() =>
      _DesktopWalletAddressesViewState();
}

class _DesktopWalletAddressesViewState
    extends ConsumerState<DesktopWalletAddressesView> {
  static const _headerHeight = 70.0;
  static const _columnWidth0 = 489.0;

  late final Stream<void> addressCollectionWatcher;

  void _onAddressCollectionWatcherEvent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void initState() {
    addressCollectionWatcher =
        MainDB.instance.isar.addresses.watchLazy(fireImmediately: true);
    addressCollectionWatcher.listen((_) => _onAddressCollectionWatcherEvent());

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));

    return DesktopScaffold(
      appBar: DesktopAppBar(
        background: Theme.of(context).extension<StackColors>()!.popupBG,
        leading: Expanded(
          child: Row(
            children: [
              const SizedBox(
                width: 32,
              ),
              AppBarIconButton(
                size: 32,
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldDefaultBG,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.arrowLeft,
                  width: 18,
                  height: 18,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .topNavIconPrimary,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                "Address list",
                style: STextStyles.desktopH3(context),
              ),
              const Spacer(),
            ],
          ),
        ),
        useSpacers: false,
        isCompactHeight: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: _columnWidth0,
                    child: DesktopAddressList(
                      searchHeight: _headerHeight,
                      walletId: widget.walletId,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: _headerHeight,
                        ),
                        if (ref.watch(desktopSelectedAddressId.state).state !=
                            null)
                          Expanded(
                            child: SingleChildScrollView(
                              child: AddressDetailsView(
                                key: Key(
                                    "currentDesktopAddressDetails_key_${ref.watch(desktopSelectedAddressId.state).state}"),
                                walletId: widget.walletId,
                                addressId: ref
                                    .watch(desktopSelectedAddressId.state)
                                    .state!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

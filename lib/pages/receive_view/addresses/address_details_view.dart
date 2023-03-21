import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/transactions_list.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_edit_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddressDetailsView extends ConsumerStatefulWidget {
  const AddressDetailsView({
    Key? key,
    required this.addressId,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/addressDetailsView";

  final Id addressId;
  final String walletId;

  @override
  ConsumerState<AddressDetailsView> createState() => _AddressDetailsViewState();
}

class _AddressDetailsViewState extends ConsumerState<AddressDetailsView> {
  final _qrKey = GlobalKey();
  final isDesktop = Util.isDesktop;

  late Stream<AddressLabel?> stream;
  late final Address address;

  AddressLabel? label;

  @override
  void initState() {
    address = MainDB.instance.isar.addresses
        .where()
        .idEqualTo(widget.addressId)
        .findFirstSync()!;

    label = MainDB.instance.getAddressLabelSync(widget.walletId, address.value);
    Id? id = label?.id;
    if (id == null) {
      label = AddressLabel(
        walletId: widget.walletId,
        addressString: address.value,
        value: "",
        tags: address.subType == AddressSubType.receiving
            ? ["receiving"]
            : address.subType == AddressSubType.change
                ? ["change"]
                : null,
      );
      id = MainDB.instance.putAddressLabelSync(label!);
    }
    stream = MainDB.instance.watchAddressLabel(id: id);

    super.initState();
  }

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
          body: SafeArea(
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        child: child,
                      ),
                    ),
                  )
                ];
              },
              body: TransactionsList(
                  walletId: widget.walletId,
                  managerProvider: ref.watch(
                      walletsChangeNotifierProvider.select((value) =>
                          value.getManagerProvider(widget.walletId)))),
            ),
          ),
        ),
      ),
      child: StreamBuilder<AddressLabel?>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            label = snapshot.data!;
          }

          return Column(
            children: [
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: QrImage(
                    data: AddressUtils.buildUriString(
                      coin,
                      address.value,
                      {},
                    ),
                    size: 220,
                    backgroundColor:
                        Theme.of(context).extension<StackColors>()!.background,
                    foregroundColor: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              _Item(
                title: "Address",
                data: address.value,
                button: SimpleCopyButton(
                  data: address.value,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              _Item(
                title: "Label",
                data: label!.value,
                button: SimpleEditButton(
                  editValue: label!.value,
                  editLabel: 'label',
                  onValueChanged: (value) {
                    MainDB.instance.putAddressLabel(
                      label!.copyWith(
                        label: value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              _Tags(
                tags: label!.tags,
              ),
              if (address.derivationPath != null)
                const SizedBox(
                  height: 12,
                ),
              if (address.derivationPath != null)
                _Item(
                  title: "Derivation path",
                  data: address.derivationPath!.value,
                  button: SimpleEditButton(
                    editValue: label!.value,
                    editLabel: 'label',
                    onValueChanged: (value) {
                      MainDB.instance.putAddressLabel(
                        label!.copyWith(
                          label: value,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(
                height: 12,
              ),
              _Item(
                title: "Type",
                data: address.type.readableName,
                button: Container(),
              ),
              const SizedBox(
                height: 12,
              ),
              _Item(
                title: "Sub type",
                data: address.subType.prettyName,
                button: Container(),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Transactions",
                style: STextStyles.itemSubtitle(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({
    Key? key,
    required this.tags,
  }) : super(key: key);

  final List<String>? tags;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tags",
                style: STextStyles.itemSubtitle(context),
              ),
              SimpleEditButton(
                onPressedOverride: () {
                  // TODO edit tags
                },
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          tags != null && tags!.isNotEmpty
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tags!
                      .map(
                        (e) => AddressTag(
                          tag: e,
                        ),
                      )
                      .toList(),
                )
              : Text(
                  "Tags will appear here",
                  style: STextStyles.w500_14(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle3,
                  ),
                ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.title,
    required this.data,
    required this.button,
  }) : super(key: key);

  final String title;
  final String data;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: STextStyles.itemSubtitle(context),
              ),
              button,
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          data.isNotEmpty
              ? SelectableText(
                  data,
                  style: STextStyles.w500_14(context),
                )
              : Text(
                  "$title will appear here",
                  style: STextStyles.w500_14(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textSubtitle3,
                  ),
                ),
        ],
      ),
    );
  }
}

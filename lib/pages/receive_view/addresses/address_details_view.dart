import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/no_transactions_found.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_copy_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_edit_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/transaction_card.dart';

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

  void _showDesktopAddressQrCode() {
    showDialog<void>(
      context: context,
      builder: (context) => DesktopDialog(
        maxWidth: 480,
        maxHeight: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Address QR code",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: AddressUtils.buildUriString(
                          ref.watch(walletsChangeNotifierProvider.select(
                              (value) =>
                                  value.getManager(widget.walletId).coin)),
                          address.value,
                          {},
                        ),
                        size: 220,
                        backgroundColor:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        foregroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 32,
            ),
          ],
        ),
      ),
    );
  }

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
              "Address details",
              style: STextStyles.navBarTitle(context),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (builderContext, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                );
              },
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

          return ConditionalParent(
            condition: isDesktop,
            builder: (child) {
              return Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  RoundedWhiteContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Address details",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                            CustomTextButton(
                              text: "View QR code",
                              onTap: _showDesktopAddressQrCode,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        RoundedWhiteContainer(
                          padding: EdgeInsets.zero,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .backgroundAppBar,
                          child: child,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Transaction history",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                      context)
                                  .copyWith(
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textSubtitle1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          padding: EdgeInsets.zero,
                          borderColor: Theme.of(context)
                              .extension<StackColors>()!
                              .backgroundAppBar,
                          child: _AddressDetailsTxList(
                            walletId: widget.walletId,
                            address: address,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isDesktop)
                  Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: AddressUtils.buildUriString(
                          ref.watch(walletsChangeNotifierProvider.select(
                              (value) =>
                                  value.getManager(widget.walletId).coin)),
                          address.value,
                          {},
                        ),
                        size: 220,
                        backgroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .background,
                        foregroundColor: Theme.of(context)
                            .extension<StackColors>()!
                            .accentColorDark,
                      ),
                    ),
                  ),
                if (!isDesktop)
                  const SizedBox(
                    height: 16,
                  ),
                _Item(
                  title: "Address",
                  data: address.value,
                  button: isDesktop
                      ? IconCopyButton(
                          data: address.value,
                        )
                      : SimpleCopyButton(
                          data: address.value,
                        ),
                ),
                const _Div(
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
                const _Div(
                  height: 12,
                ),
                _Tags(
                  tags: label!.tags,
                ),
                if (address.derivationPath != null)
                  const _Div(
                    height: 12,
                  ),
                if (address.derivationPath != null)
                  _Item(
                    title: "Derivation path",
                    data: address.derivationPath!.value,
                    button: Container(),
                  ),
                const _Div(
                  height: 12,
                ),
                _Item(
                  title: "Type",
                  data: address.type.readableName,
                  button: Container(),
                ),
                const _Div(
                  height: 12,
                ),
                _Item(
                  title: "Sub type",
                  data: address.subType.prettyName,
                  button: Container(),
                ),
                if (!isDesktop)
                  const SizedBox(
                    height: 20,
                  ),
                if (!isDesktop)
                  Text(
                    "Transactions",
                    textAlign: TextAlign.left,
                    style: STextStyles.itemSubtitle(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark3,
                    ),
                  ),
                if (!isDesktop)
                  const SizedBox(
                    height: 12,
                  ),
                if (!isDesktop)
                  _AddressDetailsTxList(
                    walletId: widget.walletId,
                    address: address,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddressDetailsTxList extends StatelessWidget {
  const _AddressDetailsTxList({
    Key? key,
    required this.walletId,
    required this.address,
  }) : super(key: key);

  final String walletId;
  final Address address;

  @override
  Widget build(BuildContext context) {
    final query = MainDB.instance
        .getTransactions(walletId)
        .filter()
        .address((q) => q.valueEqualTo(address.value));

    final count = query.countSync();

    if (count > 0) {
      if (Util.isDesktop) {
        final txns = query.findAllSync();
        return ListView.separated(
          shrinkWrap: true,
          primary: false,
          itemBuilder: (_, index) => TransactionCard(
            transaction: txns[index],
            walletId: walletId,
          ),
          separatorBuilder: (_, __) => const _Div(height: 1),
          itemCount: count,
        );
      } else {
        return RoundedWhiteContainer(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: query
                .findAllSync()
                .map(
                  (e) => TransactionCard(
                    transaction: e,
                    walletId: walletId,
                  ),
                )
                .toList(),
          ),
        );
      }
    } else {
      return const NoTransActionsFound();
    }
  }
}

class _Div extends StatelessWidget {
  const _Div({
    Key? key,
    required this.height,
  }) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    if (Util.isDesktop) {
      return Container(
        color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
        height: 1,
        width: double.infinity,
      );
    } else {
      return SizedBox(
        height: height,
      );
    }
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
              Container(),
              // SimpleEditButton(
              //   onPressedOverride: () {
              //     // TODO edit tags
              //   },
              // ),
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
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) => RoundedWhiteContainer(
        child: child,
      ),
      child: ConditionalParent(
        condition: Util.isDesktop,
        builder: (child) => Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
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
      ),
    );
  }
}

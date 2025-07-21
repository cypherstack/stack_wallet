import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';

import '../../../providers/providers.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/util.dart';
import '../../../wallets/models/tx_data.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/stack_dialog.dart';
import '../../db/drift/database.dart';
import '../../models/isar/models/blockchain_data/address.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/amount/amount_formatter.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/show_loading.dart';
import '../../utilities/text_styles.dart';
import '../../wallets/crypto_currency/coins/firo.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import '../../widgets/background.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/custom_buttons/blue_text_button.dart';
import '../../widgets/dialogs/s_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import 'confirm_spark_name_transaction_view.dart';

class BuySparkNameView extends ConsumerStatefulWidget {
  const BuySparkNameView({
    super.key,
    required this.walletId,
    required this.name,
    this.nameToRenew,
  });

  final String walletId;
  final String name;
  final SparkName? nameToRenew;

  static const routeName = "/buySparkNameView";

  @override
  ConsumerState<BuySparkNameView> createState() => _BuySparkNameViewState();
}

class _BuySparkNameViewState extends ConsumerState<BuySparkNameView> {
  final addressController = TextEditingController();
  final additionalInfoController = TextEditingController();

  bool get isRenewal => widget.nameToRenew != null;
  String get _title => isRenewal ? "Renew name" : "Buy name";

  int _years = 1;

  bool _lockAddressFill = false;
  Future<void> _fillCurrentReceiving() async {
    if (_lockAddressFill) return;
    _lockAddressFill = true;
    try {
      final wallet =
          ref.read(pWallets).getWallet(widget.walletId) as SparkInterface;
      final myAddress = await wallet.getCurrentReceivingSparkAddress();
      if (myAddress == null) {
        throw Exception("No spark address found");
      }
      addressController.text = myAddress.value;
    } catch (e, s) {
      Logging.instance.e("_fillCurrentReceiving", error: e, stackTrace: s);
    } finally {
      _lockAddressFill = false;
    }
  }

  Future<TxData> _preRegFuture() async {
    final chosenAddress = addressController.text;

    if (chosenAddress.isEmpty) {
      throw Exception(
        "Please select the Spark address you want to link to your Spark Name",
      );
    }

    final wallet =
        ref.read(pWallets).getWallet(widget.walletId) as SparkInterface;

    if (!(wallet.cryptoCurrency as Firo).validateSparkAddress(chosenAddress)) {
      throw Exception("Invalid Spark address selected");
    }

    final myAddresses =
        await wallet.mainDB.isar.addresses
            .where()
            .walletIdEqualTo(widget.walletId)
            .filter()
            .typeEqualTo(AddressType.spark)
            .and()
            .subTypeEqualTo(AddressSubType.receiving)
            .valueProperty()
            .findAll();

    if (!myAddresses.contains(chosenAddress)) {
      throw Exception("Selected Spark address does not belong to this wallet");
    }

    final txData = await wallet.prepareSparkNameTransaction(
      name: widget.name,
      address: chosenAddress,
      years: _years,
      additionalInfo: additionalInfoController.text,
    );
    return txData;
  }

  bool _preRegLock = false;
  Future<void> _prepareNameTx() async {
    if (_preRegLock) return;
    _preRegLock = true;
    try {
      final txData =
          (await showLoading(
            whileFuture: _preRegFuture(),
            context: context,
            message: "Preparing transaction...",
            onException: (e) {
              throw e;
            },
          ))!;

      if (mounted) {
        if (Util.isDesktop) {
          await showDialog<void>(
            context: context,
            builder:
                (context) => SDialog(
                  child: SizedBox(
                    width: 580,
                    child: ConfirmSparkNameTransactionView(
                      txData: txData,
                      walletId: widget.walletId,
                    ),
                  ),
                ),
          );
        } else {
          await Navigator.of(context).pushNamed(
            ConfirmSparkNameTransactionView.routeName,
            arguments: (walletId: widget.walletId, txData: txData),
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e("_prepareNameTx failed", error: e, stackTrace: s);

      if (mounted) {
        String err = e.toString();
        if (err.startsWith("Exception: ")) {
          err = err.replaceFirst("Exception: ", "");
        }

        await showDialog<void>(
          context: context,
          builder:
              (_) => StackOkDialog(
                title: "Error",
                message: err,
                desktopPopRootNavigator: Util.isDesktop,
                maxWidth: Util.isDesktop ? 600 : null,
              ),
        );
      }
    } finally {
      _preRegLock = false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (isRenewal) {
      additionalInfoController.text = widget.nameToRenew!.additionalInfo ?? "";
      addressController.text = widget.nameToRenew!.address;
    }
  }

  @override
  void dispose() {
    additionalInfoController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(pWalletCoin(widget.walletId));
    return ConditionalParent(
      condition: !Util.isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              leading: const AppBarBackButton(),
              titleSpacing: 0,
              title: Text(
                _title,
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment:
            Util.isDesktop
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.stretch,
        children: [
          RoundedWhiteContainer(
            padding: EdgeInsets.all(Util.isDesktop ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Name",
                  style:
                      Util.isDesktop
                          ? STextStyles.w500_14(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          )
                          : STextStyles.w500_12(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          ),
                ),
                Text(
                  widget.name,
                  style:
                      Util.isDesktop
                          ? STextStyles.w500_14(context)
                          : STextStyles.w500_12(context),
                ),
              ],
            ),
          ),
          SizedBox(height: Util.isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            padding: EdgeInsets.all(Util.isDesktop ? 0 : 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Spark address",
                      style:
                          Util.isDesktop
                              ? STextStyles.w500_14(context).copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).extension<StackColors>()!.infoItemLabel,
                              )
                              : STextStyles.w500_12(context).copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).extension<StackColors>()!.infoItemLabel,
                              ),
                    ),
                    CustomTextButton(
                      text: "Use current",
                      onTap: _fillCurrentReceiving,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    controller: addressController,
                    readOnly: isRenewal,
                    textAlignVertical: TextAlignVertical.center,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(16),
                      hintStyle: STextStyles.fieldLabel(context),
                      hintText: "Spark address (required)",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Util.isDesktop ? 16 : 8),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Additional info",
                    style:
                        Util.isDesktop
                            ? STextStyles.w500_14(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.infoItemLabel,
                            )
                            : STextStyles.w500_12(context).copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).extension<StackColors>()!.infoItemLabel,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RoundedWhiteContainer(
                padding: EdgeInsets.all(Util.isDesktop ? 0 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  child: TextField(
                    controller: additionalInfoController,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(16),
                      hintStyle: STextStyles.fieldLabel(context),
                      hintText: "Additional info (optional)",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Util.isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            padding: EdgeInsets.all(Util.isDesktop ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${isRenewal ? "Renew" : "Register"} for",
                  style:
                      Util.isDesktop
                          ? STextStyles.w500_14(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          )
                          : STextStyles.w500_12(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          ),
                ),
                SizedBox(
                  width: Util.isDesktop ? 180 : 140,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<int>(
                      value: _years,
                      items: [
                        ...List.generate(10, (i) => i + 1).map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              "$e years",
                              style: STextStyles.w500_14(context),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value is int) {
                          setState(() {
                            _years = value;
                          });
                        }
                      },
                      isExpanded: true,
                      buttonStyleData: ButtonStyleData(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.textFieldDefaultBG,
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                        ),
                      ),
                      iconStyleData: IconStyleData(
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SvgPicture.asset(
                            Assets.svg.chevronDown,
                            width: 12,
                            height: 6,
                            color:
                                Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFieldActiveSearchIconRight,
                          ),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        offset: const Offset(0, -10),
                        elevation: 0,
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.textFieldDefaultBG,
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Util.isDesktop ? 16 : 8),
          RoundedWhiteContainer(
            padding: EdgeInsets.all(Util.isDesktop ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cost",
                  style:
                      Util.isDesktop
                          ? STextStyles.w500_14(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          )
                          : STextStyles.w500_12(context).copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.infoItemLabel,
                          ),
                ),
                Text(
                  ref
                      .watch(pAmountFormatter(coin))
                      .format(
                        Amount.fromDecimal(
                          Decimal.fromInt(
                            kStandardSparkNamesFee[widget.name.length] * _years,
                          ),
                          fractionDigits: coin.fractionDigits,
                        ),
                      ),
                  style:
                      Util.isDesktop
                          ? STextStyles.w500_14(context)
                          : STextStyles.w500_12(context),
                ),
              ],
            ),
          ),

          SizedBox(height: Util.isDesktop ? 32 : 16),
          if (!Util.isDesktop) const Spacer(),
          PrimaryButton(
            label: isRenewal ? "Renew" : "Buy",
            buttonHeight: Util.isDesktop ? ButtonHeight.l : null,
            onPressed: _prepareNameTx,
          ),
          SizedBox(height: Util.isDesktop ? 32 : 16),
        ],
      ),
    );
  }
}

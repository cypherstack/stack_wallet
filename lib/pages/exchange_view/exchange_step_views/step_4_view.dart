import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/confirm_change_now_send.dart';
import 'package:stackwallet/pages/exchange_view/send_from_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class Step4View extends ConsumerStatefulWidget {
  const Step4View({
    Key? key,
    required this.model,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/exchangeStep4";

  final IncompleteExchangeModel model;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<Step4View> createState() => _Step4ViewState();
}

class _Step4ViewState extends ConsumerState<Step4View> {
  late final IncompleteExchangeModel model;
  late final ClipboardInterface clipboard;

  String _statusString = "New";
  ChangeNowTransactionStatus _status = ChangeNowTransactionStatus.New;

  Timer? _statusTimer;

  bool _isWalletCoinAndHasWallet(String ticker, WidgetRef ref) {
    try {
      final coin = coinFromTickerCaseInsensitive(ticker);
      return ref
          .read(walletsChangeNotifierProvider)
          .managers
          .where((element) => element.coin == coin)
          .isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateStatus() async {
    final statusResponse = await ref
        .read(changeNowProvider)
        .getTransactionStatus(id: model.trade!.id);
    String status = "Waiting";
    if (statusResponse.value != null) {
      _status = statusResponse.value!.status;
      status = _status.name;
    }

    // extra info if status is waiting
    if (status == "Waiting") {
      status += " for deposit";
    }

    if (mounted) {
      setState(() {
        _statusString = status;
      });
    }
  }

  @override
  void initState() {
    model = widget.model;
    clipboard = widget.clipboard;

    _statusTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateStatus();
    });

    super.initState();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _statusTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWalletCoin =
        _isWalletCoinAndHasWallet(model.trade!.fromCurrency, ref);
    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Exchange",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width - 32;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StepRow(
                          count: 4,
                          current: 3,
                          width: width,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          "Send ${model.sendTicker} to the address below",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Send ${model.sendTicker} to the address below. Once it is received, ChangeNOW will send the ${model.receiveTicker} to the recipient address you provided. You can find this trade details and check its status in the list of trades.",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedContainer(
                          color: CFColors.warningBackground,
                          child: RichText(
                            text: TextSpan(
                              text:
                                  "You must send at least ${model.sendAmount.toString()} ${model.sendTicker}. ",
                              style: STextStyles.label.copyWith(
                                color: CFColors.stackAccent,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      "If you send less than ${model.sendAmount.toString()} ${model.sendTicker}, your transaction may not be converted and it may not be refunded.",
                                  style: STextStyles.label.copyWith(
                                    color: CFColors.stackAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Amount",
                                    style: STextStyles.itemSubtitle.copyWith(
                                      color: CFColors.neutral50,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final data = ClipboardData(
                                          text: model.sendAmount.toString());
                                      await clipboard.setData(data);
                                      unawaited(showFloatingFlushBar(
                                        type: FlushBarType.info,
                                        message: "Copied to clipboard",
                                        context: context,
                                      ));
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          Assets.svg.copy,
                                          color: StackTheme
                                              .instance.color.infoItemIcons,
                                          width: 10,
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          "Copy",
                                          style: STextStyles.link2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                "${model.sendAmount.toString()} ${model.sendTicker}",
                                style: STextStyles.itemSubtitle12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Send ${model.sendTicker} to this address",
                                    style: STextStyles.itemSubtitle.copyWith(
                                      color: CFColors.neutral50,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final data = ClipboardData(
                                          text: model.trade!.payinAddress);
                                      await clipboard.setData(data);
                                      unawaited(showFloatingFlushBar(
                                        type: FlushBarType.info,
                                        message: "Copied to clipboard",
                                        context: context,
                                      ));
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          Assets.svg.copy,
                                          color: StackTheme
                                              .instance.color.infoItemIcons,
                                          width: 10,
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          "Copy",
                                          style: STextStyles.link2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                model.trade!.payinAddress,
                                style: STextStyles.itemSubtitle12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            children: [
                              Text(
                                "Trade ID",
                                style: STextStyles.itemSubtitle,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    model.trade!.id,
                                    style: STextStyles.itemSubtitle12,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final data =
                                          ClipboardData(text: model.trade!.id);
                                      await clipboard.setData(data);
                                      unawaited(showFloatingFlushBar(
                                        type: FlushBarType.info,
                                        message: "Copied to clipboard",
                                        context: context,
                                      ));
                                    },
                                    child: SvgPicture.asset(
                                      Assets.svg.copy,
                                      color: StackTheme
                                          .instance.color.infoItemIcons,
                                      width: 12,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Status",
                                style: STextStyles.itemSubtitle.copyWith(
                                  color: CFColors.neutral50,
                                ),
                              ),
                              Text(
                                _statusString,
                                style: STextStyles.itemSubtitle.copyWith(
                                  color: CFColors.status.forStatus(_status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(
                          height: 12,
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog<dynamic>(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) {
                                return StackDialogBase(
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Center(
                                        child: Text(
                                          "Send ${model.sendTicker} to this address",
                                          style: STextStyles.pageTitleH2,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Center(
                                        child: QrImage(
                                          // TODO: grab coin uri scheme from somewhere
                                          // data: "${coin.uriScheme}:$receivingAddress",
                                          data: model.trade!.payinAddress,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2,
                                          foregroundColor: CFColors.stackAccent,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Row(
                                        children: [
                                          const Spacer(),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Text(
                                                "Cancel",
                                                style:
                                                    STextStyles.button.copyWith(
                                                  color: CFColors.stackAccent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          style:
                              Theme.of(context).textButtonTheme.style?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      CFColors.stackAccent,
                                    ),
                                  ),
                          child: Text(
                            "Show QR Code",
                            style: STextStyles.button,
                          ),
                        ),
                        if (isWalletCoin)
                          const SizedBox(
                            height: 12,
                          ),
                        if (isWalletCoin)
                          Builder(
                            builder: (context) {
                              String buttonTitle = "Send from Stack Wallet";

                              final tuple = ref
                                  .read(exchangeSendFromWalletIdStateProvider
                                      .state)
                                  .state;
                              if (tuple != null &&
                                  model.sendTicker.toLowerCase() ==
                                      tuple.item2.ticker.toLowerCase()) {
                                final walletName = ref
                                    .read(walletsChangeNotifierProvider)
                                    .getManager(tuple.item1)
                                    .walletName;
                                buttonTitle = "Send from $walletName";
                              }

                              return TextButton(
                                onPressed: tuple != null &&
                                        model.sendTicker.toLowerCase() ==
                                            tuple.item2.ticker.toLowerCase()
                                    ? () async {
                                        final manager = ref
                                            .read(walletsChangeNotifierProvider)
                                            .getManager(tuple.item1);

                                        final amount =
                                            Format.decimalAmountToSatoshis(
                                                model.sendAmount);
                                        final address =
                                            model.trade!.payinAddress;

                                        try {
                                          bool wasCancelled = false;

                                          unawaited(showDialog<dynamic>(
                                            context: context,
                                            useSafeArea: false,
                                            barrierDismissible: false,
                                            builder: (context) {
                                              return BuildingTransactionDialog(
                                                onCancel: () {
                                                  wasCancelled = true;

                                                  Navigator.of(context).pop();
                                                },
                                              );
                                            },
                                          ));

                                          final txData =
                                              await manager.prepareSend(
                                            address: address,
                                            satoshiAmount: amount,
                                            args: {
                                              "feeRate": FeeRateType.average,
                                              // ref.read(feeRateTypeStateProvider)
                                            },
                                          );

                                          if (!wasCancelled) {
                                            // pop building dialog

                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }

                                            txData["note"] =
                                                "${model.trade!.fromCurrency.toUpperCase()}/${model.trade!.toCurrency.toUpperCase()} exchange";
                                            txData["address"] = address;

                                            if (mounted) {
                                              unawaited(
                                                  Navigator.of(context).push(
                                                RouteGenerator.getRoute(
                                                  shouldUseMaterialRoute:
                                                      RouteGenerator
                                                          .useMaterialPageRoute,
                                                  builder: (_) =>
                                                      ConfirmChangeNowSendView(
                                                    transactionInfo: txData,
                                                    walletId: tuple.item1,
                                                    routeOnSuccessName:
                                                        HomeView.routeName,
                                                    trade: model.trade!,
                                                  ),
                                                  settings: const RouteSettings(
                                                    name:
                                                        ConfirmChangeNowSendView
                                                            .routeName,
                                                  ),
                                                ),
                                              ));
                                            }
                                          }
                                        } catch (e) {
                                          // if (mounted) {
                                          // pop building dialog
                                          Navigator.of(context).pop();

                                          unawaited(showDialog<dynamic>(
                                            context: context,
                                            useSafeArea: false,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              return StackDialog(
                                                title: "Transaction failed",
                                                message: e.toString(),
                                                rightButton: TextButton(
                                                  style: StackTheme.instance
                                                      .getSecondaryEnabledButtonColor(
                                                          context),
                                                  child: Text(
                                                    "Ok",
                                                    style: STextStyles.button
                                                        .copyWith(
                                                      color:
                                                          CFColors.stackAccent,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              );
                                            },
                                          ));
                                          // }
                                        }
                                      }
                                    : () {
                                        Navigator.of(context).push(
                                          RouteGenerator.getRoute(
                                            shouldUseMaterialRoute:
                                                RouteGenerator
                                                    .useMaterialPageRoute,
                                            builder: (BuildContext context) {
                                              return SendFromView(
                                                coin:
                                                    coinFromTickerCaseInsensitive(
                                                        model.trade!
                                                            .fromCurrency),
                                                amount: model.sendAmount,
                                                address:
                                                    model.trade!.payinAddress,
                                                trade: model.trade!,
                                              );
                                            },
                                            settings: const RouteSettings(
                                              name: SendFromView.routeName,
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  buttonTitle,
                                  style: STextStyles.button.copyWith(
                                    color: CFColors.stackAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

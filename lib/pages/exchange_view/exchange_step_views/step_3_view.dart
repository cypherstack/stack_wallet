import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_4_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class Step3View extends ConsumerStatefulWidget {
  const Step3View({
    Key? key,
    required this.model,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/exchangeStep3";

  final IncompleteExchangeModel model;
  final ClipboardInterface clipboard;

  @override
  ConsumerState<Step3View> createState() => _Step3ViewState();
}

class _Step3ViewState extends ConsumerState<Step3View> {
  late final IncompleteExchangeModel model;
  late final ClipboardInterface clipboard;

  @override
  void initState() {
    model = widget.model;
    clipboard = widget.clipboard;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
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
                          current: 2,
                          width: width,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          "Confirm exchange details",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            children: [
                              Text(
                                "You send",
                                style: STextStyles.itemSubtitle,
                              ),
                              const Spacer(),
                              Text(
                                "${model.sendAmount.toString()} ${model.sendTicker}",
                                style: STextStyles.itemSubtitle12,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            children: [
                              Text(
                                "You receive",
                                style: STextStyles.itemSubtitle,
                              ),
                              const Spacer(),
                              Text(
                                "${model.receiveAmount.toString()} ${model.receiveTicker}",
                                style: STextStyles.itemSubtitle12,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            children: [
                              Text(
                                "Estimated rate",
                                style: STextStyles.itemSubtitle,
                              ),
                              const Spacer(),
                              Text(
                                model.rateInfo,
                                style: STextStyles.itemSubtitle12,
                              )
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
                              Text(
                                "Recipient ${model.receiveTicker} address",
                                style: STextStyles.itemSubtitle,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                model.recipientAddress!,
                                style: STextStyles.itemSubtitle12,
                              )
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
                              Text(
                                "Refund ${model.sendTicker} address",
                                style: STextStyles.itemSubtitle,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                model.refundAddress!,
                                style: STextStyles.itemSubtitle12,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Back",
                                  style: STextStyles.button.copyWith(
                                    color: CFColors.stackAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  ChangeNowResponse<ExchangeTransaction>
                                      response;
                                  if (model.rateType ==
                                      ExchangeRateType.estimated) {
                                    response = await ChangeNow
                                        .createStandardExchangeTransaction(
                                      fromTicker: model.sendTicker,
                                      toTicker: model.receiveTicker,
                                      receivingAddress: model.recipientAddress!,
                                      amount: model.sendAmount,
                                      refundAddress: model.refundAddress!,
                                    );
                                  } else {
                                    response = await ChangeNow
                                        .createFixedRateExchangeTransaction(
                                      fromTicker: model.sendTicker,
                                      toTicker: model.receiveTicker,
                                      receivingAddress: model.recipientAddress!,
                                      amount: model.sendAmount,
                                      refundAddress: model.refundAddress!,
                                      rateId: model.rateId!,
                                    );
                                  }

                                  if (response.value == null) {
                                    showDialog<void>(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) => StackDialog(
                                        title: "Failed to create trade",
                                        message: response.exception?.toString(),
                                      ),
                                    );
                                    return;
                                  }

                                  // save trade to hive
                                  await ref.read(tradesServiceProvider).add(
                                        trade: response.value!,
                                        shouldNotifyListeners: true,
                                      );

                                  final statusResponse =
                                      await ChangeNow.getTransactionStatus(
                                          id: response.value!.id);

                                  debugPrint("WTF: $statusResponse");

                                  String status = "Waiting";
                                  if (statusResponse.value != null) {
                                    status = statusResponse.value!.status.name;
                                  }

                                  model.trade = response.value!.copyWith(
                                    statusString: status,
                                    statusObject: statusResponse.value!,
                                  );

                                  // extra info if status is waiting
                                  if (status == "Waiting") {
                                    status += " for deposit";
                                  }

                                  NotificationApi.showNotification(
                                    changeNowId: model.trade!.id,
                                    title: status,
                                    body: "Trade ID ${model.trade!.id}",
                                    walletId: "",
                                    iconAssetName: Assets.svg.arrowRotate,
                                    date: model.trade!.date,
                                    shouldWatchForUpdates: true,
                                    coinName: "coinName",
                                  );

                                  if (mounted) {
                                    Navigator.of(context).pushNamed(
                                      Step4View.routeName,
                                      arguments: model,
                                    );
                                  }
                                },
                                style: Theme.of(context)
                                    .textButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        CFColors.stackAccent,
                                      ),
                                    ),
                                child: Text(
                                  "Next",
                                  style: STextStyles.button,
                                ),
                              ),
                            ),
                          ],
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

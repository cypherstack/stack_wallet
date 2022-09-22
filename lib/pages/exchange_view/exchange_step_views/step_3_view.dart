import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_4_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
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
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
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
          style: STextStyles.navBarTitle(context),
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
                          style: STextStyles.pageTitleH1(context),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            children: [
                              Text(
                                "You send",
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const Spacer(),
                              Text(
                                "${model.sendAmount.toString()} ${model.sendTicker.toUpperCase()}",
                                style: STextStyles.itemSubtitle12(context),
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
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const Spacer(),
                              Text(
                                "${model.receiveAmount.toString()} ${model.receiveTicker.toUpperCase()}",
                                style: STextStyles.itemSubtitle12(context),
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
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const Spacer(),
                              Text(
                                model.rateInfo,
                                style: STextStyles.itemSubtitle12(context),
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
                                "Recipient ${model.receiveTicker.toUpperCase()} address",
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                model.recipientAddress!,
                                style: STextStyles.itemSubtitle12(context),
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
                                "Refund ${model.sendTicker.toUpperCase()} address",
                                style: STextStyles.itemSubtitle(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                model.refundAddress!,
                                style: STextStyles.itemSubtitle12(context),
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
                                style: Theme.of(context)
                                    .extension<StackColors>()!
                                    .getSecondaryEnabledButtonColor(context),
                                child: Text(
                                  "Back",
                                  style: STextStyles.button(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .buttonTextSecondary,
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
                                    response = await ref
                                        .read(changeNowProvider)
                                        .createStandardExchangeTransaction(
                                          fromTicker: model.sendTicker,
                                          toTicker: model.receiveTicker,
                                          receivingAddress:
                                              model.recipientAddress!,
                                          amount: model.sendAmount,
                                          refundAddress: model.refundAddress!,
                                        );
                                  } else {
                                    response = await ref
                                        .read(changeNowProvider)
                                        .createFixedRateExchangeTransaction(
                                          fromTicker: model.sendTicker,
                                          toTicker: model.receiveTicker,
                                          receivingAddress:
                                              model.recipientAddress!,
                                          amount: model.sendAmount,
                                          refundAddress: model.refundAddress!,
                                          rateId: model.rateId!,
                                        );
                                  }

                                  if (response.value == null) {
                                    unawaited(showDialog<void>(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) => StackDialog(
                                        title: "Failed to create trade",
                                        message: response.exception?.toString(),
                                      ),
                                    ));
                                    return;
                                  }

                                  // save trade to hive
                                  await ref.read(tradesServiceProvider).add(
                                        trade: response.value!,
                                        shouldNotifyListeners: true,
                                      );

                                  final statusResponse = await ref
                                      .read(changeNowProvider)
                                      .getTransactionStatus(
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

                                  unawaited(NotificationApi.showNotification(
                                    changeNowId: model.trade!.id,
                                    title: status,
                                    body: "Trade ID ${model.trade!.id}",
                                    walletId: "",
                                    iconAssetName: Assets.svg.arrowRotate,
                                    date: model.trade!.date,
                                    shouldWatchForUpdates: true,
                                    coinName: "coinName",
                                  ));

                                  if (mounted) {
                                    unawaited(Navigator.of(context).pushNamed(
                                      Step4View.routeName,
                                      arguments: model,
                                    ));
                                  }
                                },
                                style: Theme.of(context)
                                    .extension<StackColors>()!
                                    .getPrimaryEnabledButtonColor(context),
                                child: Text(
                                  "Next",
                                  style: STextStyles.button(context),
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

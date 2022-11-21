import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_4.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_item.dart';
import 'package:stackwallet/providers/exchange/current_exchange_name_state_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/desktop/simple_desktop_dialog.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopStep3 extends ConsumerStatefulWidget {
  const DesktopStep3({
    Key? key,
    required this.model,
  }) : super(key: key);

  final IncompleteExchangeModel model;

  @override
  ConsumerState<DesktopStep3> createState() => _DesktopStep3State();
}

class _DesktopStep3State extends ConsumerState<DesktopStep3> {
  late final IncompleteExchangeModel model;

  Future<void> createTrade() async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.6),
            child: const CustomLoadingOverlay(
              message: "Creating a trade",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    final ExchangeResponse<Trade> response =
        await ref.read(exchangeProvider).createTrade(
              from: model.sendTicker,
              to: model.receiveTicker,
              fixedRate: model.rateType != ExchangeRateType.estimated,
              amount: model.reversed ? model.receiveAmount : model.sendAmount,
              addressTo: model.recipientAddress!,
              extraId: null,
              addressRefund: model.refundAddress!,
              refundExtraId: "",
              rateId: model.rateId,
              reversed: model.reversed,
            );

    if (response.value == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (_) => SimpleDesktopDialog(
              title: "Failed to create trade",
              message: response.exception?.toString() ?? ""),
        ),
      );
      return;
    }

    // save trade to hive
    await ref.read(tradesServiceProvider).add(
          trade: response.value!,
          shouldNotifyListeners: true,
        );

    String status = response.value!.status;

    model.trade = response.value!;

    // extra info if status is waiting
    if (status == "Waiting") {
      status += " for deposit";
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    unawaited(
      NotificationApi.showNotification(
        changeNowId: model.trade!.tradeId,
        title: status,
        body: "Trade ID ${model.trade!.tradeId}",
        walletId: "",
        iconAssetName: Assets.svg.arrowRotate,
        date: model.trade!.timestamp,
        shouldWatchForUpdates: true,
        coinName: "coinName",
      ),
    );

    if (mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          barrierColor: Colors.transparent,
          barrierDismissible: false,
          builder: (context) {
            return DesktopDialog(
              maxWidth: 720,
              maxHeight: double.infinity,
              child: StepScaffold(
                step: 4,
                model: model,
                body: DesktopStep4(
                  model: model,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void initState() {
    model = widget.model;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Confirm exchange details",
          style: STextStyles.desktopTextMedium(context),
        ),
        const SizedBox(
          height: 20,
        ),
        RoundedWhiteContainer(
          borderColor: Theme.of(context).extension<StackColors>()!.background,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              DesktopStepItem(
                label: "Exchange",
                value: ref.watch(currentExchangeNameStateProvider.state).state,
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "You send",
                value:
                    "${model.sendAmount.toStringAsFixed(8)} ${model.sendTicker.toUpperCase()}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "You receive",
                value:
                    "~${model.receiveAmount.toStringAsFixed(8)} ${model.receiveTicker.toUpperCase()}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: model.rateType == ExchangeRateType.estimated
                    ? "Estimated rate"
                    : "Fixed rate",
                value: model.rateInfo,
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                vertical: true,
                label: "Recipient ${model.receiveTicker.toUpperCase()} address",
                value: model.recipientAddress!,
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                vertical: true,
                label: "Refund ${model.sendTicker.toUpperCase()} address",
                value: model.refundAddress!,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 32,
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Back",
                  buttonHeight: ButtonHeight.l,
                  onPressed: Navigator.of(context).pop,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Confirm",
                  buttonHeight: ButtonHeight.l,
                  onPressed: createTrade,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

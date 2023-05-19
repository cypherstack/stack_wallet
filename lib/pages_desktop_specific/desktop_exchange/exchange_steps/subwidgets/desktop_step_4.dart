import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_item.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopStep4 extends ConsumerStatefulWidget {
  const DesktopStep4({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DesktopStep4> createState() => _DesktopStep4State();
}

class _DesktopStep4State extends ConsumerState<DesktopStep4> {
  String _statusString = "New";

  Timer? _statusTimer;

  bool _isWalletCoinAndHasWallet(String ticker) {
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
    final trade = ref.read(desktopExchangeModelProvider)?.trade;

    if (trade == null) {
      return;
    }

    final statusResponse =
        await ref.read(efExchangeProvider).updateTrade(trade);
    String status = "Waiting";
    if (statusResponse.value != null) {
      status = statusResponse.value!.status;
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
    return Column(
      children: [
        Text(
          "Send ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker.toUpperCase()))} to the address below",
          style: STextStyles.desktopTextMedium(context),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Send ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker.toUpperCase()))} to the address below. Once it is received, ${ref.watch(desktopExchangeModelProvider.select((value) => value!.trade?.exchangeName))} will send the ${ref.watch(desktopExchangeModelProvider.select((value) => value!.receiveTicker.toUpperCase()))} to the recipient address you provided. You can find this trade details and check its status in the list of trades.",
          style: STextStyles.desktopTextExtraExtraSmall(context),
        ),
        const SizedBox(
          height: 20,
        ),
        RoundedContainer(
          color: Theme.of(context).extension<StackColors>()!.warningBackground,
          child: RichText(
            text: TextSpan(
              text:
                  "You must send at least ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendAmount.toString()))} ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker))}. ",
              style: STextStyles.label700(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .warningForeground,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text:
                      "If you send less than ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendAmount.toString()))} ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker))}, your transaction may not be converted and it may not be refunded.",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .warningForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
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
                vertical: true,
                label:
                    "Send ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker.toUpperCase()))} to this address",
                value: ref.watch(desktopExchangeModelProvider
                        .select((value) => value!.trade?.payInAddress)) ??
                    "Error",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "Amount",
                value:
                    "${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendAmount.toStringAsFixed(8)))} ${ref.watch(desktopExchangeModelProvider.select((value) => value!.sendTicker.toUpperCase()))}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "Trade ID",
                value: ref.watch(desktopExchangeModelProvider
                        .select((value) => value!.trade?.tradeId)) ??
                    "Error",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status",
                      style: STextStyles.desktopTextExtraExtraSmall(context),
                    ),
                    Text(
                      _statusString,
                      style: STextStyles.desktopTextExtraExtraSmall(context)
                          .copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .colorForStatus(_statusString),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

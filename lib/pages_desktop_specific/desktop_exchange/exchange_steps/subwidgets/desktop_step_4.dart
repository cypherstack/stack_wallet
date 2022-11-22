import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/exchange_view/send_from_view.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_item.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class DesktopStep4 extends ConsumerStatefulWidget {
  const DesktopStep4({
    Key? key,
    required this.model,
  }) : super(key: key);

  final IncompleteExchangeModel model;

  @override
  ConsumerState<DesktopStep4> createState() => _DesktopStep4State();
}

class _DesktopStep4State extends ConsumerState<DesktopStep4> {
  late final IncompleteExchangeModel model;

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
    final statusResponse =
        await ref.read(exchangeProvider).updateTrade(model.trade!);
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
    model = widget.model;

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
          "Send ${model.sendTicker.toUpperCase()} to the address below",
          style: STextStyles.desktopTextMedium(context),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          "Send ${model.sendTicker.toUpperCase()} to the address below. Once it is received, ${model.trade!.exchangeName} will send the ${model.receiveTicker.toUpperCase()} to the recipient address you provided. You can find this trade details and check its status in the list of trades.",
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
                  "You must send at least ${model.sendAmount.toString()} ${model.sendTicker}. ",
              style: STextStyles.label700(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .warningForeground,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text:
                      "If you send less than ${model.sendAmount.toString()} ${model.sendTicker}, your transaction may not be converted and it may not be refunded.",
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
                label: "Send ${model.sendTicker.toUpperCase()} to this address",
                value: model.trade!.payInAddress,
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "Amount",
                value:
                    "${model.sendAmount.toStringAsFixed(8)} ${model.sendTicker.toUpperCase()}",
              ),
              Container(
                height: 1,
                color: Theme.of(context).extension<StackColors>()!.background,
              ),
              DesktopStepItem(
                label: "Trade ID",
                value: model.trade!.tradeId,
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
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 32,
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Send from Stack Wallet",
                  buttonHeight: ButtonHeight.l,
                  onPressed: () {
                    final trade = model.trade!;
                    final amount = Decimal.parse(trade.payInAmount);
                    final address = trade.payInAddress;

                    final coin =
                        coinFromTickerCaseInsensitive(trade.payInCurrency);

                    showDialog<void>(
                      context: context,
                      builder: (context) => Navigator(
                        initialRoute: SendFromView.routeName,
                        onGenerateRoute: RouteGenerator.generateRoute,
                        onGenerateInitialRoutes: (_, __) {
                          return [
                            FadePageRoute(
                              SendFromView(
                                coin: coin,
                                trade: trade,
                                amount: amount,
                                address: address,
                                shouldPopRoot: true,
                              ),
                              const RouteSettings(
                                name: SendFromView.routeName,
                              ),
                            ),
                          ];
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: PrimaryButton(
                  label: "Show QR code",
                  buttonHeight: ButtonHeight.l,
                  onPressed: () {
                    showDialog<dynamic>(
                      context: context,
                      barrierColor: Colors.transparent,
                      barrierDismissible: true,
                      builder: (_) {
                        return DesktopDialog(
                          maxHeight: 720,
                          maxWidth: 720,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Send ${model.sendAmount.toStringAsFixed(8)} ${model.sendTicker} to this address",
                                style: STextStyles.desktopH3(context),
                              ),
                              const SizedBox(
                                height: 48,
                              ),
                              Center(
                                child: QrImage(
                                  // TODO: grab coin uri scheme from somewhere
                                  // data: "${coin.uriScheme}:$receivingAddress",
                                  data: model.trade!.payInAddress,
                                  size: 290,
                                  foregroundColor: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark,
                                ),
                              ),
                              const SizedBox(
                                height: 48,
                              ),
                              SecondaryButton(
                                label: "Cancel",
                                width: 310,
                                buttonHeight: ButtonHeight.l,
                                onPressed: Navigator.of(context).pop,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

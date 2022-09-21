import 'package:flutter/material.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class Step1View extends StatefulWidget {
  const Step1View({
    Key? key,
    required this.model,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/exchangeStep1";

  final IncompleteExchangeModel model;
  final ClipboardInterface clipboard;

  @override
  State<Step1View> createState() => _Step1ViewState();
}

class _Step1ViewState extends State<Step1View> {
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
                          current: 0,
                          width: width,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          "Confirm amount",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Network fees and other exchange charges are included in the rate.",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "You send",
                                style: STextStyles.itemSubtitle.copyWith(
                                    color:
                                        StackTheme.instance.color.infoItemText),
                              ),
                              Text(
                                "${model.sendAmount.toStringAsFixed(8)} ${model.sendTicker.toUpperCase()}",
                                style: STextStyles.itemSubtitle12.copyWith(
                                    color:
                                        StackTheme.instance.color.infoItemText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "You receive",
                                style: STextStyles.itemSubtitle.copyWith(
                                    color:
                                        StackTheme.instance.color.infoItemText),
                              ),
                              Text(
                                "~${model.receiveAmount.toStringAsFixed(8)} ${model.receiveTicker.toUpperCase()}",
                                style: STextStyles.itemSubtitle12.copyWith(
                                    color:
                                        StackTheme.instance.color.infoItemText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        RoundedWhiteContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                model.rateType == ExchangeRateType.estimated
                                    ? "Estimated rate"
                                    : "Fixed rate",
                                style: STextStyles.itemSubtitle.copyWith(
                                  color:
                                      StackTheme.instance.color.infoItemLabel,
                                ),
                              ),
                              Text(
                                model.rateInfo,
                                style: STextStyles.itemSubtitle12.copyWith(
                                    color:
                                        StackTheme.instance.color.infoItemText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(Step2View.routeName,
                                arguments: model);
                          },
                          style: StackTheme.instance
                              .getPrimaryEnabledButtonColor(context),
                          child: Text(
                            "Next",
                            style: STextStyles.button,
                          ),
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

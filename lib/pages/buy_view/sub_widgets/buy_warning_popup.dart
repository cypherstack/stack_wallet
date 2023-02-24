import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/order.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/pages/buy_view/buy_order_details.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuyWarningPopup extends StatefulWidget {
  const BuyWarningPopup({
    Key? key,
    required this.quote,
    this.order,
  }) : super(key: key);
  final SimplexQuote quote;
  final SimplexOrder? order;
  @override
  State<BuyWarningPopup> createState() => _BuyWarningPopupState();
}

class _BuyWarningPopupState extends State<BuyWarningPopup> {
  late final bool isDesktop;
  SimplexOrder? order;

  String get title => "Buy ${widget.quote.crypto.ticker}";
  String get message =>
      "This purchase is provided and fulfilled by Simplex by nuvei "
      "(a third party). You will be taken to their website. Please follow "
      "their instructions.";

  Future<BuyResponse<SimplexOrder>> newOrder(SimplexQuote quote) async {
    final orderResponse = await SimplexAPI.instance.newOrder(quote);

    return orderResponse;
  }

  Future<BuyResponse<bool>> redirect(SimplexOrder order) async {
    return SimplexAPI.instance.redirect(order);
  }

  Future<void> _buyInvoice() async {
    await showDialog<void>(
      context: context,
      // useRootNavigator: isDesktop,
      builder: (context) {
        return isDesktop
            ? DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Order details",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: BuyOrderDetailsView(
                                  order: order as SimplexOrder,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : BuyOrderDetailsView(
                order: order as SimplexOrder,
              );
      },
    );
  }

  Future<void> onContinue() async {
    BuyResponse<SimplexOrder> orderResponse = await newOrder(widget.quote);
    if (orderResponse.exception == null) {
      await redirect(orderResponse.value as SimplexOrder)
          .then((_response) async {
        order = orderResponse.value as SimplexOrder;
        Navigator.of(context, rootNavigator: isDesktop).pop();
        Navigator.of(context, rootNavigator: isDesktop).pop();
        await _buyInvoice();
      });
    } else {
      await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          if (isDesktop) {
            return DesktopDialog(
              maxWidth: 450,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Simplex API error",
                      style: STextStyles.desktopH3(context),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      "${orderResponse.exception?.errorMessage}",
                      style: STextStyles.smallMed14(context),
                    ),
                    const SizedBox(
                      height: 56,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: PrimaryButton(
                            buttonHeight: ButtonHeight.l,
                            label: "Ok",
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(); // weee
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          } else {
            return StackDialog(
              title: "Simplex API error",
              message: "${orderResponse.exception?.errorMessage}",
              // "${quoteResponse.exception?.errorMessage.substring(8, (quoteResponse.exception?.errorMessage?.length ?? 109) - (8 + 6))}",
              rightButton: TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getSecondaryEnabledButtonStyle(context),
                child: Text(
                  "Ok",
                  style: STextStyles.button(context).copyWith(
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // weee
                },
              ),
            );
          }
        },
      );
    }
  }

  @override
  void initState() {
    order = widget.order;
    isDesktop = Util.isDesktop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return DesktopDialog(
        maxWidth: 580,
        maxHeight: 350,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: STextStyles.desktopH3(context),
                  ),
                  SizedBox(
                    width: 64,
                    height: 32,
                    child: SvgPicture.asset(
                      Assets.buy.simplexLogo(context),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                message,
                style: STextStyles.desktopTextSmall(context),
              ),
              const Spacer(
                flex: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: "Cancel",
                      buttonHeight: ButtonHeight.l,
                      onPressed:
                          Navigator.of(context, rootNavigator: isDesktop).pop,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: PrimaryButton(
                      buttonHeight: ButtonHeight.l,
                      label: "Continue",
                      onPressed: onContinue,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    } else {
      return StackDialog(
        title: title,
        message: message,
        leftButton: SecondaryButton(
          label: "Cancel",
          onPressed: Navigator.of(context, rootNavigator: isDesktop).pop,
        ),
        rightButton: PrimaryButton(
          label: "Continue",
          onPressed: onContinue,
        ),
        icon: SizedBox(
          width: 64,
          height: 32,
          child: SvgPicture.asset(
            Assets.buy.simplexLogo(context),
          ),
        ),
      );
    }
  }
}

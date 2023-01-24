import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/buy_warning_popup.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class BuyQuotePreviewView extends StatefulWidget {
  const BuyQuotePreviewView({
    Key? key,
    required this.quote,
  }) : super(key: key);

  final SimplexQuote quote;

  static const String routeName = "/buyQuotePreview";

  @override
  State<BuyQuotePreviewView> createState() => _BuyQuotePreviewViewState();
}

class _BuyQuotePreviewViewState extends State<BuyQuotePreviewView> {
  final isDesktop = Util.isDesktop;

  Future<void> _buyWarning() async {
    await showDialog<void>(
      context: context,
      builder: (context) => BuyWarningPopup(
        quote: widget.quote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.backgroundAppBar,
              leading: const AppBarBackButton(),
              title: Text(
                "Preview quote",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: LayoutBuilder(
              builder: (builderContext, constraints) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 12,
                    right: 12,
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Buy ${widget.quote.crypto.ticker.toUpperCase()}",
            style: STextStyles.pageTitleH1(context),
          ),
          const SizedBox(
            height: 16,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "You pay",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.quote.youPayFiatPrice.toStringAsFixed(2)} ${widget.quote.fiat.ticker.toUpperCase()}",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          // RoundedWhiteContainer(
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         "You pay with",
          //         style: STextStyles.label(context),
          //       ),
          //       Text(
          //         widget.quote.fiat.name,
          //         style: STextStyles.label(context).copyWith(
          //           color: Theme.of(context).extension<StackColors>()!.textDark,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(
          //   height: 8,
          // ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "You receive",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.quote.youReceiveCryptoAmount} ${widget.quote.crypto.ticker.toUpperCase()}",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
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
                Text(
                  "Receiving ${widget.quote.crypto.ticker.toUpperCase()} address",
                  style: STextStyles.label(context),
                ),
                Text(
                  "${widget.quote.receivingAddress} ",
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quote ID",
                  style: STextStyles.label(context),
                ),
                Text(
                  widget.quote.id,
                  style: STextStyles.label(context).copyWith(
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          RoundedWhiteContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Provider",
                  style: STextStyles.label(context),
                ),
                SizedBox(
                  width: 64,
                  height: 32,
                  child: SvgPicture.asset(
                    Assets.buy.simplexLogo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Spacer(),
          PrimaryButton(
            label: "Buy",
            onPressed: _buyWarning,
          )
        ],
      ),
    );
  }
}

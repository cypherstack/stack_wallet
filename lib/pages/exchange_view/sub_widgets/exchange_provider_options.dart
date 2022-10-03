import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

final currentExchangeNameStateProvider =
    StateProvider<String>((ref) => ChangeNowExchange.exchangeName);

final exchangeProvider = Provider<Exchange>((ref) {
  switch (ref.watch(currentExchangeNameStateProvider.state).state) {
    case ChangeNowExchange.exchangeName:
      return ChangeNowExchange();
    case SimpleSwapExchange.exchangeName:
      return SimpleSwapExchange();
    default:
      const errorMessage =
          "Attempted to access exchangeProvider with invalid exchange name!";
      Logging.instance.log(errorMessage, level: LogLevel.Fatal);
      throw Exception(errorMessage);
  }
});

class ExchangeProviderOptions extends ConsumerWidget {
  const ExchangeProviderOptions({
    Key? key,
    required this.fromAmount,
    required this.toAmount,
    required this.fixedRate,
    required this.reversed,
  }) : super(key: key);

  final Decimal? fromAmount;
  final Decimal? toAmount;
  final bool fixedRate;
  final bool reversed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoundedWhiteContainer(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (ref.read(currentExchangeNameStateProvider.state).state !=
                  ChangeNowExchange.exchangeName) {
                ref.read(currentExchangeNameStateProvider.state).state =
                    ChangeNowExchange.exchangeName;
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Radio(
                      activeColor: Theme.of(context)
                          .extension<StackColors>()!
                          .radioButtonIconEnabled,
                      value: ChangeNowExchange.exchangeName,
                      groupValue: ref
                          .watch(currentExchangeNameStateProvider.state)
                          .state,
                      onChanged: (value) {
                        if (value is String) {
                          ref
                              .read(currentExchangeNameStateProvider.state)
                              .state = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  SvgPicture.asset(
                    Assets.exchange.changeNow,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ChangeNowExchange.exchangeName,
                          style: STextStyles.titleBold12(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark2,
                          ),
                        ),
                        Text(
                          ChangeNowExchange.exchangeName,
                          style: STextStyles.itemSubtitle12(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          GestureDetector(
            onTap: () {
              if (ref.read(currentExchangeNameStateProvider.state).state !=
                  SimpleSwapExchange.exchangeName) {
                ref.read(currentExchangeNameStateProvider.state).state =
                    SimpleSwapExchange.exchangeName;
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Radio(
                      activeColor: Theme.of(context)
                          .extension<StackColors>()!
                          .radioButtonIconEnabled,
                      value: SimpleSwapExchange.exchangeName,
                      groupValue: ref
                          .watch(currentExchangeNameStateProvider.state)
                          .state,
                      onChanged: (value) {
                        if (value is String) {
                          ref
                              .read(currentExchangeNameStateProvider.state)
                              .state = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  SvgPicture.asset(
                    Assets.exchange.simpleSwap,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SimpleSwapExchange.exchangeName,
                          style: STextStyles.titleBold12(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark2,
                          ),
                        ),
                        Text(
                          SimpleSwapExchange.exchangeName,
                          style: STextStyles.itemSubtitle12(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddTokenListElementData {
  AddTokenListElementData(this.token);

  final EthToken token;
  bool selected = false;
}

class AddTokenListElement extends StatefulWidget {
  const AddTokenListElement({Key? key, required this.data}) : super(key: key);

  final AddTokenListElementData data;

  @override
  State<AddTokenListElement> createState() => _AddTokenListElementState();
}

class _AddTokenListElementState extends State<AddTokenListElement> {
  @override
  Widget build(BuildContext context) {
    final currency = ExchangeDataLoadingService.instance.isar.currencies
        .where()
        .tickerExchangeNameEqualToAnyName(
          "${widget.data.token.symbol}ERC20",
          ChangeNowExchange.exchangeName,
        )
        .or()
        .tickerExchangeNameEqualToAnyName(
          widget.data.token.symbol,
          ChangeNowExchange.exchangeName,
        )
        .or()
        .tickerExchangeNameEqualToAnyName(
          "${widget.data.token.symbol}BSC",
          ChangeNowExchange.exchangeName,
        )
        .filter()
        .imageIsNotEmpty()
        .findFirstSync();
    return RoundedWhiteContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              currency != null
                  ? SvgPicture.network(
                      currency.image,
                      width: 24,
                      height: 24,
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      color: Colors.red,
                    ),
              const SizedBox(
                width: 12,
              ),
              Text(
                "${widget.data.token.name} (${widget.data.token.symbol})",
                style: STextStyles.w600_14(context),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(
            width: 4,
          ),
          SizedBox(
            height: 20,
            width: 40,
            child: DraggableSwitchButton(
              isOn: widget.data.selected,
              onValueChanged: (newValue) {
                widget.data.selected = newValue;
              },
            ),
          ),
        ],
      ),
    );
  }
}

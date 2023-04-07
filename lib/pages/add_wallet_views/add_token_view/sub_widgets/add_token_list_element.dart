import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddTokenListElementData {
  AddTokenListElementData(this.token);

  final EthContract token;
  bool selected = false;
}

class AddTokenListElement extends StatefulWidget {
  const AddTokenListElement({Key? key, required this.data}) : super(key: key);

  final AddTokenListElementData data;

  @override
  State<AddTokenListElement> createState() => _AddTokenListElementState();
}

class _AddTokenListElementState extends State<AddTokenListElement> {
  final bool isDesktop = Util.isDesktop;

  @override
  Widget build(BuildContext context) {
    final currency = ExchangeDataLoadingService.instance.isar.currencies
        .where()
        .exchangeNameEqualTo(ChangeNowExchange.exchangeName)
        .filter()
        .tokenContractEqualTo(
          widget.data.token.address,
          caseSensitive: false,
        )
        .and()
        .imageIsNotEmpty()
        .findFirstSync();

    final String mainLabel = widget.data.token.name;
    final double iconSize = isDesktop ? 32 : 24;

    return RoundedWhiteContainer(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.backgroundAppBar
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              currency != null
                  ? SvgPicture.network(
                      currency.image,
                      width: iconSize,
                      height: iconSize,
                    )
                  : SvgPicture.asset(
                      widget.data.token.symbol == "BNB"
                          ? Assets.svg.bnbIcon
                          : Assets.svg.ethereum,
                      width: iconSize,
                      height: iconSize,
                    ),
              const SizedBox(
                width: 12,
              ),
              ConditionalParent(
                condition: isDesktop,
                builder: (child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    child,
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      widget.data.token.symbol,
                      style: STextStyles.desktopTextExtraExtraSmall(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                child: Text(
                  isDesktop
                      ? mainLabel
                      : "$mainLabel (${widget.data.token.symbol})",
                  style: isDesktop
                      ? STextStyles.desktopTextSmall(context)
                      : STextStyles.w600_14(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 4,
          ),
          isDesktop
              ? Checkbox(
                  value: widget.data.selected,
                  onChanged: (newValue) =>
                      setState(() => widget.data.selected = newValue!),
                )
              : SizedBox(
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

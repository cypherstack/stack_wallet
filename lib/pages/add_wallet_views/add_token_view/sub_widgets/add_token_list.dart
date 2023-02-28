import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_token_list_element.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

class AddTokenList extends StatelessWidget {
  const AddTokenList({
    Key? key,
    required this.items,
  }) : super(key: key);

  final List<AddTokenListElementData> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        return ConditionalParent(
          condition: index == items.length - 1,
          builder: (child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              Padding(
                padding: const EdgeInsets.all(4),
                child: RawMaterialButton(
                  fillColor:
                      Theme.of(context).extension<StackColors>()!.popupBG,
                  elevation: 0,
                  focusElevation: 0,
                  hoverElevation: 0,
                  highlightElevation: 0,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  onPressed: () {
                    // todo add custom token
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          Assets.svg.circlePlusFilled,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textDark,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          "Add custom token",
                          style: STextStyles.w600_14(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AddTokenListElement(
              data: items[index],
            ),
          ),
        );
      },
    );
  }
}

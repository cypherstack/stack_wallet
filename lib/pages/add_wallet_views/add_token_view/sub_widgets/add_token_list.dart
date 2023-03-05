import 'package:flutter/material.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_custom_token_selector.dart';
import 'package:stackwallet/pages/add_wallet_views/add_token_view/sub_widgets/add_token_list_element.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';

class AddTokenList extends StatelessWidget {
  const AddTokenList({
    Key? key,
    required this.walletId,
    required this.items,
    required this.addFunction,
  }) : super(key: key);

  final String walletId;
  final List<AddTokenListElementData> items;
  final VoidCallback addFunction;

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
              AddCustomTokenSelector(
                addFunction: addFunction,
              ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 4),
              //   child: RawMaterialButton(
              //     fillColor:
              //         Theme.of(context).extension<StackColors>()!.popupBG,
              //     elevation: 0,
              //     focusElevation: 0,
              //     hoverElevation: 0,
              //     highlightElevation: 0,
              //     constraints: const BoxConstraints(),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(
              //         Constants.size.circularBorderRadius,
              //       ),
              //     ),
              //     onPressed: addFunction,
              //     child: Padding(
              //       padding: const EdgeInsets.all(12),
              //       child: Row(
              //         children: [
              //           SvgPicture.asset(
              //             Assets.svg.circlePlusFilled,
              //             color: Theme.of(context)
              //                 .extension<StackColors>()!
              //                 .textDark,
              //             width: 24,
              //             height: 24,
              //           ),
              //           const SizedBox(
              //             width: 12,
              //           ),
              //           Text(
              //             "Add custom token",
              //             style: STextStyles.w600_14(context),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AddTokenListElement(
              data: items[index],
            ),
          ),
        );
      },
    );
  }
}

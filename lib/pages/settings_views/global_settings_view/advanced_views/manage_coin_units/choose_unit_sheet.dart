import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class ChooseUnitSheet extends ConsumerStatefulWidget {
  const ChooseUnitSheet({
    Key? key,
    required this.coin,
  }) : super(key: key);

  final Coin coin;

  @override
  ConsumerState<ChooseUnitSheet> createState() => _ChooseUnitSheetState();
}

class _ChooseUnitSheetState extends ConsumerState<ChooseUnitSheet> {
  late AmountUnit _current;
  late final List<AmountUnit> values;

  @override
  void initState() {
    values = AmountUnit.valuesForCoin(widget.coin);
    _current = ref.read(pAmountUnit(widget.coin));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                width: 60,
                height: 4,
              ),
            ),
            const SizedBox(
              height: 36,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Phrase length",
                  style: STextStyles.pageTitleH2(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(
                  height: 16,
                ),
                for (int i = 0; i < values.length; i++)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _current = values[i];
                          });

                          Navigator.of(context).pop(_current);
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Radio(
                                  activeColor: Theme.of(context)
                                      .extension<StackColors>()!
                                      .radioButtonIconEnabled,
                                  value: values[i],
                                  groupValue: _current,
                                  onChanged: (x) {
                                    setState(() {
                                      _current = values[i];
                                    });

                                    Navigator.of(context).pop(_current);
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                values[i].unitForCoin(widget.coin),
                                style: STextStyles.titleBold12(context),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

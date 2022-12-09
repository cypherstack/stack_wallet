import 'package:epicpay/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table_item.dart';
import 'package:flutter/material.dart';

class MnemonicTable extends StatelessWidget {
  const MnemonicTable({
    Key? key,
    required this.words,
    required this.isDesktop,
    this.itemBorderColor,
  }) : super(key: key);

  final List<String> words;
  final bool isDesktop;
  final Color? itemBorderColor;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final wordsPerRow = isDesktop ? 4 : 3;

    final int rows = words.length ~/ wordsPerRow;

    final int remainder = words.length % wordsPerRow;

    int index = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 1; i <= rows; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 13),
            child: Row(
              children: [
                for (int j = 1; j <= wordsPerRow; j++) ...[
                  if (j > 1)
                    const SizedBox(
                      width: 10,
                    ),
                  Expanded(
                    child: MnemonicTableItem(
                      number: ++index,
                      word: words[index - 1],
                      isDesktop: isDesktop,
                      borderColor: itemBorderColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (index != words.length)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 13),
            child: Row(
              children: [
                for (int i = index; i < words.length; i++) ...[
                  if (i > index)
                    const SizedBox(
                      width: 10,
                    ),
                  Expanded(
                    child: MnemonicTableItem(
                      number: i + 1,
                      word: words[i],
                      isDesktop: isDesktop,
                      borderColor: itemBorderColor,
                    ),
                  ),
                ],
                for (int i = remainder; i < wordsPerRow; i++) ...[
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

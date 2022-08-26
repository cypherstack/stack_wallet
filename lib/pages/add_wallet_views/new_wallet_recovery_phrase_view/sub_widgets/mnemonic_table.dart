import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table_item.dart';

class MnemonicTable extends StatelessWidget {
  const MnemonicTable({
    Key? key,
    required this.words,
  }) : super(key: key);

  final List<String> words;

  static const wordsPerRow = 3;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final int rows = words.length ~/ wordsPerRow;

    final int remainder = words.length % wordsPerRow;

    int index = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 1; i <= rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                for (int j = 1; j <= wordsPerRow; j++) ...[
                  if (j > 1)
                    const SizedBox(
                      width: 6,
                    ),
                  Expanded(
                    child: MnemonicTableItem(
                      number: ++index,
                      word: words[index - 1],
                    ),
                  ),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              for (int i = index; i < words.length; i++) ...[
                if (i > index)
                  const SizedBox(
                    width: 6,
                  ),
                Expanded(
                  child: MnemonicTableItem(
                    number: i + 1,
                    word: words[i],
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

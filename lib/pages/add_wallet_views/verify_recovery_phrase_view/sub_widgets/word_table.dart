import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/sub_widgets/word_table_item.dart';

class WordTable extends ConsumerWidget {
  const WordTable({
    Key? key,
    required this.words,
  }) : super(key: key);

  final List<String> words;

  static const wordsPerRow = 3;
  static const wordsToShow = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");

    final int rows = words.length ~/ wordsPerRow;
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
                    child: WordTableItem(
                      number: ++index,
                      word: words[index - 1],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:epicpay/pages/settings_views/wallet_settings/sub_widgets/word_table_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WordTable extends ConsumerWidget {
  const WordTable({
    Key? key,
    required this.words,
    this.onPressed,
  }) : super(key: key);

  final List<String> words;
  final void Function(String)? onPressed;

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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                for (int j = 1; j <= wordsPerRow; j++) ...[
                  if (j > 1)
                    const SizedBox(
                      width: 25,
                    ),
                  Expanded(
                    child: WordTableItem(
                      number: ++index,
                      word: words[index - 1],
                      onPressed: onPressed,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class SimpleCopyButton extends StatelessWidget {
  const SimpleCopyButton({
    Key? key,
    required this.data,
  }) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: data));
        if (context.mounted) {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.info,
              message: "Copied to clipboard",
              context: context,
            ),
          );
        }
      },
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.svg.copy,
            width: 10,
            height: 10,
            color: Theme.of(context).extension<StackColors>()!.infoItemIcons,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            "Copy",
            style: STextStyles.link2(context),
          ),
        ],
      ),
    );
  }
}

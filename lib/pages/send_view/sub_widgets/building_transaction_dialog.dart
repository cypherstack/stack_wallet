import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_widgets/rotating_arrows.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class BuildingTransactionDialog extends ConsumerStatefulWidget {
  const BuildingTransactionDialog({
    Key? key,
    required this.onCancel,
    required this.coin,
  }) : super(key: key);

  final VoidCallback onCancel;
  final Coin coin;

  @override
  ConsumerState<BuildingTransactionDialog> createState() =>
      _RestoringDialogState();
}

class _RestoringDialogState extends ConsumerState<BuildingTransactionDialog> {
  late final VoidCallback onCancel;

  @override
  void initState() {
    onCancel = widget.onCancel;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = ref.watch(
      coinImageSecondaryProvider(
        widget.coin,
      ),
    );

    if (Util.isDesktop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Generating transaction",
            style: STextStyles.desktopH3(context),
          ),
          const SizedBox(
            height: 40,
          ),
          assetPath.endsWith(".gif")
              ? Image.file(File(
                  assetPath,
                ))
              : const RotatingArrows(
                  width: 40,
                  height: 40,
                ),
          const SizedBox(
            height: 40,
          ),
          SecondaryButton(
            buttonHeight: ButtonHeight.l,
            label: "Cancel",
            onPressed: () {
              onCancel.call();
            },
          )
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: assetPath.endsWith(".gif")
            ? StackDialogBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(File(
                      assetPath,
                    )),
                    Text(
                      "Generating transaction",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH2(context),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getSecondaryEnabledButtonStyle(context),
                            child: Text(
                              "Cancel",
                              style: STextStyles.itemSubtitle12(context),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCancel.call();
                            },
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              )
            : StackDialog(
                title: "Generating transaction",
                icon: const RotatingArrows(
                  width: 24,
                  height: 24,
                ),
                rightButton: TextButton(
                  style: Theme.of(context)
                      .extension<StackColors>()!
                      .getSecondaryEnabledButtonStyle(context),
                  child: Text(
                    "Cancel",
                    style: STextStyles.itemSubtitle12(context),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel.call();
                  },
                ),
              ),
      );
    }
  }
}

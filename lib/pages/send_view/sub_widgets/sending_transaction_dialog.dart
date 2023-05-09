import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class SendingTransactionDialog extends ConsumerStatefulWidget {
  const SendingTransactionDialog({
    Key? key,
    required this.coin,
    required this.controller,
  }) : super(key: key);

  final Coin coin;
  final ProgressAndSuccessController controller;

  @override
  ConsumerState<SendingTransactionDialog> createState() =>
      _RestoringDialogState();
}

class _RestoringDialogState extends ConsumerState<SendingTransactionDialog> {
  late ProgressAndSuccessController? _progressAndSuccessController;

  @override
  void initState() {
    _progressAndSuccessController = widget.controller;

    super.initState();
  }

  @override
  void dispose() {
    _progressAndSuccessController = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = ref.watch(
      coinImageSecondaryProvider(
        widget.coin,
      ),
    );

    if (Util.isDesktop) {
      return DesktopDialog(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sending transaction",
                style: STextStyles.desktopH3(context),
              ),
              const SizedBox(
                height: 40,
              ),
              assetPath.endsWith(".gif")
                  ? Image.file(
                      File(assetPath),
                    )
                  : ProgressAndSuccess(
                      controller: _progressAndSuccessController!,
                    ),
            ],
          ),
        ),
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
                    Image.file(
                      File(assetPath),
                    ),
                    Text(
                      "Sending transaction",
                      textAlign: TextAlign.center,
                      style: STextStyles.pageTitleH2(context),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                  ],
                ),
              )
            : StackDialog(
                title: "Sending transaction",
                icon: ProgressAndSuccess(
                  controller: _progressAndSuccessController!,
                ),
              ),
      );
    }
  }
}

class ProgressAndSuccessController {
  VoidCallback? triggerSuccess;
}

class ProgressAndSuccess extends StatefulWidget {
  const ProgressAndSuccess({
    Key? key,
    this.height = 24,
    this.width = 24,
    required this.controller,
  }) : super(key: key);

  final double height;
  final double width;
  final ProgressAndSuccessController controller;

  @override
  State<ProgressAndSuccess> createState() => _ProgressAndSuccessState();
}

class _ProgressAndSuccessState extends State<ProgressAndSuccess>
    with TickerProviderStateMixin {
  late final AnimationController controller1;
  late final AnimationController controller2;

  CrossFadeState _crossFadeState = CrossFadeState.showFirst;

  bool _triggered = false;

  @override
  void initState() {
    controller1 = AnimationController(vsync: this);
    controller2 = AnimationController(vsync: this);

    controller1.addListener(() => setState(() {}));
    controller2.addListener(() => setState(() {}));

    controller1.addStatusListener((status) {
      if (status == AnimationStatus.completed && _triggered) {
        controller2.forward();
        setState(() {
          _crossFadeState = CrossFadeState.showSecond;
        });
      }
    });

    widget.controller.triggerSuccess = () {
      controller1.forward();
      _triggered = true;
    };

    super.initState();
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      crossFadeState: _crossFadeState,
      firstChild: Lottie.asset(
        Assets.lottie.iconSend,
        controller: controller1,
        width: widget.width,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              const ["**"],
              value:
                  Theme.of(context).extension<StackColors>()!.accentColorDark,
            ),
            ValueDelegate.strokeColor(
              const ["**"],
              value:
                  Theme.of(context).extension<StackColors>()!.accentColorDark,
            ),
          ],
        ),
        height: widget.height,
        onLoaded: (composition) {
          final start = composition.markers[0].start;
          final end = composition.markers[1].start;

          setState(() {
            controller1.duration = composition.duration;
          });
          controller1.repeat(
            min: start,
            max: end,
            period: composition.duration * (end - start),
          );
        },
      ),
      secondChild: Lottie.asset(
        Assets.lottie.loaderAndCheckmark,
        controller: controller2,
        width: widget.width,
        height: widget.height,
        onLoaded: (composition) {
          setState(() {
            controller2.duration = composition.duration *
                (composition.markers.last.end - composition.markers[1].start);
            controller2.value = composition.markers[1].start;
          });
        },
      ),
      duration: const Duration(microseconds: 1),
    );
  }
}

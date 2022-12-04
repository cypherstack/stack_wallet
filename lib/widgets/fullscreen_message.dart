import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter/material.dart';

class FullScreenMessageController {
  VoidCallback? forcePop;
}

class FullScreenMessage extends StatefulWidget {
  const FullScreenMessage({
    Key? key,
    this.icon,
    this.message,
    this.duration,
    this.controller,
  })  : assert(duration != null || controller != null),
        super(key: key);

  final Widget? icon;
  final String? message;
  final Duration? duration;
  final FullScreenMessageController? controller;

  @override
  State<FullScreenMessage> createState() => _FullScreenMessageState();
}

class _FullScreenMessageState extends State<FullScreenMessage> {
  late final Duration? duration;
  late final FullScreenMessageController? controller;

  bool _canPop = false;

  void _pop() {
    _canPop = true;
    controller?.forcePop = null;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    duration = widget.duration;
    controller = widget.controller;

    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Future<void>.delayed(duration!).then((_) {
          if (mounted) {
            _pop();
          }
        });
      });
    } else {
      controller!.forcePop = _pop;
    }

    super.initState();
  }

  @override
  void dispose() {
    controller?.forcePop = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _canPop,
      child: Material(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topRight,
              colors: [
                Theme.of(context).extension<StackColors>()!.overlay,
                Theme.of(context).extension<StackColors>()!.popupBG,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) widget.icon!,
                  if (widget.message != null && widget.icon != null)
                    const SizedBox(
                      height: 20,
                    ),
                  if (widget.message != null)
                    Text(
                      widget.message!,
                      style: STextStyles.bodyBold(context),
                      textAlign: TextAlign.center,
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class CustomLoadingOverlay extends ConsumerStatefulWidget {
  const CustomLoadingOverlay({
    Key? key,
    required this.message,
    this.subMessage,
    required this.eventBus,
    this.textColor,
  }) : super(key: key);

  final String message;
  final String? subMessage;
  final EventBus? eventBus;
  final Color? textColor;

  @override
  ConsumerState<CustomLoadingOverlay> createState() =>
      _CustomLoadingOverlayState();
}

class _CustomLoadingOverlayState extends ConsumerState<CustomLoadingOverlay> {
  double _percent = 0;

  late final StreamSubscription<double>? subscription;

  @override
  void initState() {
    subscription = widget.eventBus?.on<double>().listen((event) {
      setState(() {
        _percent = event;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: Center(
            child: Column(
              children: [
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: STextStyles.pageTitleH2(context).copyWith(
                    color: widget.textColor ??
                        Theme.of(context)
                            .extension<StackColors>()!
                            .loadingOverlayTextColor,
                  ),
                ),
                if (widget.eventBus != null)
                  const SizedBox(
                    height: 10,
                  ),
                if (widget.eventBus != null)
                  Text(
                    "${(_percent * 100).toStringAsFixed(2)}%",
                    style: STextStyles.pageTitleH2(context).copyWith(
                      color: widget.textColor ??
                          Theme.of(context)
                              .extension<StackColors>()!
                              .loadingOverlayTextColor,
                    ),
                  ),
                if (widget.subMessage != null)
                  const SizedBox(
                    height: 10,
                  ),
                if (widget.subMessage != null)
                  Text(
                    widget.subMessage!,
                    textAlign: TextAlign.center,
                    style: STextStyles.pageTitleH2(context).copyWith(
                      fontSize: 14,
                      color: widget.textColor ??
                          Theme.of(context)
                              .extension<StackColors>()!
                              .loadingOverlayTextColor,
                    ),
                  )
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 64,
        ),
        const Center(
          child: LoadingIndicator(
            width: 100,
          ),
        ),
      ],
    );
  }
}

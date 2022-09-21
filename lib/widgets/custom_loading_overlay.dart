import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class CustomLoadingOverlay extends ConsumerStatefulWidget {
  const CustomLoadingOverlay({
    Key? key,
    required this.message,
    required this.eventBus,
  }) : super(key: key);

  final String message;
  final EventBus? eventBus;

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
                  style: STextStyles.pageTitleH2.copyWith(
                    color: CFColors.white,
                  ),
                ),
                if (widget.eventBus != null)
                  const SizedBox(
                    height: 10,
                  ),
                if (widget.eventBus != null)
                  Text(
                    "${(_percent * 100).toStringAsFixed(2)}%",
                    style: STextStyles.pageTitleH2.copyWith(
                      color: CFColors.white,
                    ),
                  ),
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

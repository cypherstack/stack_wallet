import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ExchangeLoadingOverlayView extends ConsumerStatefulWidget {
  const ExchangeLoadingOverlayView({
    Key? key,
    required this.unawaitedLoad,
  }) : super(key: key);

  final VoidCallback unawaitedLoad;

  @override
  ConsumerState<ExchangeLoadingOverlayView> createState() =>
      _ExchangeLoadingOverlayViewState();
}

class _ExchangeLoadingOverlayViewState
    extends ConsumerState<ExchangeLoadingOverlayView> {
  late ChangeNowLoadStatus _statusEst;
  late ChangeNowLoadStatus _statusFixed;

  bool userReloaded = false;

  @override
  void initState() {
    _statusEst =
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state;
    _statusFixed =
        ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen(
        changeNowEstimatedInitialLoadStatusStateProvider
            .select((value) => value), (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusEst = next;
        });
      }
    });

    ref.listen(
        changeNowFixedInitialLoadStatusStateProvider.select((value) => value),
        (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusFixed = next;
        });
      }
    });

    return Stack(
      children: [
        if (_statusEst == ChangeNowLoadStatus.loading ||
            (_statusFixed == ChangeNowLoadStatus.loading && userReloaded))
          Container(
            color: CFColors.stackAccent.withOpacity(0.7),
            child: const CustomLoadingOverlay(
                message: "Loading ChangeNOW data", eventBus: null),
          ),
        if ((_statusEst == ChangeNowLoadStatus.failed ||
                _statusFixed == ChangeNowLoadStatus.failed) &&
            _statusEst != ChangeNowLoadStatus.loading &&
            _statusFixed != ChangeNowLoadStatus.loading)
          Container(
            color: CFColors.stackAccent.withOpacity(0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StackDialog(
                  title: "Failed to fetch ChangeNow data",
                  message:
                      "ChangeNOW requires a working internet connection. Tap OK to try fetching again.",
                  rightButton: TextButton(
                    child: Text(
                      "OK",
                      style: STextStyles.button
                          .copyWith(color: CFColors.stackAccent),
                    ),
                    onPressed: () {
                      userReloaded = true;
                      widget.unawaitedLoad();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/frost_route_generator.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class FrostStepScaffold extends ConsumerStatefulWidget {
  const FrostStepScaffold({super.key});

  static const String routeName = "/frostStepScaffold";

  @override
  ConsumerState<FrostStepScaffold> createState() => _FrostScaffoldState();
}

class _FrostScaffoldState extends ConsumerState<FrostStepScaffold> {
  static const _titleTextSize = 18.0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  late final List<FrostStepRoute> _routes;

  bool _requestPopLock = false;

  String get _message {
    switch (ref.read(pFrostScaffoldArgs)!.frostInterruptionDialogType) {
      case FrostInterruptionDialogType.walletCreation:
        return "wallet creation";
      case FrostInterruptionDialogType.resharing:
        return "resharing";
      case FrostInterruptionDialogType.transactionCreation:
        return "transaction signing";
    }
  }

  Future<void> _requestPop(BuildContext context) async {
    if (_requestPopLock ||
        (Util.isDesktop && ref.read(pFrostScaffoldCanPopDesktop))) {
      return;
    }
    _requestPopLock = true;

    final resultFuture = showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StackDialog(
        title: "Cancel $_message process",
        message: "Are you sure you want to cancel the $_message process?",
        leftButton: SecondaryButton(
          label: "No",
          onPressed: () {
            // pop dialog
            Navigator.of(
              context,
              rootNavigator: Util.isDesktop,
            ).pop("no");
          },
        ),
        rightButton: PrimaryButton(
          label: "Yes",
          onPressed: () {
            // pop dialog
            Navigator.of(
              context,
              rootNavigator: Util.isDesktop,
            ).pop("yes");
          },
        ),
      ),
    );

    // make sure to at least delay some time otherwise flutter pops back more than a single route lol...
    final minTimeFuture =
        Future<void>.delayed(const Duration(milliseconds: 200));

    final result = await Future.wait<dynamic>([resultFuture, minTimeFuture]);

    if (context.mounted && result[0] == "yes") {
      Navigator.of(context).pop();
      ref.read(pFrostScaffoldArgs.state).state = null;
    }

    _requestPopLock = false;
  }

  @override
  void initState() {
    _routes = ref.read(pFrostScaffoldArgs)!.stepRoutes;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Util.isDesktop && ref.watch(pFrostScaffoldCanPopDesktop),
      onPopInvoked: (_) => _requestPop(context),
      child: Material(
        child: ConditionalParent(
          condition: Util.isDesktop,
          builder: (child) => child,
          child: ConditionalParent(
            condition: !Util.isDesktop,
            builder: (child) => Background(
              child: Scaffold(
                backgroundColor:
                    Theme.of(context).extension<StackColors>()!.background,
                body: SafeArea(
                  child: child,
                ),
              ),
            ),
            child: Column(
              children: [
                // header
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${ref.watch(pFrostCreateCurrentStep)} / ${_routes.length}",
                          style: STextStyles.navBarTitle(context).copyWith(
                            fontSize: _titleTextSize,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .customTextButtonEnabledText,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            _routes[ref.watch(pFrostCreateCurrentStep) - 1]
                                .title,
                            style: STextStyles.navBarTitle(context).copyWith(
                              fontSize: _titleTextSize,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        CustomTextButton(
                          text: "Exit",
                          textSize: _titleTextSize,
                          onTap: () => _requestPop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (subContext, constraints) => ProgressBar(
                    width: constraints.maxWidth,
                    height: 3,
                    fillColor: Theme.of(context)
                        .extension<StackColors>()!
                        .customTextButtonEnabledText,
                    backgroundColor: Theme.of(context)
                        .extension<StackColors>()!
                        .customTextButtonEnabledText
                        .withOpacity(0.1),
                    percent:
                        ref.watch(pFrostCreateCurrentStep) / _routes.length,
                  ),
                ),
                Expanded(
                  child: ConditionalParent(
                    condition: Util.isDesktop,
                    builder: (child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: SizedBox(
                            width: 500,
                            child: child,
                          ),
                        )
                      ],
                    ),
                    child: ConditionalParent(
                      condition: !Util.isDesktop,
                      builder: (child) => LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                      child: Navigator(
                        key: _navigatorKey,
                        initialRoute: _routes[0].routeName,
                        onGenerateRoute: FrostRouteGenerator.generateRoute,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

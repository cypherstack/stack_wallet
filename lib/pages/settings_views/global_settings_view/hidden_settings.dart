import 'package:epicmobile/providers/global/debug_service_provider.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiddenSettings extends StatelessWidget {
  const HiddenSettings({Key? key}) : super(key: key);

  static const String routeName = "/hiddenSettings";

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: Container(),
          title: Text(
            "Not so secret anymore",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // Consumer(builder: (_, ref, __) {
                        //   return GestureDetector(
                        //     onTap: () async {
                        //       final trades =
                        //           ref.read(tradesServiceProvider).trades;
                        //
                        //       for (final trade in trades) {
                        //         ref.read(tradesServiceProvider).delete(
                        //             trade: trade, shouldNotifyListeners: false);
                        //       }
                        //       ref.read(tradesServiceProvider).delete(
                        //           trade: trades[0], shouldNotifyListeners: true);
                        //
                        //       // ref.read(notificationsProvider).DELETE_EVERYTHING();
                        //     },
                        //     child: RoundedWhiteContainer(
                        //       child: Text(
                        //         "Delete trade history",
                        //         style: STextStyles.button(context).copyWith(
                        //           color: Theme.of(context).extension<StackColors>()!.accentColorDark
                        //         ),
                        //       ),
                        //     ),
                        //   );
                        // }),
                        const SizedBox(
                          height: 12,
                        ),
                        Consumer(builder: (_, ref, __) {
                          return GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(debugServiceProvider)
                                  .deleteAllMessages();

                              // unawaited(showFloatingFlushBar(
                              //   type: FlushBarType.success,
                              //   message: "Debug Logs deleted",
                              //   context: context,
                              // ));
                            },
                            child: RoundedWhiteContainer(
                              child: Text(
                                "Delete Debug Logs",
                                style: STextStyles.button(context).copyWith(
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .accentColorDark),
                              ),
                            ),
                          );
                        }),
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // GestureDetector(
                        //   onTap: () async {
                        //     showDialog<void>(
                        //       context: context,
                        //       builder: (_) {
                        //         return StackDialogBase(
                        //           child: SizedBox(
                        //             width: 200,
                        //             child: Lottie.asset(
                        //               Assets.lottie.test2,
                        //             ),
                        //           ),
                        //         );
                        //       },
                        //     );
                        //   },
                        //   child: RoundedWhiteContainer(
                        //     child: Text(
                        //       "Lottie test",
                        //       style: STextStyles.button(context).copyWith(
                        //         color: Theme.of(context).extension<StackColors>()!.accentColorDark
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/toggle.dart';
import 'sub_widgets/buy_spark_name_option_widget.dart';
import 'sub_widgets/manage_spark_names_option_widget.dart';

class SparkNamesHomeView extends ConsumerStatefulWidget {
  const SparkNamesHomeView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/sparkNamesHomeView";

  @override
  ConsumerState<SparkNamesHomeView> createState() =>
      _NamecoinNamesHomeViewState();
}

class _NamecoinNamesHomeViewState extends ConsumerState<SparkNamesHomeView> {
  bool _onManage = true;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar:
          isDesktop
              ? DesktopAppBar(
                isCompactHeight: true,
                background: Theme.of(context).extension<StackColors>()!.popupBG,
                leading: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 20),
                      child: AppBarIconButton(
                        size: 32,
                        color:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.textFieldDefaultBG,
                        shadows: const [],
                        icon: SvgPicture.asset(
                          Assets.svg.arrowLeft,
                          width: 18,
                          height: 18,
                          color:
                              Theme.of(
                                context,
                              ).extension<StackColors>()!.topNavIconPrimary,
                        ),
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                    SvgPicture.asset(
                      Assets.svg.robotHead,
                      width: 32,
                      height: 32,
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark,
                    ),
                    const SizedBox(width: 10),
                    Text("Names", style: STextStyles.desktopH3(context)),
                  ],
                ),
              )
              : AppBar(
                leading: AppBarBackButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                titleSpacing: 0,
                title: Text(
                  "Names",
                  style: STextStyles.navBarTitle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder:
            (child) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: child,
              ),
            ),
        child:
            Util.isDesktop
                ? Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 460,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Register",
                                  style: STextStyles.desktopTextExtraSmall(
                                    context,
                                  ).copyWith(
                                    color:
                                        Theme.of(context)
                                            .extension<StackColors>()!
                                            .textFieldActiveSearchIconLeft,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Flexible(
                              child: BuySparkNameOptionWidget(
                                walletId: widget.walletId,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        child: SizedBox(
                          width: 520,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Names",
                                    style: STextStyles.desktopTextExtraSmall(
                                      context,
                                    ).copyWith(
                                      color:
                                          Theme.of(context)
                                              .extension<StackColors>()!
                                              .textFieldActiveSearchIconLeft,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: ManageSparkNamesOptionWidget(
                                    walletId: widget.walletId,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Toggle(
                        key: UniqueKey(),
                        onColor:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        offColor:
                            Theme.of(
                              context,
                            ).extension<StackColors>()!.textFieldDefaultBG,
                        onText: "Register",
                        offText: "Names",
                        isOn: !_onManage,
                        onValueChanged: (value) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {
                            _onManage = !value;
                          });
                        },
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: IndexedStack(
                        index: _onManage ? 0 : 1,
                        children: [
                          BuySparkNameOptionWidget(walletId: widget.walletId),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: SingleChildScrollView(
                                  child: IntrinsicHeight(
                                    child: ManageSparkNamesOptionWidget(
                                      walletId: widget.walletId,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

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
import 'sub_widgets/buy_domain_option_widget.dart';
import 'sub_widgets/manage_domains_option_widget.dart';

class NamecoinNamesHomeView extends ConsumerStatefulWidget {
  const NamecoinNamesHomeView({
    super.key,
    required this.walletId,
  });

  final String walletId;

  static const String routeName = "/namecoinNamesHomeView";

  @override
  ConsumerState<NamecoinNamesHomeView> createState() =>
      _NamecoinNamesHomeViewState();
}

class _NamecoinNamesHomeViewState extends ConsumerState<NamecoinNamesHomeView> {
  bool _onManage = true;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final isDesktop = Util.isDesktop;

    return MasterScaffold(
      isDesktop: isDesktop,
      appBar: isDesktop
          ? DesktopAppBar(
              isCompactHeight: true,
              background: Theme.of(context).extension<StackColors>()!.popupBG,
              leading: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 20,
                    ),
                    child: AppBarIconButton(
                      size: 32,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textFieldDefaultBG,
                      shadows: const [],
                      icon: SvgPicture.asset(
                        Assets.svg.arrowLeft,
                        width: 18,
                        height: 18,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .topNavIconPrimary,
                      ),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                  SvgPicture.asset(
                    Assets.svg.robotHead,
                    width: 32,
                    height: 32,
                    color: Theme.of(context).extension<StackColors>()!.textDark,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Domains",
                    style: STextStyles.desktopH3(context),
                  ),
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
                "Domains",
                style: STextStyles.navBarTitle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: ConditionalParent(
        condition: !isDesktop,
        builder: (child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: Util.isDesktop ? 24 : 16,
                left: Util.isDesktop ? 24 : 16,
                right: Util.isDesktop ? 24 : 16,
              ),
              child: SizedBox(
                height: 48,
                child: Toggle(
                  key: UniqueKey(),
                  onColor: Theme.of(context).extension<StackColors>()!.popupBG,
                  offColor: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  onText: "Buy domain",
                  offText: "Manage domains",
                  isOn: !_onManage,
                  onValueChanged: (value) {
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
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Util.isDesktop ? 24 : 16),
                child: IndexedStack(
                  index: _onManage ? 0 : 1,
                  children: [
                    BuyDomainOptionWidget(
                      walletId: widget.walletId,
                    ),
                    ManageDomainsOptionWidget(
                      walletId: widget.walletId,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

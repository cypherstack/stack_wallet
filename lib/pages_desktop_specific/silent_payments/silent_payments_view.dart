// ignore_for_file: unused_import, prefer_const_constructors, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../notifications/show_flush_bar.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/conditional_parent.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/desktop_app_bar.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/icon_widgets/copy_icon.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/qr.dart';

class SilentPaymentsView extends ConsumerStatefulWidget {
  const SilentPaymentsView({super.key, required this.walletId});

  final String walletId;

  static const String routeName = "/silentPayments";

  @override
  ConsumerState<SilentPaymentsView> createState() => _SilentPaymentsViewState();
}

class _SilentPaymentsViewState extends ConsumerState<SilentPaymentsView> {
  bool _enabled = false;
  bool _isLoading = false;

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
                    Text(
                      "Silent Payments",
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
                  "Silent Payments",
                  style: STextStyles.navBarTitle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color:
                      Theme.of(
                        context,
                      ).extension<StackColors>()!.accentColorDark,
                ),
              )
              : ConditionalParent(
                condition: !isDesktop,
                builder:
                    (child) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: child,
                      ),
                    ),
                child: Column(
                  crossAxisAlignment:
                      isDesktop
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                  children: [
                    ConditionalParent(
                      condition: isDesktop,
                      builder:
                          (child) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: RoundedWhiteContainer(
                              padding: const EdgeInsets.all(16),
                              child: child,
                            ),
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: Text(
                              "Scan for Silent Payments",
                              style:
                                  isDesktop
                                      ? STextStyles.desktopTextMedium(context)
                                      : STextStyles.titleBold12(context),
                            ),
                            value: _enabled,
                            onChanged: (value) {
                              setState(() {
                                _enabled = value;
                              });
                            },
                            activeColor:
                                Theme.of(
                                  context,
                                ).extension<StackColors>()!.accentColorGreen,
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

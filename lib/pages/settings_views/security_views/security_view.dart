import 'package:epicpay/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicpay/pages/settings_views/security_views/change_pin_view/change_pin_view.dart';
import 'package:epicpay/providers/global/prefs_provider.dart';
import 'package:epicpay/route_generator.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SecurityView extends StatelessWidget {
  const SecurityView({
    Key? key,
    this.biometrics = true,
  }) : super(key: key);

  static const String routeName = "/security";

  final bool biometrics;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final small = MediaQuery.of(context).size.width < 350;

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            "Security",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      RouteGenerator.getRoute(
                        shouldUseMaterialRoute:
                            RouteGenerator.useMaterialPageRoute,
                        builder: (_) => const LockscreenView(
                          showBackButton: true,
                          routeOnSuccess: ChangePinView.routeName,
                          biometricsCancelButtonString: "CANCEL",
                          biometricsLocalizedReason:
                              "Authenticate to change PIN",
                          biometricsAuthenticationTitle: "Change PIN",
                        ),
                        settings:
                            const RouteSettings(name: "/changepinlockscreen"),
                      ),
                    );
                  },
                  child: Container(
                    height: 56,
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Change PIN",
                          style: STextStyles.bodyBold(context),
                          textAlign: TextAlign.left,
                        ),
                        SvgPicture.asset(
                          Assets.svg.chevronRight,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                GestureDetector(
                  onTap: () {
                    //
                  },
                  child: Container(
                    height: 56,
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          small
                              ? "Enable biometrics"
                              : "Enable biometric authentication",
                          style: STextStyles.bodyBold(context),
                          textAlign: TextAlign.left,
                        ),
                        Consumer(builder: (context, ref, __) {
                          return SizedBox(
                            height: 24,
                            width: 48,
                            child: DraggableSwitchButton(
                              enabled: biometrics,
                              isOn: ref.watch(
                                prefsChangeNotifierProvider
                                    .select((value) => value.useBiometrics),
                              ),
                              onValueChanged: (newValue) {
                                ref
                                    .read(prefsChangeNotifierProvider)
                                    .useBiometrics = newValue;
                              },
                            ),
                          );
                        }),
                      ],
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

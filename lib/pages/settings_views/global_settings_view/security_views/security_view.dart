import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/security_views/change_pin_view/change_pin_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class SecurityView extends StatelessWidget {
  const SecurityView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/security";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      backgroundColor: StackTheme.instance.color.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Security",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: RawMaterialButton(
                // splashColor: StackTheme.instance.color.highlight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    RouteGenerator.getRoute(
                      shouldUseMaterialRoute:
                          RouteGenerator.useMaterialPageRoute,
                      builder: (_) => const LockscreenView(
                        showBackButton: true,
                        routeOnSuccess: ChangePinView.routeName,
                        biometricsCancelButtonString: "CANCEL",
                        biometricsLocalizedReason: "Authenticate to change PIN",
                        biometricsAuthenticationTitle: "Change PIN",
                      ),
                      settings:
                          const RouteSettings(name: "/changepinlockscreen"),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Change PIN",
                        style: STextStyles.titleBold12,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            RoundedWhiteContainer(
              child: Consumer(
                builder: (_, ref, __) {
                  return RawMaterialButton(
                    // splashColor: StackTheme.instance.color.highlight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    onPressed: null,
                    //     () {
                    //   final useBio =
                    //       ref.read(prefsChangeNotifierProvider).useBiometrics;
                    //
                    //   debugPrint("useBio: $useBio");
                    //   ref.read(prefsChangeNotifierProvider).useBiometrics =
                    //       !useBio;
                    //
                    //   debugPrint(
                    //       "useBio set to: ${ref.read(prefsChangeNotifierProvider).useBiometrics}");
                    // },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Enable biometric authentication",
                            style: STextStyles.titleBold12,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 20,
                            width: 40,
                            child: DraggableSwitchButton(
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

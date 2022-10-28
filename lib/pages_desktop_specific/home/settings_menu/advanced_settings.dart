import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AdvancedSettings extends ConsumerStatefulWidget {
  const AdvancedSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuAdvanced";

  @override
  ConsumerState<AdvancedSettings> createState() => _AdvancedSettings();
}

class _AdvancedSettings extends ConsumerState<AdvancedSettings> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleLanguage,
                  width: 48,
                  height: 48,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Advanced",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text:
                                  "\n\nConfigurate these settings only if you know what you are doing!",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(
                        10,
                      ),
                      child: ShowLogsButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ShowLogsButton extends ConsumerWidget {
  const ShowLogsButton({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {},
        child: Text(
          "Show logs",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}

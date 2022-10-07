import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class StackPrivacyCalls extends ConsumerStatefulWidget {
  const StackPrivacyCalls({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/stackPrivacy";

  @override
  ConsumerState<StackPrivacyCalls> createState() => _StackPrivacyCalls();
}

class _StackPrivacyCalls extends ConsumerState<StackPrivacyCalls> {
  final PageController _pageController =
      PageController(initialPage: 0, keepPage: true);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Choose your Stack experience",
                  style: STextStyles.pageTitleH1(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "You can change it later in Settings",
                  style: STextStyles.subtitle(context),
                ),
                const SizedBox(
                  height: 36,
                ),
                RoundedWhiteContainer(
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style:
                            STextStyles.label(context).copyWith(fontSize: 12.0),
                        children: [
                          const TextSpan(
                              text:
                                  "Exchange data preloaded for a seamless experience."),
                          const TextSpan(
                              text:
                                  "CoinGecko enabled: (24 hour price change shown in-app, total wallet value shown in USD or other currency)."),
                          TextSpan(
                              text: "Recommended for most crypto users.",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

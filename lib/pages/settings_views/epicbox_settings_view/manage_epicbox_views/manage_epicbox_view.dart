import 'package:epicpay/providers/providers.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/rounded_white_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageEpicBoxView extends ConsumerStatefulWidget {
  const ManageEpicBoxView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/manage_EpicBox";

  @override
  ConsumerState<ManageEpicBoxView> createState() => _ManageEpicBoxViewState();
}

class _ManageEpicBoxViewState extends ConsumerState<ManageEpicBoxView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showTestNet = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
    );

    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Manage Epic Box servers",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 12,
            right: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: RoundedWhiteContainer(
                      padding: const EdgeInsets.all(0),
                      child: RawMaterialButton(
                        // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Constants.size.circularBorderRadius,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () {
                          // Navigator.of(context).pushNamed(
                          //   CoinEpicBoxView.routeName,
                          // );
                          print('TODO implement');
                        },
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}

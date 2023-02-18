import 'package:epicpay/pages/settings_views/epicbox_settings_view/manage_epicbox_views/add_edit_epicbox_view.dart';
import 'package:epicpay/pages/settings_views/epicbox_settings_view/sub_widgets/epicbox_list.dart';
import 'package:epicpay/utilities/assets.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/text_styles.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:epicpay/utilities/util.dart';
import 'package:epicpay/widgets/background.dart';
import 'package:epicpay/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicpay/widgets/custom_buttons/blue_text_button.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog.dart';
import 'package:epicpay/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuple/tuple.dart';

class EpicBoxesView extends ConsumerStatefulWidget {
  const EpicBoxesView({
    Key? key,
    this.rootNavigator = false,
  }) : super(key: key);

  static const String routeName = "/epicBoxes";

  final bool rootNavigator;

  @override
  ConsumerState<EpicBoxesView> createState() => _EpicBoxesViewState();
}

class _EpicBoxesViewState extends ConsumerState<EpicBoxesView> {
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
    if (Util.isDesktop) {
      return DesktopDialog(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Epic Box servers",
                    style: STextStyles.desktopTextExtraSmall(context).copyWith(
                      color:
                          Theme.of(context).extension<StackColors>()!.textDark,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  BlueTextButton(
                    text: "Add new node",
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AddEditEpixBoxView.routeName,
                        arguments: Tuple3(
                          AddEditNodeViewType.add,
                          null,
                          EpicBoxesView.routeName,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: EpicBoxList(
                popBackToRoute: EpicBoxesView.routeName,
              ),
            ),
          ],
        ),
      );
    } else {
      return Background(
        child: Scaffold(
          backgroundColor:
              Theme.of(context).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "Epic Box servers",
              style: STextStyles.titleH4(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppBarIconButton(
                    key: const Key("manageEpicBoxesAddNewNodeButtonKey"),
                    size: 36,
                    shadows: const [],
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                    icon: SvgPicture.asset(
                      Assets.svg.plus,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .accentColorDark,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AddEditNodeView.routeName,
                        arguments: Tuple3(
                          AddEditNodeViewType.add,
                          null,
                          EpixBoxesView.routeName,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 12,
              left: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: EpicBoxList(
                popBackToRoute: EpixBoxesView.routeName,
              ),
            ),
          ),
        ),
      );
    }
  }
}

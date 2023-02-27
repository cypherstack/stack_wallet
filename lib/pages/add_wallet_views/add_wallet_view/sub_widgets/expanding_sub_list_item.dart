import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/add_wallet_entity_list.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/animated_widgets/rotate_icon.dart';
import 'package:stackwallet/widgets/expandable.dart';

class ExpandingSubListItem extends StatefulWidget {
  const ExpandingSubListItem({
    Key? key,
    required this.title,
    required this.entities,
    required this.initialState,
    double? animationDurationMultiplier,
    this.curve = Curves.easeInOutCubicEmphasized,
  })  : animationDurationMultiplier =
            animationDurationMultiplier ?? entities.length * 0.11,
        super(key: key);

  final String title;
  final List<AddWalletListEntity> entities;
  final ExpandableState initialState;
  final double animationDurationMultiplier;
  final Curve curve;

  @override
  State<ExpandingSubListItem> createState() => _ExpandingSubListItemState();
}

class _ExpandingSubListItemState extends State<ExpandingSubListItem> {
  final isDesktop = Util.isDesktop;

  late final ExpandableController _controller;
  late final RotateIconController _rotateIconController;

  @override
  void initState() {
    _controller = ExpandableController();
    _rotateIconController = RotateIconController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialState == ExpandableState.expanded) {
        _controller.toggle?.call();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.toggle = null;
    _rotateIconController.forward = null;
    _rotateIconController.reverse = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expandable(
      animationDurationMultiplier: widget.animationDurationMultiplier,
      curve: widget.curve,
      controller: _controller,
      onExpandWillChange: (state) {
        if (state == ExpandableState.expanded) {
          _rotateIconController.forward?.call();
        } else {
          _rotateIconController.reverse?.call();
        }
      },
      header: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: isDesktop
                    ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                      )
                    : STextStyles.smallMed12(context),
                textAlign: TextAlign.left,
              ),
              RotateIcon(
                icon: SvgPicture.asset(
                  Assets.svg.chevronDown,
                  width: 12,
                  height: 6,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldActiveSearchIconRight,
                ),
                curve: widget.curve,
                animationDurationMultiplier: widget.animationDurationMultiplier,
                controller: _rotateIconController,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        primary: false,
        child: AddWalletEntityList(
          entities: widget.entities,
        ),
      ),
    );
  }
}

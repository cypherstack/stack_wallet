import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';

class FavoriteToggle extends StatefulWidget {
  const FavoriteToggle({
    Key? key,
    this.backGround,
    this.borderRadius = BorderRadius.zero,
    this.initialState = false,
    this.on,
    this.off,
    required this.onChanged,
  }) : super(key: key);

  final Color? backGround;
  final Color? on;
  final Color? off;
  final BorderRadiusGeometry borderRadius;
  final bool initialState;
  final void Function(bool)? onChanged;

  @override
  State<FavoriteToggle> createState() => _FavoriteToggleState();
}

class _FavoriteToggleState extends State<FavoriteToggle> {
  late bool _isActive;
  late Color _color;
  late void Function(bool)? _onChanged;

  late final Color on;
  late final Color off;

  @override
  void initState() {
    on = widget.on ?? StackTheme.instance.color.infoItemIcons;
    off = widget.off ?? StackTheme.instance.color.buttonBackSecondary;
    _isActive = widget.initialState;
    _color = _isActive ? on : off;
    _onChanged = widget.onChanged;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backGround,
        borderRadius: widget.borderRadius,
      ),
      child: MaterialButton(
        splashColor: StackTheme.instance.color.highlight,
        minWidth: 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
        ),
        onPressed: _onChanged != null
            ? () {
                _isActive = !_isActive;
                setState(() {
                  _color = _isActive ? on : off;
                });
                _onChanged!.call(_isActive);
              }
            : null,
        child: SvgPicture.asset(
          Assets.svg.star,
          width: 16,
          height: 16,
          color: _color,
        ),
      ),
    );
  }
}

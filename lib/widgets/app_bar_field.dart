import 'package:flutter/material.dart';
import 'package:stackduo/utilities/text_styles.dart';

class AppBarSearchField extends StatefulWidget {
  const AppBarSearchField({
    Key? key,
    required this.controller,
    this.focusNode,
  }) : super(key: key);

  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<AppBarSearchField> createState() => _AppBarSearchFieldState();
}

class _AppBarSearchFieldState extends State<AppBarSearchField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
        ),
        Expanded(
          child: TextField(
            autofocus: true,
            focusNode: widget.focusNode,
            controller: widget.controller,
            style: STextStyles.field(context),
            decoration: InputDecoration(
              fillColor: Colors.transparent,
              hintText: "Search...",
              hintStyle: STextStyles.fieldLabel(context),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

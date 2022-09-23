import 'package:flutter/material.dart';

class TableViewCell extends StatelessWidget {
  const TableViewCell({
    Key? key,
    required this.flex,
    required this.child,
  }) : super(key: key);

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

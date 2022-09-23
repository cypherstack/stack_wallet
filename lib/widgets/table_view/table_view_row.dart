import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';

class TableViewRow extends StatelessWidget {
  const TableViewRow({
    Key? key,
    required this.cells,
    required this.expandingChild,
    this.decoration,
    this.onExpandChanged,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  final List<TableViewCell> cells;
  final Widget? expandingChild;
  final Decoration? decoration;
  final void Function(ExpandableState)? onExpandChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: expandingChild == null
          ? Padding(
              padding: padding,
              child: Row(
                children: [
                  ...cells.map(
                    (e) => Expanded(
                      flex: e.flex,
                      child: e,
                    ),
                  ),
                ],
              ),
            )
          : Expandable(
              onExpandChanged: onExpandChanged,
              header: Padding(
                padding: padding,
                child: Row(
                  children: [
                    ...cells.map(
                      (e) => Expanded(
                        flex: e.flex,
                        child: e,
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Container(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .buttonBackSecondary,
                    width: double.infinity,
                    height: 1,
                  ),
                  expandingChild!,
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/expandable.dart';
import 'package:epicmobile/widgets/table_view/table_view_cell.dart';

class TableViewRow extends StatelessWidget {
  const TableViewRow({
    Key? key,
    required this.cells,
    required this.expandingChild,
    this.decoration,
    this.onExpandChanged,
    this.padding = const EdgeInsets.all(0),
    this.spacing = 0.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  final List<TableViewCell> cells;
  final Widget? expandingChild;
  final Decoration? decoration;
  final void Function(ExpandableState)? onExpandChanged;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: expandingChild == null
          ? Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  for (int i = 0; i < cells.length; i++) ...[
                    if (i != 0 && i != cells.length)
                      SizedBox(
                        width: spacing,
                      ),
                    Expanded(
                      flex: cells[i].flex,
                      child: cells[i],
                    ),
                  ],
                ],
              ),
            )
          : Expandable(
              onExpandChanged: onExpandChanged,
              header: Padding(
                padding: padding,
                child: Row(
                  children: [
                    for (int i = 0; i < cells.length; i++) ...[
                      if (i != 0 && i != cells.length)
                        SizedBox(
                          width: spacing,
                        ),
                      Expanded(
                        flex: cells[i].flex,
                        child: cells[i],
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/expandable.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';

class TableViewRow extends StatefulWidget {
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
  final BoxDecoration? decoration;
  final void Function(ExpandableState)? onExpandChanged;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<TableViewRow> createState() => _TableViewRowState();
}

class _TableViewRowState extends State<TableViewRow> {
  late final List<TableViewCell> cells;
  late final Widget? expandingChild;
  late final BoxDecoration? decoration;
  late final void Function(ExpandableState)? onExpandChanged;
  late final EdgeInsetsGeometry padding;
  late final double spacing;
  late final CrossAxisAlignment crossAxisAlignment;

  bool _hovering = false;

  @override
  void initState() {
    cells = widget.cells;
    expandingChild = widget.expandingChild;
    decoration = widget.decoration;
    onExpandChanged = widget.onExpandChanged;
    padding = widget.padding;
    spacing = widget.spacing;
    crossAxisAlignment = widget.crossAxisAlignment;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: !_hovering
          ? decoration
          : decoration?.copyWith(
              boxShadow: [
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
                Theme.of(context).extension<StackColors>()!.standardBoxShadow,
              ],
            ),
      child: expandingChild == null
          ? MouseRegion(
              onEnter: (_) {
                setState(() {
                  _hovering = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _hovering = false;
                });
              },
              child: Padding(
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
              ),
            )
          : Expandable(
              onExpandChanged: onExpandChanged,
              header: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _hovering = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hovering = false;
                  });
                },
                child: Padding(
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

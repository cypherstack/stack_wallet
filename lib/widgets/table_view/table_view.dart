import 'package:flutter/material.dart';

class TableView extends StatelessWidget {
  const TableView({
    Key? key,
    required this.rows,
    this.rowSpacing = 10.0,
    this.shrinkWrap = false,
  }) : super(key: key);

  final List<Widget> rows;
  final double rowSpacing;
  final bool shrinkWrap;
//
//   @override
//   State<TableView> createState() => _TableViewState();
// }
//
// class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return ListView(
      shrinkWrap: shrinkWrap,
      children: [
        for (int i = 0; i < rows.length; i++)
          Column(
            children: [
              if (i != 0)
                SizedBox(
                  height: rowSpacing,
                ),
              rows[i],
            ],
          )
      ],
    );
  }
}

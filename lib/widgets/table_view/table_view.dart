import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

class TableView extends StatefulWidget {
  const TableView({
    Key? key,
    required this.rows,
    this.rowSpacing = 10.0,
    this.shrinkWrap = false,
  }) : super(key: key);

  final List<TableViewRow> rows;
  final double rowSpacing;
  final bool shrinkWrap;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: widget.shrinkWrap,
      children: [
        for (int i = 0; i < widget.rows.length; i++)
          Column(
            children: [
              if (i != 0)
                SizedBox(
                  height: widget.rowSpacing,
                ),
              widget.rows[i],
            ],
          )
      ],
    );
  }
}

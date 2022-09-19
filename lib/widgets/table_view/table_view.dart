import 'package:flutter/material.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

class TableView extends StatefulWidget {
  const TableView({Key? key, required this.rows}) : super(key: key);

  final List<TableViewRow> rows;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.rows,
    );
  }
}

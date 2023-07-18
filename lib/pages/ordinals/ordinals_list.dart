import 'package:flutter/material.dart';
import 'package:stackwallet/models/ordinal.dart';
import 'package:stackwallet/pages/ordinals/widgets/ordinal_card.dart';

class OrdinalsList extends StatefulWidget {
  const OrdinalsList({
    super.key,
    required this.ordinals,
  });

  final List<Ordinal> ordinals;

  @override
  State<OrdinalsList> createState() => _OrdinalsListState();
}

class _OrdinalsListState extends State<OrdinalsList> {
  static const spacing = 10.0;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: widget.ordinals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (_, i) => OrdinalCard(
        ordinal: widget.ordinals[i],
      ),
    );
  }
}

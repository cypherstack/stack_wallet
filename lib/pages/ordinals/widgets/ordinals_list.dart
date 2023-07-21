import 'package:flutter/material.dart';
import 'package:stackwallet/models/ordinal.dart';

import 'package:stackwallet/pages/ordinals/widgets/ordinal_card.dart';

class OrdinalsList extends StatelessWidget {
  const OrdinalsList({
    Key? key,
    required this.walletId,
    required this.ordinalsFuture,
  }) : super(key: key);

  final String walletId;
  final Future<List<Ordinal>> ordinalsFuture;

  get spacing => 2.0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ordinal>>(
      future: ordinalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final List<Ordinal> ordinals = snapshot.data!;
          return GridView.builder(
            shrinkWrap: true,
            itemCount: ordinals.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: spacing as double,
              mainAxisSpacing: spacing as double,
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
            ),
            itemBuilder: (_, i) => OrdinalCard(
              walletId: walletId,
              ordinal: ordinals[i],
            ),
          );
        } else {
          return Text('No data found.');
        }
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:stackwallet/models/ordinal.dart';

import 'package:stackwallet/pages_desktop_specific/ordinals/subwidgets/desktop_ordinal_card.dart';

class DesktopOrdinalsList extends StatelessWidget {
  const DesktopOrdinalsList({
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
              crossAxisCount: 4,
              childAspectRatio: 6 / 7, // was 3/4, less data displayed now
            ),
            itemBuilder: (_, i) => DesktopOrdinalCard(
              walletId: walletId,
              ordinal: ordinals[i],
            ),
          );
        } else {
          return const Text('No data found.');
        }
      },
    );
  }
}
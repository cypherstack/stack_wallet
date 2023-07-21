import 'package:flutter/material.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';

import 'package:stackwallet/pages/ordinals/widgets/ordinal_card.dart';

class OrdinalsList extends StatelessWidget {
  const OrdinalsList({
    Key? key,
    required this.walletId,
    required this.ordinalsFuture,
  }) : super(key: key);

  final String walletId;
  final Future<List<InscriptionData>> ordinalsFuture;

  get spacing => 2.0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InscriptionData>>(
      future: ordinalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final List<InscriptionData> inscriptions = snapshot.data!;
          return GridView.builder(
            shrinkWrap: true,
            itemCount: inscriptions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: spacing as double,
              mainAxisSpacing: spacing as double,
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
            ),
            itemBuilder: (_, i) => OrdinalCard(
              walletId: walletId,
              inscriptionData: inscriptions[i],
            ),
          );
        } else {
          return Text('No data found.');
        }
      },
    );
  }
}
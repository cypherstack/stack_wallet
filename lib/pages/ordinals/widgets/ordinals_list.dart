import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../models/isar/ordinal.dart';
import 'ordinal_card.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/text_styles.dart';
import '../../../utilities/util.dart';
import '../../../widgets/rounded_white_container.dart';

class OrdinalsList extends ConsumerStatefulWidget {
  const OrdinalsList({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<OrdinalsList> createState() => _OrdinalsListState();
}

class _OrdinalsListState extends ConsumerState<OrdinalsList> {
  final double _spacing = Util.isDesktop ? 16 : 10;

  late List<Ordinal> _data;

  late final Stream<List<Ordinal>?> _stream;

  @override
  void initState() {
    _stream = ref
        .read(mainDBProvider)
        .isar
        .ordinals
        .where()
        .filter()
        .walletIdEqualTo(widget.walletId)
        .watch();

    _data = ref
        .read(mainDBProvider)
        .isar
        .ordinals
        .where()
        .filter()
        .walletIdEqualTo(widget.walletId)
        .findAllSync();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ordinal>?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _data = snapshot.data!;
        }

        if (_data.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundedWhiteContainer(
                child: Center(
                  child: Text(
                    "Your ordinals will appear here",
                    style: Util.isDesktop
                        ? STextStyles.w500_14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textSubtitle1)
                        : STextStyles.label(context),
                  ),
                ),
              ),
            ],
          );
        }

        if (Util.isDesktop) {
          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: _data
                .map((e) => SizedBox(
                    width: 220,
                    height: 270,
                    child: OrdinalCard(
                      walletId: widget.walletId,
                      ordinal: e,
                    )))
                .toList(),
          );
        } else {
          return GridView.builder(
            shrinkWrap: true,
            itemCount: _data.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: _spacing,
              mainAxisSpacing: _spacing,
              crossAxisCount: Util.isDesktop ? 4 : 2,
              childAspectRatio: 6 / 7, // was 3/4, less data displayed now
            ),
            itemBuilder: (_, i) => OrdinalCard(
              walletId: widget.walletId,
              ordinal: _data[i],
            ),
          );
        }
      },
    );
  }
}

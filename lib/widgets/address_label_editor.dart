import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/isar/main_db.dart';
import '../models/isar/models/address_label.dart';
import '../notifications/show_flush_bar.dart';
import '../providers/db/main_db_provider.dart';
import '../providers/wallet/address_label_provider.dart';
import '../themes/stack_colors.dart';
import '../utilities/logger.dart';
import '../utilities/text_styles.dart';
import 'custom_buttons/simple_edit_button.dart';

abstract interface class AddressLabelWriter {
  Future<void> write(AddressLabelKey key, String value);
}

class _MainDBAddressLabelWriter implements AddressLabelWriter {
  const _MainDBAddressLabelWriter(this.db);

  final MainDB db;

  @override
  Future<void> write(AddressLabelKey key, String value) async {
    final existing = db.getAddressLabelSync(key.walletId, key.address);
    await db.putAddressLabel(
      existing?.copyWith(label: value) ??
          AddressLabel(
            walletId: key.walletId,
            addressString: key.address,
            value: value,
            tags: null,
          ),
    );
  }
}

final addressLabelWriterProvider = Provider<AddressLabelWriter>((ref) {
  return _MainDBAddressLabelWriter(ref.watch(mainDBProvider));
});

class AddressLabelEditor extends ConsumerStatefulWidget {
  const AddressLabelEditor({
    super.key,
    required this.walletId,
    required this.address,
    required this.isDesktop,
  });

  final String walletId;
  final String address;
  final bool isDesktop;

  @override
  ConsumerState<AddressLabelEditor> createState() => _AddressLabelEditorState();
}

class _AddressLabelEditorState extends ConsumerState<AddressLabelEditor> {
  Future<void> _pendingWrite = Future.value();

  // Each write is a read-then-put on the unique (address, wallet) index, so
  // writes are chained: two concurrent creates would race and the loser would
  // throw. The key and writer are bound when the edit starts rather than when
  // the edit view returns, because the receiving address can rotate while it
  // is open and this state may be unmounted by then.
  void _queueWrite(
    AddressLabelKey key,
    AddressLabelWriter writer,
    String value,
  ) {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await writer.write(key, value);
      } catch (error, stackTrace) {
        Logging.instance.w(
          'Failed to update address label',
          error: error,
          stackTrace: stackTrace,
        );
        if (mounted) {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message: 'Failed to update address label',
              context: context,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (walletId: widget.walletId, address: widget.address);
    final writer = ref.watch(addressLabelWriterProvider);
    final value = ref.watch(pAddressLabel(key))?.value ?? '';
    final style = widget.isDesktop
        ? STextStyles.desktopTextExtraExtraSmall(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          )
        : STextStyles.itemSubtitle(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(value.isEmpty ? 'No label' : value, style: style)),
        SimpleEditButton(
          editValue: value,
          editLabel: 'label',
          overrideTitle: 'Edit label',
          onValueChanged: (newValue) => _queueWrite(key, writer, newValue),
        ),
      ],
    );
  }
}

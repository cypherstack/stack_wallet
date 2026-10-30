/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 */

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../db/isar/main_db.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../providers/db/main_db_provider.dart';

const maxAddressTagCount = 12;
const maxAddressTagLength = 32;

/// Cc/Cf ranges: `trim()` only removes whitespace, so without this a tag can
/// be non-empty yet render as nothing.
final _invisibleTagChars = RegExp(
  r"[\u0000-\u001f\u007f-\u009f\u00ad\u061c\u180e\u200b-\u200f"
  r"\u202a-\u202e\u2060-\u2064\u2066-\u206f\ufeff\ufff9-\ufffb]",
);

String normalizeAddressTag(String value) =>
    value.replaceAll(_invisibleTagChars, "").trim().toLowerCase();

List<String> distinctAddressTags(Iterable<AddressLabel> labels) {
  final tags = <String>{};
  for (final label in labels) {
    for (final tag in label.tags ?? const <String>[]) {
      final normalized = normalizeAddressTag(tag);
      if (normalized.isNotEmpty) {
        tags.add(normalized);
      }
    }
  }
  return tags.toList()..sort();
}

String? reconcileSelectedAddressTag(String? selectedTag, List<String> tags) {
  final normalized = selectedTag == null
      ? null
      : normalizeAddressTag(selectedTag);
  return normalized != null && tags.contains(normalized) ? normalized : null;
}

@immutable
class WalletAddressFilter {
  const WalletAddressFilter({
    required this.walletId,
    this.searchTerm = "",
    this.tag,
  });

  final String walletId;
  final String searchTerm;
  final String? tag;

  @override
  bool operator ==(Object other) =>
      other is WalletAddressFilter &&
      other.walletId == walletId &&
      other.searchTerm == searchTerm &&
      other.tag == tag;

  @override
  int get hashCode => Object.hash(walletId, searchTerm, tag);
}

final walletAddressTagsProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, walletId) {
      final db = ref.watch(mainDBProvider);
      return db
          .getAddressLabels(walletId)
          .watch(fireImmediately: true)
          .map(distinctAddressTags);
    });

final filteredWalletAddressIdsProvider = StreamProvider.autoDispose
    .family<List<Id>, WalletAddressFilter>((ref, filter) {
      final db = ref.watch(mainDBProvider);
      final changes = StreamGroup.merge<void>([
        db.getAddresses(filter.walletId).watchLazy(fireImmediately: true),
        db.getAddressLabels(filter.walletId).watchLazy(fireImmediately: true),
      ]);
      return changes.asyncMap((_) => findFilteredWalletAddressIds(db, filter));
    });

Future<List<Id>> findFilteredWalletAddressIds(
  MainDB db,
  WalletAddressFilter filter,
) async {
  final term = filter.searchTerm.trim();
  final tag = filter.tag == null ? null : normalizeAddressTag(filter.tag!);

  if (term.isEmpty && tag == null) {
    return db
        .getAddresses(filter.walletId)
        .filter()
        .group(_supportedAddressSubtypes)
        .and()
        .not()
        .typeEqualTo(AddressType.nonWallet)
        .and()
        .group(_supportedFrostAddresses)
        .sortByDerivationIndex()
        .idProperty()
        .findAll();
  }

  final candidates = await db
      .getAddressLabels(filter.walletId)
      .filter()
      .group(
        (q) => tag == null
            ? q.addressStringIsNotEmpty()
            : q.tagsIsNotNull().and().tagsIsNotEmpty(),
      )
      .and()
      .group(
        (q) => term.isEmpty
            ? q.addressStringIsNotEmpty()
            : q
                  .valueContains(term, caseSensitive: false)
                  .or()
                  .addressStringContains(term, caseSensitive: false)
                  .or()
                  .group(
                    (q) => q.tagsIsNotNull().and().tagsElementContains(
                      term,
                      caseSensitive: false,
                    ),
                  ),
      )
      .findAll();

  // Chips are built from normalized tags, so the tag match must be normalized
  // too; Isar compares the raw stored string and would miss an untrimmed tag.
  final labels = tag == null
      ? candidates
      : candidates
            .where(
              (label) => (label.tags ?? const <String>[]).any(
                (t) => normalizeAddressTag(t) == tag,
              ),
            )
            .toList();

  if (labels.isEmpty) {
    return [];
  }

  return db
      .getAddresses(filter.walletId)
      .filter()
      .anyOf<AddressLabel, Address>(
        labels,
        (q, label) => q.valueEqualTo(label.addressString),
      )
      .group(_supportedAddressSubtypes)
      .and()
      .not()
      .typeEqualTo(AddressType.nonWallet)
      .and()
      .group(_supportedFrostAddresses)
      .sortByDerivationIndex()
      .idProperty()
      .findAll();
}

QueryBuilder<Address, Address, QAfterFilterCondition> _supportedAddressSubtypes(
  QueryBuilder<Address, Address, QFilterCondition> q,
) => q
    .subTypeEqualTo(AddressSubType.change)
    .or()
    .subTypeEqualTo(AddressSubType.receiving)
    .or()
    .subTypeEqualTo(AddressSubType.paynymReceive)
    .or()
    .subTypeEqualTo(AddressSubType.paynymNotification);

QueryBuilder<Address, Address, QAfterFilterCondition> _supportedFrostAddresses(
  QueryBuilder<Address, Address, QFilterCondition> q,
) => q
    .group(
      (q) => q.typeEqualTo(AddressType.frostMS).and().zSafeFrostEqualTo(true),
    )
    .or()
    .not()
    .typeEqualTo(AddressType.frostMS);

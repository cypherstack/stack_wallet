part of 'package:stackwallet/db/isar/main_db.dart';

enum CCFilter {
  all,
  available,
  frozen;

  @override
  String toString() {
    if (this == all) {
      return "Show $name outputs";
    }

    return "${name.capitalize()} outputs";
  }
}

enum CCSortDescriptor {
  age,
  address,
  value;

  @override
  String toString() {
    return name.capitalize();
  }
}

extension MainDBQueries on MainDB {
  List<Id> queryUTXOsSync({
    required String walletId,
    required CCFilter filter,
    required CCSortDescriptor sort,
    required String searchTerm,
    required Coin coin,
  }) {
    var preSort = getUTXOs(walletId).filter().group((q) {
      final qq = q.group(
        (q) => q.usedIsNull().or().usedEqualTo(false),
      );
      switch (filter) {
        case CCFilter.frozen:
          return qq.and().isBlockedEqualTo(true);
        case CCFilter.available:
          return qq.and().isBlockedEqualTo(false);
        case CCFilter.all:
          return qq;
      }
    });

    if (searchTerm.isNotEmpty) {
      preSort = preSort.and().group(
        (q) {
          var qq = q.addressContains(searchTerm, caseSensitive: false);

          qq = qq.or().nameContains(searchTerm, caseSensitive: false);
          qq = qq.or().group(
                (q) => q
                    .isBlockedEqualTo(true)
                    .and()
                    .blockedReasonContains(searchTerm, caseSensitive: false),
              );

          qq = qq.or().txidContains(searchTerm, caseSensitive: false);
          qq = qq.or().blockHashContains(searchTerm, caseSensitive: false);

          final maybeDecimal = Decimal.tryParse(searchTerm);
          if (maybeDecimal != null) {
            qq = qq.or().valueEqualTo(
                  Format.decimalAmountToSatoshis(
                    maybeDecimal,
                    coin,
                  ),
                );
          }

          final maybeInt = int.tryParse(searchTerm);
          if (maybeInt != null) {
            qq = qq.or().valueEqualTo(maybeInt);
          }

          return qq;
        },
      );
    }

    final List<Id> ids;
    switch (sort) {
      case CCSortDescriptor.age:
        ids = preSort.sortByBlockHeight().idProperty().findAllSync();
        break;
      case CCSortDescriptor.address:
        ids = preSort.sortByAddress().idProperty().findAllSync();
        break;
      case CCSortDescriptor.value:
        ids = preSort.sortByValueDesc().idProperty().findAllSync();
        break;
    }
    return ids;
  }

  Map<String, List<Id>> queryUTXOsGroupedByAddressSync({
    required String walletId,
    required CCFilter filter,
    required CCSortDescriptor sort,
    required String searchTerm,
    required Coin coin,
  }) {
    var preSort = getUTXOs(walletId).filter().group((q) {
      final qq = q.group(
        (q) => q.usedIsNull().or().usedEqualTo(false),
      );
      switch (filter) {
        case CCFilter.frozen:
          return qq.and().isBlockedEqualTo(true);
        case CCFilter.available:
          return qq.and().isBlockedEqualTo(false);
        case CCFilter.all:
          return qq;
      }
    });

    if (searchTerm.isNotEmpty) {
      preSort = preSort.and().group(
        (q) {
          var qq = q.addressContains(searchTerm, caseSensitive: false);

          qq = qq.or().nameContains(searchTerm, caseSensitive: false);
          qq = qq.or().group(
                (q) => q
                    .isBlockedEqualTo(true)
                    .and()
                    .blockedReasonContains(searchTerm, caseSensitive: false),
              );

          qq = qq.or().txidContains(searchTerm, caseSensitive: false);
          qq = qq.or().blockHashContains(searchTerm, caseSensitive: false);

          final maybeDecimal = Decimal.tryParse(searchTerm);
          if (maybeDecimal != null) {
            qq = qq.or().valueEqualTo(
                  Format.decimalAmountToSatoshis(
                    maybeDecimal,
                    coin,
                  ),
                );
          }

          final maybeInt = int.tryParse(searchTerm);
          if (maybeInt != null) {
            qq = qq.or().valueEqualTo(maybeInt);
          }

          return qq;
        },
      );
    }

    final List<UTXO> utxos;
    switch (sort) {
      case CCSortDescriptor.age:
        utxos = preSort.sortByBlockHeight().findAllSync();
        break;
      case CCSortDescriptor.address:
        utxos = preSort.sortByAddress().findAllSync();
        break;
      case CCSortDescriptor.value:
        utxos = preSort.sortByValueDesc().findAllSync();
        break;
    }

    final Map<String, List<Id>> results = {};
    for (final utxo in utxos) {
      if (results[utxo.address!] == null) {
        results[utxo.address!] = [];
      }
      results[utxo.address!]!.add(utxo.id);
    }

    return results;
  }
}

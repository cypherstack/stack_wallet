import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag_data.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';

void main() {
  const walletId = "wallet-1";
  late Directory tempDir;
  late Isar isar;
  final db = MainDB.instance;

  Address address({
    required String value,
    required int index,
    String wallet = walletId,
    AddressType type = AddressType.p2wpkh,
    AddressSubType subType = AddressSubType.receiving,
    bool? zSafeFrost,
  }) => Address(
    walletId: wallet,
    value: value,
    publicKey: const [],
    derivationIndex: index,
    derivationPath: null,
    type: type,
    subType: subType,
    zSafeFrost: zSafeFrost,
  );

  AddressLabel label({
    required String address,
    required List<String>? tags,
    String value = "",
    String wallet = walletId,
  }) => AddressLabel(
    walletId: wallet,
    addressString: address,
    value: value,
    tags: tags,
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp("stack-tag-test-");
    isar = await Isar.open(
      [AddressSchema, AddressLabelSchema, TransactionSchema],
      directory: tempDir.path,
      name: "address_tag_test",
    );
    await db.initMainDB(mock: isar);
  });

  setUp(() async {
    await isar.writeTxn(() async {
      await isar.addresses.clear();
      await isar.addressLabels.clear();
    });
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  test("normalizes, deduplicates, and reconciles tags", () {
    final tags = distinctAddressTags([
      label(address: "a", tags: [" Work ", "personal"]),
      label(address: "b", tags: ["work", ""]),
    ]);

    expect(tags, ["personal", "work"]);
    expect(reconcileSelectedAddressTag(" WORK ", tags), "work");
    expect(reconcileSelectedAddressTag("removed", tags), isNull);
  });

  test("strips invisible characters when normalizing", () {
    expect(normalizeAddressTag("\u200b"), isEmpty);
    expect(normalizeAddressTag("\u202eevil"), "evil");
    expect(
      distinctAddressTags([
        label(address: "a", tags: ["\u200bwork"]),
        label(address: "b", tags: ["work", "\u200b"]),
      ]),
      ["work"],
    );
  });

  test("filters by normalized tag whatever form is stored", () async {
    await isar.writeTxn(() async {
      await isar.addresses.putAll([
        address(value: "padded", index: 0),
        address(value: "uppercase", index: 1),
      ]);
      await isar.addressLabels.putAll([
        label(address: "padded", tags: [" Savings "]),
        label(address: "uppercase", tags: ["Savings"]),
      ]);
    });

    final chips = distinctAddressTags(
      await db.getAddressLabels(walletId).findAll(),
    );
    expect(chips, ["savings"]);

    // A chip the strip offers must never filter to nothing.
    final ids = await findFilteredWalletAddressIds(
      db,
      WalletAddressFilter(walletId: walletId, tag: chips.single),
    );
    expect(ids, hasLength(2));
  });

  test("filters supported wallet addresses asynchronously", () async {
    await isar.writeTxn(() async {
      await isar.addresses.putAll([
        address(value: "receiving", index: 2),
        address(value: "change", index: 1, subType: AddressSubType.change),
        address(
          value: "unsafe-frost",
          index: 3,
          type: AddressType.frostMS,
          zSafeFrost: false,
        ),
        address(value: "external", index: 4, type: AddressType.nonWallet),
        address(value: "other-wallet", index: 0, wallet: "wallet-2"),
      ]);
      await isar.addressLabels.putAll([
        label(address: "receiving", tags: ["income"], value: "Salary"),
        label(address: "change", tags: ["private"]),
        label(address: "other-wallet", tags: ["income"], wallet: "wallet-2"),
      ]);
    });

    final all = await findFilteredWalletAddressIds(
      db,
      const WalletAddressFilter(walletId: walletId),
    );
    final income = await findFilteredWalletAddressIds(
      db,
      const WalletAddressFilter(walletId: walletId, tag: "INCOME"),
    );
    final salary = await findFilteredWalletAddressIds(
      db,
      const WalletAddressFilter(walletId: walletId, searchTerm: "salary"),
    );

    expect(
      await Future.wait(all.map((id) => isar.addresses.get(id))),
      hasLength(2),
    );
    expect((await isar.addresses.get(all.first))!.value, "change");
    expect((await isar.addresses.get(income.single))!.value, "receiving");
    expect((await isar.addresses.get(salary.single))!.value, "receiving");
  });

  test("tag provider reacts to label changes", () async {
    final first = label(address: "a", tags: ["one"]);
    await db.putAddressLabel(first);
    final container = ProviderContainer(
      overrides: [mainDBProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final initial = Completer<List<String>>();
    final updated = Completer<List<String>>();
    final subscription = container.listen(
      walletAddressTagsProvider(walletId),
      (_, value) => value.whenData((tags) {
        if (tags.contains("two") && !updated.isCompleted) {
          updated.complete(tags);
        } else if (!initial.isCompleted) {
          initial.complete(tags);
        }
      }),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    expect(await initial.future, ["one"]);

    await db.putAddressLabel(first.copyWith(tags: ["one", "two"]));
    expect(await updated.future, ["one", "two"]);
  });

  test(
    "filtered address provider reacts when a selected tag is removed",
    () async {
      final taggedAddress = address(value: "tagged", index: 0);
      final taggedLabel = label(address: "tagged", tags: ["selected"]);
      await isar.writeTxn(() async {
        await isar.addresses.put(taggedAddress);
        await isar.addressLabels.put(taggedLabel);
      });
      final container = ProviderContainer(
        overrides: [mainDBProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final initial = Completer<List<Id>>();
      final removed = Completer<List<Id>>();
      final subscription = container.listen(
        filteredWalletAddressIdsProvider(
          const WalletAddressFilter(walletId: walletId, tag: "selected"),
        ),
        (_, value) => value.whenData((ids) {
          if (ids.isEmpty && initial.isCompleted && !removed.isCompleted) {
            removed.complete(ids);
          } else if (ids.isNotEmpty && !initial.isCompleted) {
            initial.complete(ids);
          }
        }),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(await initial.future, [taggedAddress.id]);
      await db.putAddressLabel(taggedLabel.copyWith(tags: []));
      expect(await removed.future, isEmpty);
    },
  );
}

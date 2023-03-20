import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/utilities/prefs.dart';

import 'cached_electrumx_test.mocks.dart';
// import 'sample_data/get_anonymity_set_sample_data.dart';

@GenerateMocks([ElectrumX, Prefs])
void main() {
  group("tests using mock hive", () {
    setUp(() async {
      await setUpTestHive();
    });
    group("getAnonymitySet", () {
      // test("empty set cache call", () async {
      //   final client = MockElectrumX();
      //   when(
      //     client.getAnonymitySet(
      //       groupId: "1",
      //       blockhash: "",
      //     ),
      //   ).thenAnswer(
      //     (_) async => GetAnonymitySetSampleData.data,
      //   );
      //
      //   final cachedClient = CachedElectrumX(
      //       electrumXClient: client,
      //       port: 0,
      //       failovers: [],
      //       server: '',
      //       useSSL: true,
      //       prefs: Prefs.instance);
      //
      //   final result = await cachedClient.getAnonymitySet(
      //     groupId: "1",
      //     coin: Coin.firo,
      //   );
      //
      //   final expected =
      //       Map<String, dynamic>.from(GetAnonymitySetSampleData.data);
      //   expected["setId"] = "1";
      //
      //   expect(result, expected);
      // });
      //
      // test("use and update set cache call", () async {
      //   final storedData = Map.from(GetAnonymitySetSampleData.initialData);
      //   storedData["setId"] = "1";
      //   final box = await Hive.openBox('Some coinName_anonymitySetCache');
      //   await box.put("1", storedData);
      //
      //   final client = MockElectrumX();
      //   when(
      //     client.getAnonymitySet(
      //       groupId: "1",
      //       blockhash: GetAnonymitySetSampleData.initialData["blockHash"],
      //     ),
      //   ).thenAnswer(
      //     (_) async => GetAnonymitySetSampleData.followUpData,
      //   );
      //
      //   final cachedClient = CCachedElectrumX(
      //       electrumXClient: client,
      //       port: 0,
      //       failovers: [],
      //       server: '',
      //       useSSL: true,
      //       prefs: Prefs.instance);
      //
      //   final result = await cachedClient.getAnonymitySet(
      //     groupId: "1",
      //     coinName: "Some coinName",
      //     callOutSideMainIsolate: true,
      //   );
      //
      //   final expected = Map.from(GetAnonymitySetSampleData.finalData as Map);
      //   expected["setId"] = "1";
      //
      //   expect(result, expected);
      //   fail("This test needs updating");
      // });

      // test("getAnonymitySet throws", () async {
      //   final client = MockElectrumX();
      //   when(
      //     client.getAnonymitySet(
      //       groupId: "1",
      //       blockhash: "",
      //     ),
      //   ).thenThrow(Exception());
      //
      //   final cachedClient = CachedElectrumX(
      //       electrumXClient: client,
      //       port: 0,
      //       failovers: [],
      //       server: '',
      //       useSSL: true,
      //       prefs: Prefs.instance);
      //
      //   expect(
      //       () async => await cachedClient.getAnonymitySet(
      //             groupId: "1",
      //             coin: Coin.firo,
      //           ),
      //       throwsA(isA<Exception>()));
      // });
    });

    // test("clearSharedTransactionCache", () async {
    //   final cachedClient = CachedElectrumX(
    //       server: '',
    //       electrumXClient: MockElectrumX(),
    //       port: 0,
    //       useSSL: true,
    //       prefs: MockPrefs(),
    //       failovers: []);
    //
    //   bool didThrow = false;
    //   try {
    //     await cachedClient.clearSharedTransactionCache(coin: Coin.firo);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, false);
    // });

    tearDown(() async {
      await tearDownTestHive();
    });
  });

  test(".from factory", () {
    final node = ElectrumXNode(
      address: "some address",
      port: 1,
      name: "some name",
      id: "some ID",
      useSSL: true,
    );

    final client = CachedElectrumX.from(
        node: node,
        prefs: MockPrefs(),
        failovers: [],
        electrumXClient: MockElectrumX());

    expect(client, isA<CachedElectrumX>());
  });
}

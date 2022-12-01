import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/models/lelantus_coin.dart';
import 'package:epicmobile/models/paymint/transactions_model.dart';

import 'lelantus_coin_adapter_test.mocks.dart';

@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  test("read", () {
    LelantusCoinAdapter adapter = LelantusCoinAdapter();
    final reader = MockBinaryReader();

    List<int> readByteResponses = [6, 0, 1, 2, 3, 4, 5];
    List<dynamic> readResponses = [
      1,
      1000,
      "kjhxzcfg8u7ty23w8gbdsf87cfgsdf3",
      "some txid",
      1,
      true,
    ];

    when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));
    when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

    final result = adapter.read(reader);

    verify(reader.read()).called(6);
    verify(reader.readByte()).called(7);

    expect(result, isA<LelantusCoin>());
  });

  test("write", () {
    LelantusCoinAdapter adapter = LelantusCoinAdapter();
    LelantusCoin obj =
        LelantusCoin(1, 100, "some public coin", "some txid", 1, true);
    final writer = MockBinaryWriter();

    for (int i = 0; i <= 6; i++) {
      when(writer.writeByte(i)).thenAnswer((_) {
        return;
      });
    }

    when(writer.write(obj.index)).thenAnswer((_) {
      return;
    });
    when(writer.write(obj.value)).thenAnswer((_) {
      return;
    });
    when(writer.write(obj.publicCoin)).thenAnswer((_) {
      return;
    });
    when(writer.write(obj.txId)).thenAnswer((_) {
      return;
    });
    when(writer.write(obj.anonymitySetId)).thenAnswer((_) {
      return;
    });
    when(writer.write(obj.isUsed)).thenAnswer((_) {
      return;
    });

    adapter.write(writer, obj);

    verifyInOrder([
      writer.writeByte(6),
      writer.writeByte(0),
      writer.write(obj.index),
      writer.writeByte(1),
      writer.write(obj.value),
      writer.writeByte(2),
      writer.write(obj.publicCoin),
      writer.writeByte(3),
      writer.write(obj.txId),
      writer.writeByte(4),
      writer.write(obj.anonymitySetId),
      writer.writeByte(5),
      writer.write(obj.isUsed),
    ]);
  });

  test("get hashcode", () {
    final adapter = LelantusCoinAdapter();

    final result = adapter.hashCode;
    expect(result, 9);
  });

  group("compare operator", () {
    test("is equal one", () {
      final a = LelantusCoinAdapter();
      final b = LelantusCoinAdapter();

      final result = a == b;
      expect(result, true);
    });

    test("is equal two", () {
      final a = LelantusCoinAdapter();
      final b = a;

      final result = a == b;
      expect(result, true);
    });

    test("is not equal one", () {
      final a = LelantusCoinAdapter();
      final b = TransactionDataAdapter();

      // ignore: unrelated_type_equality_checks
      final result = a == b;
      expect(result, false);
    });

    test("is not equal two", () {
      final a = LelantusCoinAdapter();

      // ignore: unrelated_type_equality_checks
      final result = a == 8;
      expect(result, false);
    });
  });
}

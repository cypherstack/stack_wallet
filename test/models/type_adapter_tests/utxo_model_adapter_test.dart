import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/models/paymint/transactions_model.dart';
import 'package:epicmobile/models/paymint/utxo_model.dart';

import 'utxo_model_adapter_test.mocks.dart';

@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  group("UtxoDataAdapter", () {
    test("UtxoDataAdapter.read", () {
      final adapter = UtxoDataAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [5];
      for (int i = 0; i < 5; i++) {
        readByteResponses.add(i);
      }

      List<dynamic> readResponses = [
        "100",
        100000000,
        "10",
        <UtxoObject>[],
        0,
      ];

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));
      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(5);
      verify(reader.readByte()).called(6);
      expect(result, isA<UtxoData>());
    });

    test("UtxoDataAdapter.write", () {
      final adapter = UtxoDataAdapter();
      final obj = UtxoData(
        totalUserCurrency: "10000",
        satoshiBalance: 10000000,
        bitcoinBalance: "1",
        unspentOutputArray: [],
        satoshiBalanceUnconfirmed: 0,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 4; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.totalUserCurrency)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.satoshiBalance)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.bitcoinBalance)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.satoshiBalanceUnconfirmed)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.unspentOutputArray)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(5),
        writer.writeByte(0),
        writer.write(obj.totalUserCurrency),
        writer.writeByte(1),
        writer.write(obj.satoshiBalance),
        writer.writeByte(2),
        writer.write(obj.bitcoinBalance),
        writer.writeByte(3),
        writer.write(obj.unspentOutputArray),
        writer.writeByte(4),
        writer.write(obj.satoshiBalanceUnconfirmed),
      ]);
    });

    test("UtxoDataAdapter.hashcode", () {
      final adapter = UtxoDataAdapter();

      final result = adapter.hashCode;
      expect(result, 6);
    });

    group("UtxoDataAdapter compare operator", () {
      test("UtxoDataAdapter is equal one", () {
        final a = UtxoDataAdapter();
        final b = UtxoDataAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("UtxoDataAdapter is equal two", () {
        final a = UtxoDataAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("UtxoDataAdapter is not equal one", () {
        final a = UtxoDataAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("UtxoDataAdapter is not equal two", () {
        final a = UtxoDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("UtxoObjectAdapter", () {
    test("UtxoObjectAdapter.read", () {
      final adapter = UtxoObjectAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [8];
      for (int i = 0; i < 8; i++) {
        readByteResponses.add(i);
      }

      List<dynamic> readResponses = [
        "100",
        1,
        Status(
          confirmed: true,
          blockHash: "hash",
          blockHeight: 1,
          blockTime: 1,
          confirmations: 1,
        ),
        100000,
        "123",
        "10",
        true,
        true,
      ];

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));
      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(8);
      verify(reader.readByte()).called(9);
      expect(result, isA<UtxoObject>());
    });

    test("UtxoObjectAdapter.write", () {
      final adapter = UtxoObjectAdapter();
      final obj = UtxoObject(
        txid: "some txid",
        vout: 1,
        status: Status(
          confirmed: true,
          confirmations: 1,
          blockHeight: 1,
          blockHash: '',
          blockTime: 1,
        ),
        value: 10000,
        fiatWorth: "122",
        txName: "name",
        blocked: true,
        isCoinbase: false,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 7; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.txid)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.vout)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.status)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.value)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.fiatWorth)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.txName)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blocked)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(8),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.vout),
        writer.writeByte(2),
        writer.write(obj.status),
        writer.writeByte(3),
        writer.write(obj.value),
        writer.writeByte(4),
        writer.write(obj.fiatWorth),
        writer.writeByte(5),
        writer.write(obj.txName),
        writer.writeByte(6),
        writer.write(obj.blocked),
        writer.writeByte(7),
        writer.write(obj.isCoinbase),
      ]);
    });

    test("UtxoObjectAdapter.hashcode", () {
      final adapter = UtxoObjectAdapter();

      final result = adapter.hashCode;
      expect(result, 7);
    });

    group("UtxoObjectAdapter compare operator", () {
      test("UtxoObjectAdapter is equal one", () {
        final a = UtxoObjectAdapter();
        final b = UtxoObjectAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("UtxoObjectAdapter is equal two", () {
        final a = UtxoObjectAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("UtxoObjectAdapter is not equal one", () {
        final a = UtxoObjectAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("UtxoObjectAdapter is not equal two", () {
        final a = UtxoObjectAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("StatusAdapter", () {
    test("StatusAdapter.read", () {
      final adapter = StatusAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [5];
      for (int i = 0; i < 5; i++) {
        readByteResponses.add(i);
      }

      List<dynamic> readResponses = [
        true,
        "some blockhash",
        4587364,
        3476523434,
        1,
      ];

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));
      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(5);
      verify(reader.readByte()).called(6);
      expect(result, isA<Status>());
    });

    test("StatusAdapter.write", () {
      final adapter = StatusAdapter();
      final obj = Status(
        confirmed: true,
        blockHash: "some block hash",
        blockHeight: 328746,
        blockTime: 2174381236,
        confirmations: 1,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 4; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.confirmed)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockHash)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockHeight)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.blockTime)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.confirmations)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(5),
        writer.writeByte(0),
        writer.write(obj.confirmed),
        writer.writeByte(1),
        writer.write(obj.blockHash),
        writer.writeByte(2),
        writer.write(obj.blockHeight),
        writer.writeByte(3),
        writer.write(obj.blockTime),
        writer.writeByte(4),
        writer.write(obj.confirmations),
      ]);
    });

    test("StatusAdapter.hashcode", () {
      final adapter = StatusAdapter();

      final result = adapter.hashCode;
      expect(result, 8);
    });

    group("StatusAdapter compare operator", () {
      test("StatusAdapter is equal one", () {
        final a = StatusAdapter();
        final b = StatusAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("StatusAdapter is equal two", () {
        final a = StatusAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("StatusAdapter is not equal one", () {
        final a = StatusAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("StatusAdapter is not equal two", () {
        final a = StatusAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });
}

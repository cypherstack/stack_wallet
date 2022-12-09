import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:epicmobile/models/lelantus_coin.dart';
import 'package:epicmobile/models/paymint/transactions_model.dart';

import 'transactions_model_adapter_test.mocks.dart';

@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  group("TransactionDataAdapter", () {
    test("TransactionDataAdapter.read", () {
      final adapter = TransactionDataAdapter();
      final reader = MockBinaryReader();

      List<int> readeByteResponses = [1, 0];

      when(reader.readByte()).thenAnswer((_) => readeByteResponses.removeAt(0));

      when(reader.read()).thenAnswer((_) => <TransactionChunk>[]);

      final result = adapter.read(reader);

      verify(reader.read()).called(1);
      verify(reader.readByte()).called(2);
      expect(result, isA<TransactionData>());
    });

    test("TransactionDataAdapter.write", () {
      final adapter = TransactionDataAdapter();
      final obj = TransactionData();
      final writer = MockBinaryWriter();

      when(writer.writeByte(1)).thenAnswer((_) {
        return;
      });
      when(writer.writeByte(0)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.txChunks)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(1),
        writer.writeByte(0),
        writer.write(obj.txChunks),
      ]);
    });

    test("TransactionDataAdapter.hashcode", () {
      final adapter = TransactionDataAdapter();

      final result = adapter.hashCode;
      expect(result, 1);
    });

    group("TransactionDataAdapter compare operator", () {
      test("TransactionDataAdapter is equal one", () {
        final a = TransactionDataAdapter();
        final b = TransactionDataAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionDataAdapter is equal two", () {
        final a = TransactionDataAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionDataAdapter is not equal one", () {
        final a = TransactionDataAdapter();
        final b = LelantusCoinAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("TransactionDataAdapter is not equal two", () {
        final a = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("TransactionChunkAdapter", () {
    test("TransactionChunkAdapter.read", () {
      final adapter = TransactionChunkAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [2, 0, 1];

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));

      List<dynamic> readResponses = [
        3426523234,
        <Transaction>[],
      ];

      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(2);
      verify(reader.readByte()).called(3);
      expect(result, isA<TransactionChunk>());
    });

    test("TransactionChunkAdapter.write", () {
      final adapter = TransactionChunkAdapter();
      final obj = TransactionChunk(timestamp: 389475684, transactions: []);
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 2; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.timestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.transactions)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(2),
        writer.writeByte(0),
        writer.write(obj.timestamp),
        writer.writeByte(1),
        writer.write(obj.transactions),
      ]);
    });

    test("TransactionChunkAdapter.hashcode", () {
      final adapter = TransactionChunkAdapter();

      final result = adapter.hashCode;
      expect(result, 2);
    });

    group("TransactionChunkAdapter compare operator", () {
      test("TransactionChunkAdapter is equal one", () {
        final a = TransactionChunkAdapter();
        final b = TransactionChunkAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionChunkAdapter is equal two", () {
        final a = TransactionChunkAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionChunkAdapter is not equal one", () {
        final a = TransactionChunkAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("TransactionChunkAdapter is not equal two", () {
        final a = TransactionChunkAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("TransactionAdapter", () {
    test("TransactionAdapter.read", () {
      final adapter = TransactionAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [20];
      for (int i = 0; i < 20; i++) {
        readByteResponses.add(i);
      }

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));

      List<dynamic> readResponses = [
        "some txid",
        true,
        872346534,
        "Received",
        10000000,
        <dynamic>[],
        "122",
        "122",
        3794,
        3794,
        4,
        [
          Input(txid: "abc", vout: 1),
          Input(txid: "abc", vout: 1),
        ],
        [
          Output(scriptpubkeyAddress: "adr", value: 1),
          Output(scriptpubkeyAddress: "adr", value: 1),
        ],
        "some address",
        458734,
        "mint",
        1,
        false,
        null,
        null,
      ];

      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(20);
      verify(reader.readByte()).called(21);
      expect(result, isA<Transaction>());
    });

    test("TransactionAdapter.write", () {
      final adapter = TransactionAdapter();
      final obj = Transaction(
        txid: "some txid",
        confirmedStatus: false,
        timestamp: 1123,
        txType: "Sent",
        amount: 123,
        worthNow: "0",
        worthAtBlockTimestamp: "0",
        fees: 1,
        inputSize: 1,
        outputSize: 1,
        inputs: [],
        outputs: [],
        address: "address",
        height: 1,
        confirmations: 1,
      );
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 20; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.txid)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.confirmedStatus)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.timestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.txType)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.amount)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.aliens)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.worthNow)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.worthAtBlockTimestamp)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.fees)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.inputSize)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.outputSize)).thenAnswer((_) {
        return;
      });

      when(writer.write(obj.inputs)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.outputs)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.address)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.height)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.subType)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.confirmations)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.isCancelled)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.slateId)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.otherData)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(20),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.confirmedStatus),
        writer.writeByte(2),
        writer.write(obj.timestamp),
        writer.writeByte(3),
        writer.write(obj.txType),
        writer.writeByte(4),
        writer.write(obj.amount),
        writer.writeByte(5),
        writer.write(obj.aliens),
        writer.writeByte(6),
        writer.write(obj.worthNow),
        writer.writeByte(7),
        writer.write(obj.worthAtBlockTimestamp),
        writer.writeByte(8),
        writer.write(obj.fees),
        writer.writeByte(9),
        writer.write(obj.inputSize),
        writer.writeByte(10),
        writer.write(obj.outputSize),
        writer.writeByte(11),
        writer.write(obj.inputs),
        writer.writeByte(12),
        writer.write(obj.outputs),
        writer.writeByte(13),
        writer.write(obj.address),
        writer.writeByte(14),
        writer.write(obj.height),
        writer.writeByte(15),
        writer.write(obj.subType),
        writer.writeByte(16),
        writer.write(obj.confirmations),
        writer.writeByte(17),
        writer.write(obj.isCancelled),
        writer.writeByte(18),
        writer.write(obj.slateId),
        writer.writeByte(19),
        writer.write(obj.otherData),
      ]);
    });

    test("TransactionAdapter.hashcode", () {
      final adapter = TransactionAdapter();

      final result = adapter.hashCode;
      expect(result, 3);
    });

    group("TransactionAdapter compare operator", () {
      test("TransactionAdapter is equal one", () {
        final a = TransactionAdapter();
        final b = TransactionAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("TransactionAdapter is equal two", () {
        final a = TransactionAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("TransactionAdapteris not equal one", () {
        final a = TransactionAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("TransactionAdapter is not equal two", () {
        final a = TransactionAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("InputAdapter", () {
    test("InputAdapter.read", () {
      final adapter = InputAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [9];
      for (int i = 0; i < 9; i++) {
        readByteResponses.add(i);
      }

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));

      List<dynamic> readResponses = [
        "some txid",
        1,
        Output(scriptpubkeyAddress: "adr", value: 1),
        "some script sig",
        "some script sig asm",
        <dynamic>[],
        true,
        1,
        "some script",
      ];

      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(9);
      verify(reader.readByte()).called(10);
      expect(result, isA<Input>());
    });

    test("InputAdapter.write", () {
      final adapter = InputAdapter();
      final obj = Input(txid: "abc", vout: 1);
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 9; i++) {
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
      when(writer.write(obj.prevout)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptsig)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptsigAsm)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.witness)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.isCoinbase)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.sequence)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.innerRedeemscriptAsm)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(9),
        writer.writeByte(0),
        writer.write(obj.txid),
        writer.writeByte(1),
        writer.write(obj.vout),
        writer.writeByte(2),
        writer.write(obj.prevout),
        writer.writeByte(3),
        writer.write(obj.scriptsig),
        writer.writeByte(4),
        writer.write(obj.scriptsigAsm),
        writer.writeByte(5),
        writer.write(obj.witness),
        writer.writeByte(6),
        writer.write(obj.isCoinbase),
        writer.writeByte(7),
        writer.write(obj.sequence),
        writer.writeByte(8),
        writer.write(obj.innerRedeemscriptAsm),
      ]);
    });

    test("InputAdapter.hashcode", () {
      final adapter = InputAdapter();

      final result = adapter.hashCode;
      expect(result, 4);
    });

    group("InputAdapter compare operator", () {
      test("InputAdapter is equal one", () {
        final a = InputAdapter();
        final b = InputAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("InputAdapter is equal two", () {
        final a = InputAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("InputAdapter is not equal one", () {
        final a = InputAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("InputAdapter is not equal two", () {
        final a = InputAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });

  group("OutputAdapter", () {
    test("OutputAdapter.read", () {
      final adapter = OutputAdapter();
      final reader = MockBinaryReader();

      List<int> readByteResponses = [5];
      for (int i = 0; i < 5; i++) {
        readByteResponses.add(i);
      }

      when(reader.readByte()).thenAnswer((_) => readByteResponses.removeAt(0));

      List<dynamic> readResponses = [
        "some scriptpubkey",
        "some scriptpubkey asm",
        "some scriptpubkey type",
        "some scriptpubkey address",
        10000,
      ];

      when(reader.read()).thenAnswer((_) => readResponses.removeAt(0));

      final result = adapter.read(reader);

      verify(reader.read()).called(5);
      verify(reader.readByte()).called(6);
      expect(result, isA<Output>());
    });

    test("OutputAdapter.write", () {
      final adapter = OutputAdapter();
      final obj = Output(scriptpubkeyAddress: "adr", value: 1);
      final writer = MockBinaryWriter();

      for (int i = 0; i <= 5; i++) {
        when(writer.writeByte(i)).thenAnswer((_) {
          return;
        });
      }

      when(writer.write(obj.scriptpubkey)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyAsm)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyType)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.scriptpubkeyAddress)).thenAnswer((_) {
        return;
      });
      when(writer.write(obj.value)).thenAnswer((_) {
        return;
      });

      adapter.write(writer, obj);

      verifyInOrder([
        writer.writeByte(5),
        writer.writeByte(0),
        writer.write(obj.scriptpubkey),
        writer.writeByte(1),
        writer.write(obj.scriptpubkeyAsm),
        writer.writeByte(2),
        writer.write(obj.scriptpubkeyType),
        writer.writeByte(3),
        writer.write(obj.scriptpubkeyAddress),
        writer.writeByte(4),
        writer.write(obj.value),
      ]);
    });

    test("OutputAdapter.hashcode", () {
      final adapter = OutputAdapter();

      final result = adapter.hashCode;
      expect(result, 5);
    });

    group("OutputAdapter compare operator", () {
      test("OutputAdapter is equal one", () {
        final a = OutputAdapter();
        final b = OutputAdapter();

        final result = a == b;
        expect(result, true);
      });

      test("OutputAdapter is equal two", () {
        final a = OutputAdapter();
        final b = a;

        final result = a == b;
        expect(result, true);
      });

      test("OutputAdapter is not equal one", () {
        final a = OutputAdapter();
        final b = TransactionDataAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == b;
        expect(result, false);
      });

      test("OutputAdapter is not equal two", () {
        final a = OutputAdapter();

        // ignore: unrelated_type_equality_checks
        final result = a == 8;
        expect(result, false);
      });
    });
  });
}

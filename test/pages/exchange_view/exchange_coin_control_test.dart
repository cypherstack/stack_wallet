import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_coin_control.dart';
import 'package:stackwallet/utilities/amount/amount.dart';

void main() {
  const walletId = "wallet-1";

  UTXO utxo({
    String id = "tx-1",
    String wallet = walletId,
    int value = 1500,
    bool blocked = false,
    bool? used,
    String name = "",
  }) => UTXO(
    walletId: wallet,
    txid: id,
    vout: 0,
    value: value,
    name: name,
    isBlocked: blocked,
    blockedReason: null,
    isCoinbase: false,
    blockHash: "block",
    blockHeight: 1,
    blockTime: 1,
    used: used,
  );

  Amount amount(int raw) =>
      Amount(rawValue: BigInt.from(raw), fractionDigits: 8);

  group("visibility", () {
    test("requires preference and coin-control wallet", () {
      expect(
        shouldShowExchangeCoinControl(
          preferenceEnabled: true,
          walletSupportsCoinControl: true,
          isFiro: false,
        ),
        isTrue,
      );
      expect(
        shouldShowExchangeCoinControl(
          preferenceEnabled: false,
          walletSupportsCoinControl: true,
          isFiro: false,
        ),
        isFalse,
      );
      expect(
        shouldShowExchangeCoinControl(
          preferenceEnabled: true,
          walletSupportsCoinControl: false,
          isFiro: false,
        ),
        isFalse,
      );
    });

    test("excludes Firo exchange sends", () {
      expect(
        shouldShowExchangeCoinControl(
          preferenceEnabled: true,
          walletSupportsCoinControl: true,
          isFiro: true,
        ),
        isFalse,
      );
    });
  });

  test("funding total includes the estimated network fee", () async {
    final total = await estimateExchangeFundingTotal(
      amount: amount(1000),
      estimateFee: (requested) async {
        expect(requested.raw, BigInt.from(1000));
        return amount(250);
      },
    );

    expect(total.raw, BigInt.from(1250));
  });

  group("selection validation", () {
    test("uses fresh database outputs", () {
      final prior = utxo(name: "old");
      final current = utxo(name: "current");

      final result = validateExchangeCoinSelection(
        walletId: walletId,
        selected: {prior},
        requiredTotal: amount(1200),
        lookup: (_) => current,
        isConfirmed: (_) => true,
      );

      expect(result, hasLength(1));
      expect(result!.single.utxo.name, "current");
    });

    test("accepts an empty optional selection", () {
      final result = validateExchangeCoinSelection(
        walletId: walletId,
        selected: const {},
        requiredTotal: amount(1200),
        lookup: (_) => fail("lookup should not run"),
        isConfirmed: (_) => fail("confirmation should not run"),
      );

      expect(result, isNull);
    });

    for (final invalidCase in <String, UTXO? Function()>{
      "missing": () => null,
      "wrong wallet": () => utxo(wallet: "wallet-2"),
      "blocked": () => utxo(blocked: true),
      "spent": () => utxo(used: true),
    }.entries) {
      test("rejects ${invalidCase.key} outputs", () {
        final prior = utxo();

        expect(
          () => validateExchangeCoinSelection(
            walletId: walletId,
            selected: {prior},
            requiredTotal: amount(1200),
            lookup: (_) => invalidCase.value(),
            isConfirmed: (_) => true,
          ),
          throwsA(
            isA<ExchangeCoinSelectionException>().having(
              (error) => error.clearSelection,
              "clearSelection",
              true,
            ),
          ),
        );
      });
    }

    test("rejects an unconfirmed output", () {
      final prior = utxo();

      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {prior},
          requiredTotal: amount(1200),
          lookup: (_) => prior,
          isConfirmed: (_) => false,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>().having(
            (error) => error.clearSelection,
            "clearSelection",
            true,
          ),
        ),
      );
    });

    test("rejects a total that omits the fee without clearing", () {
      final prior = utxo(value: 1000);

      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {prior},
          requiredTotal: amount(1200),
          lookup: (_) => prior,
          isConfirmed: (_) => true,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>()
              .having((error) => error.clearSelection, "clearSelection", false)
              .having(
                (error) => error.message,
                "message",
                contains("network fee"),
              ),
        ),
      );
    });

    test("allows an underfunded selection while adding more outputs", () {
      final prior = utxo(value: 1000);

      final result = validateExchangeCoinSelection(
        walletId: walletId,
        selected: {prior},
        requiredTotal: amount(1200),
        lookup: (_) => prior,
        isConfirmed: (_) => true,
        requireSufficientValue: false,
      );

      expect(result, hasLength(1));
    });

    test("still rejects stale outputs when sufficiency is not required", () {
      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {utxo()},
          requiredTotal: amount(1200),
          lookup: (_) => null,
          isConfirmed: (_) => true,
          requireSufficientValue: false,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>().having(
            (error) => error.clearSelection,
            "clearSelection",
            true,
          ),
        ),
      );
    });

    test("rejects a prior from another wallet without consulting the "
        "database", () {
      // The lookup is keyed on (txid, walletId, vout), so a stale prior from
      // another wallet would silently resolve to this wallet's output at the
      // same outpoint if it were not rejected before the query.
      var lookups = 0;

      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {utxo(wallet: "wallet-2")},
          requiredTotal: amount(1200),
          lookup: (_) {
            lookups++;
            return utxo();
          },
          isConfirmed: (_) => true,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>().having(
            (error) => error.clearSelection,
            "clearSelection",
            true,
          ),
        ),
      );
      expect(lookups, 0);
    });

    test("validates every selected output, not only the first", () {
      final fresh = utxo(id: "tx-fresh", value: 5000);
      final stale = utxo(id: "tx-stale", value: 5000);

      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {fresh, stale},
          requiredTotal: amount(1200),
          lookup: (prior) => prior.txid == "tx-stale" ? null : prior,
          isConfirmed: (_) => true,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>().having(
            (error) => error.clearSelection,
            "clearSelection",
            true,
          ),
        ),
      );
    });

    test("accepts a selection worth exactly the required total", () {
      final prior = utxo(value: 1200);

      final result = validateExchangeCoinSelection(
        walletId: walletId,
        selected: {prior},
        requiredTotal: amount(1200),
        lookup: (_) => prior,
        isConfirmed: (_) => true,
      );

      expect(result, hasLength(1));
    });

    test("rejects a selection one atomic unit short", () {
      final prior = utxo(value: 1199);

      expect(
        () => validateExchangeCoinSelection(
          walletId: walletId,
          selected: {prior},
          requiredTotal: amount(1200),
          lookup: (_) => prior,
          isConfirmed: (_) => true,
        ),
        throwsA(
          isA<ExchangeCoinSelectionException>().having(
            (error) => error.clearSelection,
            "clearSelection",
            false,
          ),
        ),
      );
    });
  });
}

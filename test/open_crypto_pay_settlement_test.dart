import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/open_crypto_pay/models.dart';
import 'package:stackwallet/services/open_crypto_pay/settlement.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);
  final cardano = Cardano(CryptoCurrencyNetwork.main);
  final ethereum = Ethereum(CryptoCurrencyNetwork.main);
  final firo = Firo(CryptoCurrencyNetwork.main);

  group("shouldCommitTxIdFor", () {
    test("always uses txid for txid submission flows", () {
      expect(
        OpenCryptoPaySettlement.shouldCommitTxIdFor(
          method: "Cardano",
          submissionFlow: OpenCryptoPaySubmissionFlow.txIdAfterLocalBroadcast,
          cryptoCurrency: cardano,
          hasSparkInputs: false,
          rawHexLength: 0,
        ),
        true,
      );
    });

    test("falls back for Firo Spark spends", () {
      expect(
        OpenCryptoPaySettlement.shouldCommitTxIdFor(
          method: "Firo",
          submissionFlow: OpenCryptoPaySubmissionFlow.rawHexToProvider,
          cryptoCurrency: firo,
          hasSparkInputs: true,
          rawHexLength: 100,
        ),
        true,
      );
    });

    test("falls back only above the Firo raw hex query limit", () {
      expect(
        OpenCryptoPaySettlement.shouldCommitTxIdFor(
          method: "Firo",
          submissionFlow: OpenCryptoPaySubmissionFlow.rawHexToProvider,
          cryptoCurrency: firo,
          hasSparkInputs: false,
          rawHexLength: OpenCryptoPaySettlement.maxRawHexQueryLength,
        ),
        false,
      );
      expect(
        OpenCryptoPaySettlement.shouldCommitTxIdFor(
          method: "Firo",
          submissionFlow: OpenCryptoPaySubmissionFlow.rawHexToProvider,
          cryptoCurrency: firo,
          hasSparkInputs: false,
          rawHexLength: OpenCryptoPaySettlement.maxRawHexQueryLength + 1,
        ),
        true,
      );
    });

    test("does not use the Firo fallback for other coins", () {
      expect(
        OpenCryptoPaySettlement.shouldCommitTxIdFor(
          method: "Bitcoin",
          submissionFlow: OpenCryptoPaySubmissionFlow.rawHexToProvider,
          cryptoCurrency: bitcoin,
          hasSparkInputs: false,
          rawHexLength: OpenCryptoPaySettlement.maxRawHexQueryLength + 1,
        ),
        false,
      );
    });
  });

  group("validateMinFee", () {
    test("ceil-checks Ethereum wei gas price", () {
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: ethereum,
          minFee: Decimal.parse("10.1"),
          gasPrice: BigInt.from(10),
        ),
        "Open CryptoPay requires at least 10.1 wei gas price",
      );
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: ethereum,
          minFee: Decimal.parse("10.1"),
          gasPrice: BigInt.from(11),
        ),
        isNull,
      );
    });

    test("requires Ethereum gas price when minFee is set", () {
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: ethereum,
          minFee: Decimal.fromInt(1),
        ),
        "Could not verify Open CryptoPay minimum gas price",
      );
    });

    test("ceil-checks Bitcoin sat/vB against total fee", () {
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: bitcoin,
          minFee: Decimal.parse("2.5"),
          fee: _rawAmount(7),
          vSize: 3,
        ),
        "Open CryptoPay requires at least 2.5 sat/vB fee",
      );
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: bitcoin,
          minFee: Decimal.parse("2.5"),
          fee: _rawAmount(8),
          vSize: 3,
        ),
        isNull,
      );
    });

    test("requires fee and vSize for sat/vB methods", () {
      expect(
        OpenCryptoPaySettlement.validateMinFee(
          cryptoCurrency: firo,
          minFee: Decimal.fromInt(1),
        ),
        "Could not verify Open CryptoPay minimum fee",
      );
    });
  });

  group("validateTransaction", () {
    test("requires exactly one recipient", () {
      expect(
        OpenCryptoPaySettlement.validateTransaction(
          cryptoCurrency: bitcoin,
          recipients: <({String address, Amount amount})>[],
          recipientAddress: "bc1qrecipient",
          amount: Decimal.fromInt(1),
        ),
        "Open CryptoPay requires exactly one recipient",
      );
      expect(
        OpenCryptoPaySettlement.validateTransaction(
          cryptoCurrency: bitcoin,
          recipients: [
            (address: "bc1qone", amount: _amount("1")),
            (address: "bc1qtwo", amount: _amount("1")),
          ],
          recipientAddress: "bc1qrecipient",
          amount: Decimal.fromInt(1),
        ),
        "Open CryptoPay requires exactly one recipient",
      );
    });

    test("rejects recipient mismatch", () {
      expect(
        OpenCryptoPaySettlement.validateTransaction(
          cryptoCurrency: bitcoin,
          recipients: [(address: "bc1qactual", amount: _amount("1"))],
          recipientAddress: "bc1qexpected",
          amount: Decimal.fromInt(1),
        ),
        "Open CryptoPay recipient changed. Please scan again.",
      );
    });

    test("rejects amount mismatch", () {
      expect(
        OpenCryptoPaySettlement.validateTransaction(
          cryptoCurrency: bitcoin,
          recipients: [(address: "bc1qrecipient", amount: _amount("1.01"))],
          recipientAddress: "bc1qrecipient",
          amount: Decimal.fromInt(1),
        ),
        "Open CryptoPay amount changed. Please scan again.",
      );
    });

    test("normalizes Ethereum recipient case", () {
      expect(
        OpenCryptoPaySettlement.validateTransaction(
          cryptoCurrency: ethereum,
          recipients: [
            (
              address: "0x9C2242A0B71FD84661FD4BC56B75C90FAC6D10FC",
              amount: _amount("1", fractionDigits: 18),
            ),
          ],
          recipientAddress: "0x9c2242a0b71fd84661fd4bc56b75c90fac6d10fc",
          amount: Decimal.fromInt(1),
        ),
        isNull,
      );
    });
  });

  group("validateToken", () {
    OpenCryptoPayCommit commit({
      String asset = "USDT",
      String contract = "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      int? tokenDecimals = 6,
    }) {
      return OpenCryptoPayCommit(
        callbackUrl: "https://merchant.example/cb/payment-1",
        quoteId: "quote-1",
        paymentId: "payment-1",
        method: "Ethereum",
        asset: asset,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        submissionFlow: OpenCryptoPaySubmissionFlow.rawHexToProvider,
        minFee: Decimal.zero,
        recipientAddress: "0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC",
        amount: Decimal.fromInt(1),
        tokenContractAddress: contract,
        tokenDecimals: tokenDecimals,
      );
    }

    test("accepts matching enabled token metadata", () {
      expect(
        OpenCryptoPaySettlement.validateToken(
          commit: commit(),
          isTokenTx: true,
          tokenContractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
          tokenSymbol: "USDT",
          tokenDecimals: 6,
        ),
        isNull,
      );
    });

    test("rejects token decimals mismatch", () {
      expect(
        OpenCryptoPaySettlement.validateToken(
          commit: commit(tokenDecimals: 6),
          isTokenTx: true,
          tokenContractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
          tokenSymbol: "USDT",
          tokenDecimals: 18,
        ),
        "Open CryptoPay token decimals changed. Please scan again.",
      );
    });
  });
}

Amount _amount(String value, {int fractionDigits = 8}) {
  return Amount.fromDecimal(
    Decimal.parse(value),
    fractionDigits: fractionDigits,
  );
}

Amount _rawAmount(int value, {int fractionDigits = 8}) {
  return Amount(rawValue: BigInt.from(value), fractionDigits: fractionDigits);
}

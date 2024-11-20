import 'dart:convert';
import 'dart:io';

import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/cardano/mnemonic/cardano_icarus_seed_generator.dart';
import 'package:blockchain_utils/bip/cardano/shelley/cardano_shelley.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:socks5_proxy/socks.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import 'package:tuple/tuple.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart' as isar;
import '../../../models/paymint/fee_object_model.dart';
import '../../../networking/http.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import 'package:isar/isar.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../api/cardano/blockfrost_http_provider.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';

class CardanoWallet extends Bip39Wallet<Cardano> {
  CardanoWallet(CryptoCurrencyNetwork network) : super(Cardano(network));

  // Source: https://cips.cardano.org/cip/CIP-1852
  static const String _addressDerivationPath = "m/1852'/1815'/0'/0/0";
  static final HTTP _httpClient = HTTP();

  BlockforestProvider? blockfrostProvider;

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation? get receivingAddressFilterOperation => null;

  Future<Address> _getAddress() async {
    final mnemonic = await getMnemonic();
    final seed = CardanoIcarusSeedGenerator(mnemonic).generate();
    final cip1852 = Cip1852.fromSeed(seed, Cip1852Coins.cardanoIcarus);
    final derivationAccount = cip1852.purpose.coin.account(0);
    final shelley = CardanoShelley.fromCip1852Object(derivationAccount)
        .change(Bip44Changes.chainExt)
        .addressIndex(0);
    final paymentPublicKey = shelley.bip44.publicKey.compressed;
    final stakePublicKey = shelley.bip44Sk.publicKey.compressed;
    final addressStr = ADABaseAddress.fromPublicKey(
      basePubkeyBytes: paymentPublicKey,
      stakePubkeyBytes: stakePublicKey,
    ).address;
    return Address(
      walletId: walletId,
      value: addressStr,
      publicKey: paymentPublicKey,
      derivationIndex: 0,
      derivationPath: DerivationPath()..value = _addressDerivationPath,
      type: AddressType.cardanoShelley,
      subType: AddressSubType.receiving,
    );
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    try {
      final Address? address = await getCurrentReceivingAddress();

      if (address == null) {
        final address = await _getAddress();

        await mainDB.updateOrPutAddresses([address]);
      }
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType  checkSaveInitialReceivingAddress() failed: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> pingCheck() async {
    try {
      await updateProvider();

      final health = await blockfrostProvider!.request(
        BlockfrostRequestBackendHealthStatus(),
      );

      return Future.value(health);
    } catch (e, s) {
      Logging.instance.log(
        "Error ping checking in cardano_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
      return Future.value(false);
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    await updateProvider();

    if (info.cachedBalance.spendable.raw == BigInt.zero) {
      return Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    final params = await blockfrostProvider!.request(
      BlockfrostRequestLatestEpochProtocolParameters(),
    );

    final fee = params.calculateFee(284);

    return Amount(
      rawValue: fee,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees async {
    try {
      await updateProvider();

      final params = await blockfrostProvider!.request(
        BlockfrostRequestLatestEpochProtocolParameters(),
      );

      // 284 is the size of a basic transaction with one input and two outputs (change and recipient)
      final fee = params.calculateFee(284).toInt();

      return FeeObject(
          numberOfBlocksFast: 2,
          numberOfBlocksAverage: 2,
          numberOfBlocksSlow: 2,
          fast: fee,
          medium: fee,
          slow: fee,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Error getting fees in cardano_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      await updateProvider();

      if (txData.amount!.raw < ADAHelper.toLovelaces("1")) {
        throw Exception("By network rules, you can send minimum 1 ADA");
      }

      final utxos = await blockfrostProvider!.request(
        BlockfrostRequestAddressUTXOsOfAGivenAsset(
          address: ADAAddress.fromAddress(
            (await getCurrentReceivingAddress())!.value,
          ),
          asset: "lovelace",
        ),
      );

      var leftAmountForUtxos = txData.amount!.raw;
      final listOfUtxosToBeUsed = <ADAAccountUTXOResponse>[];
      var totalBalance = BigInt.zero;

      for (final utxo in utxos) {
        if (!(leftAmountForUtxos <= BigInt.parse("0"))) {
          leftAmountForUtxos -= BigInt.parse(utxo.amount.first.quantity);
          listOfUtxosToBeUsed.add(utxo);
        }
        totalBalance += BigInt.parse(utxo.amount.first.quantity);
      }

      if (leftAmountForUtxos > BigInt.parse("0") || totalBalance < txData.amount!.raw) {
        throw Exception("Insufficient balance");
      }

      final bip32 = CardanoIcarusBip32.fromSeed(CardanoIcarusSeedGenerator(await getMnemonic()).generate());
      final spend = bip32.derivePath("1852'/1815'/0'/0/0");
      final privateKey = AdaPrivateKey.fromBytes(spend.privateKey.raw);

      // Calculate fees with example tx
      final exampleFee = ADAHelper.toLovelaces("0.10");
      final change = TransactionOutput(address: ADABaseAddress((await getCurrentReceivingAddress())!.value), amount: Value(coin: totalBalance - (txData.amount!.raw)));
      final body = TransactionBody(
        inputs: listOfUtxosToBeUsed.map((e) => TransactionInput(transactionId: TransactionHash.fromHex(e.txHash), index: e.outputIndex)).toList(),
        outputs: [change, TransactionOutput(address: ADABaseAddress(txData.recipients!.first.address), amount: Value(coin: txData.amount!.raw - exampleFee))],
        fee: exampleFee,
      );
      final exampleTx = ADATransaction(
          body: body,
          witnessSet: TransactionWitnessSet(vKeys: [
            privateKey.createSignatureWitness(body.toHash().data),
          ],)
        ,);
      final params = await blockfrostProvider!.request(BlockfrostRequestLatestEpochProtocolParameters());
      final fee = params.calculateFee(exampleTx.size);

      // Check if we are sending all balance, which means no change and only one output for recipient.
      if (totalBalance == txData.amount!.raw) {
        final List<TxRecipient> newRecipients = [(
        address: txData.recipients!.first.address,
        amount: Amount(
          rawValue: txData.amount!.raw - fee,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        isChange: txData.recipients!.first.isChange,
        ),];
        return txData.copyWith(
          fee: Amount(
            rawValue: fee,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          recipients: newRecipients,
        );
      } else {
        if (txData.amount!.raw + fee > totalBalance) {
          throw Exception("Insufficient balance for fee");
        }

        // Minimum change in Cardano is 1 ADA and we need to have enough balance for that
        if (totalBalance - (txData.amount!.raw + fee) < ADAHelper.toLovelaces("1")) {
          throw Exception("Not enough balance for change. By network rules, please either send all balance or leave at least 1 ADA change.");
        }

        return txData.copyWith(
          fee: Amount(
            rawValue: fee,
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Cardano prepareSend failed: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      await updateProvider();

      final utxos = await blockfrostProvider!.request(
        BlockfrostRequestAddressUTXOsOfAGivenAsset(
          address: ADAAddress.fromAddress(
            (await getCurrentReceivingAddress())!.value,
          ),
          asset: "lovelace",
        ),
      );


      var leftAmountForUtxos = txData.amount!.raw + txData.fee!.raw;
      final listOfUtxosToBeUsed = <ADAAccountUTXOResponse>[];
      var totalBalance = BigInt.zero;

      for (final utxo in utxos) {
        if (!(leftAmountForUtxos <= BigInt.parse("0"))) {
          leftAmountForUtxos -= BigInt.parse(utxo.amount.first.quantity);
          listOfUtxosToBeUsed.add(utxo);
        }
        totalBalance += BigInt.parse(utxo.amount.first.quantity);
      }

      var totalUtxoAmount = BigInt.zero;

      for (final utxo in listOfUtxosToBeUsed) {
        totalUtxoAmount += BigInt.parse(utxo.amount.first.quantity);
      }

      final bip32 = CardanoIcarusBip32.fromSeed(CardanoIcarusSeedGenerator(await getMnemonic()).generate());
      final spend = bip32.derivePath("1852'/1815'/0'/0/0");
      final privateKey = AdaPrivateKey.fromBytes(spend.privateKey.raw);

      final change = TransactionOutput(address: ADABaseAddress((await getCurrentReceivingAddress())!.value), amount: Value(coin: totalUtxoAmount - (txData.amount!.raw + txData.fee!.raw)));
      List<TransactionOutput> outputs = [];
      if (totalBalance == (txData.amount!.raw + txData.fee!.raw)) {
        outputs = [TransactionOutput(address: ADABaseAddress(txData.recipients!.first.address), amount: Value(coin: txData.amount!.raw))];
      } else {
        outputs = [change, TransactionOutput(address: ADABaseAddress(txData.recipients!.first.address), amount: Value(coin: txData.amount!.raw))];
      }
      final body = TransactionBody(
        inputs: listOfUtxosToBeUsed.map((e) => TransactionInput(transactionId: TransactionHash.fromHex(e.txHash), index: e.outputIndex)).toList(),
        outputs: outputs,
        fee: txData.fee!.raw,
      );
      final tx = ADATransaction(
          body: body,
          witnessSet: TransactionWitnessSet(vKeys: [
            privateKey.createSignatureWitness(body.toHash().data),
          ],)
        ,);

      final sentTx = await blockfrostProvider!.request(BlockfrostRequestSubmitTransaction(
          transactionCborBytes: tx.serialize(),),);
      return txData.copyWith(
        txid: sentTx,
      );
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType Cardano confirmSend failed: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshMutex.protect(() async {
      final addressStruct = await _getAddress();

      await mainDB.updateOrPutAddresses([addressStruct]);

      if (info.cachedReceivingAddress != addressStruct.value) {
        await info.updateReceivingAddress(
          newAddress: addressStruct.value,
          isar: mainDB.isar,
        );
      }

      await Future.wait([
        updateBalance(),
        updateChainHeight(),
        updateTransactions(),
      ]);
    });
  }

  @override
  Future<void> updateBalance() async {
    try {
      await updateProvider();

      final addressUtxos = await blockfrostProvider!.request(
        BlockfrostRequestAddressUTXOsOfAGivenAsset(
          address: ADAAddress.fromAddress(
            (await getCurrentReceivingAddress())!.value,
          ),
          asset: "lovelace",
        ),
      );

      BigInt totalBalanceInLovelace = BigInt.parse("0");
      for (final utxo in addressUtxos) {
        totalBalanceInLovelace += BigInt.parse(utxo.amount.first.quantity);
      }

      final balance = Balance(
        total: Amount(
            rawValue: totalBalanceInLovelace,
            fractionDigits: cryptoCurrency.fractionDigits,),
        spendable: Amount(
            rawValue: totalBalanceInLovelace,
            fractionDigits: cryptoCurrency.fractionDigits,),
        blockedTotal: Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );

      await info.updateBalance(newBalance: balance, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.log(
        "Error getting balance in cardano_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      await updateProvider();

      final latestBlock = await blockfrostProvider!.request(
        BlockfrostRequestLatestBlock(),
      );

      await info.updateCachedChainHeight(
          newHeight: latestBlock.height == null ? 0 : latestBlock.height!,
          isar: mainDB.isar,);
    } catch (e, s) {
      Logging.instance.log(
        "Error updating transactions in cardano_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    await refresh();
  }

  @override
  Future<void> updateTransactions() async {
    try {
      await updateProvider();

      final currentAddr = (await getCurrentReceivingAddress())!.value;

      final txsList = await blockfrostProvider!.request(
        BlockfrostRequestAddressTransactions(
          ADAAddress.fromAddress(
            currentAddr,
          ),
        ),
      );

      final parsedTxsList =
          List<Tuple2<isar.Transaction, Address>>.empty(growable: true);

      for (final tx in txsList) {
        final txInfo = await blockfrostProvider!.request(
          BlockfrostRequestSpecificTransaction(tx.txHash),
        );
        final utxoInfo = await blockfrostProvider!.request(
          BlockfrostRequestTransactionUTXOs(tx.txHash),
        );
        var txType = isar.TransactionType.unknown;

        for (final input in utxoInfo.inputs) {
          if (input.address == currentAddr) {
            txType = isar.TransactionType.outgoing;
          }
        }

        if (txType == isar.TransactionType.outgoing) {
          var isSelfTx = true;
          for (final output in utxoInfo.outputs) {
            if (output.address != currentAddr) {
              isSelfTx = false;
            }
          }
          if (isSelfTx) {
            txType = isar.TransactionType.sentToSelf;
          }
        }

        if (txType == isar.TransactionType.unknown) {
          for (final output in utxoInfo.outputs) {
            if (output.address == currentAddr) {
              txType = isar.TransactionType.incoming;
            }
          }
        }

        var receiverAddr = "Unknown?";
        var amount = 0;

        if (txType == isar.TransactionType.incoming) {
          receiverAddr = currentAddr;
          for (final output in utxoInfo.outputs) {
            if (output.address == currentAddr && output.amount.first.unit == "lovelace") {
              amount += int.parse(output.amount.first.quantity);
            }
          }
        } else if (txType == isar.TransactionType.outgoing) {
          for (final output in utxoInfo.outputs) {
            if (output.address != currentAddr && output.amount.first.unit == "lovelace") {
              receiverAddr = output.address;
              amount += int.parse(output.amount.first.quantity);
            }
          }
        } else if (txType == isar.TransactionType.sentToSelf) {
          receiverAddr = currentAddr;
          for (final output in utxoInfo.outputs) {
            if (output.amount.first.unit == "lovelace") {
              amount += int.parse(output.amount.first.quantity);
            }
          }
        }

        final transaction = isar.Transaction(
          walletId: walletId,
          txid: txInfo.hash,
          timestamp: tx.blockTime,
          type: txType,
          subType: isar.TransactionSubType.none,
          amount: amount,
          amountString: Amount(
            rawValue: BigInt.from(amount),
            fractionDigits: cryptoCurrency.fractionDigits,
          ).toJsonString(),
          fee: int.parse(txInfo.fees),
          height: txInfo.blockHeight,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: null,
          inputs: [],
          outputs: [],
          nonce: null,
          numberOfMessages: 0,
        );

        final txAddress = Address(
          walletId: walletId,
          value: receiverAddr,
          publicKey: List<int>.empty(),
          derivationIndex: 0,
          derivationPath: DerivationPath()..value = _addressDerivationPath,
          type: AddressType.cardanoShelley,
          subType: txType == isar.TransactionType.outgoing
              ? AddressSubType.unknown
              : AddressSubType.receiving,
        );

        parsedTxsList.add(Tuple2(transaction, txAddress));
      }

      await mainDB.addNewTransactionData(parsedTxsList, walletId);
    } catch (e, s) {
      Logging.instance.log(
        "Error updating transactions in cardano_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // TODO: implement updateUTXOs
    return false;
  }

  Future<void> updateProvider() async {
    final currentNode = getCurrentNode();
    final client = HttpClient();
    if (prefs.useTor) {
      final proxyInfo = TorService.sharedInstance.getProxyInfo();
      final proxySettings = ProxySettings(
        proxyInfo.host,
        proxyInfo.port,
      );
      SocksTCPClient.assignToHttpClient(client, [proxySettings]);
    }
    blockfrostProvider = BlockforestProvider(
      BlockfrostHttpProvider(
        url: "${currentNode.host}:${currentNode.port}/",
        client: client,
      ),
    );
  }
}

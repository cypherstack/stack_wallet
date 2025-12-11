/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart' hide Wallet;

import '../../../../db/isar/main_db.dart';
import '../../../../models/balance.dart';
import '../../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../models/paymint/fee_object_model.dart';
import '../../../../services/solana/solana_token_api.dart';
import '../../../../utilities/amount/amount.dart';
import '../../../../utilities/logger.dart';
import '../../../models/tx_data.dart';
import '../../wallet.dart';
import '../solana_wallet.dart';

class SolanaTokenWallet extends Wallet {
  @override
  int get isarTransactionVersion => 2;

  SolanaTokenWallet(this.parentSolanaWallet, this.solContract)
    : super(parentSolanaWallet.cryptoCurrency);

  final SolanaWallet parentSolanaWallet;

  final SolContract solContract;

  String get tokenMint => solContract.address;
  String get tokenName => solContract.name;
  String get tokenSymbol => solContract.symbol;
  int get tokenDecimals => solContract.decimals;

  @override
  String get walletId => parentSolanaWallet.walletId;

  @override
  MainDB get mainDB => parentSolanaWallet.mainDB;

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation? get receivingAddressFilterOperation => null;

  @override
  FilterOperation? get transactionFilterOperation =>
      FilterCondition.equalTo(property: r"contractAddress", value: tokenMint);

  @override
  Future<void> init() async {
    await super.init();

    parentSolanaWallet.checkClient();

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      if (txData.recipients == null || txData.recipients!.isEmpty) {
        throw ArgumentError("At least one recipient is required");
      }

      if (txData.recipients!.length != 1) {
        throw ArgumentError(
          "SOL token transfers support only 1 recipient per transaction",
        );
      }

      if (txData.amount == null || txData.amount!.raw <= BigInt.zero) {
        throw ArgumentError("Send amount must be greater than zero");
      }

      final recipientAddress = txData.recipients!.first.address;
      if (recipientAddress.isEmpty) {
        throw ArgumentError("Recipient address cannot be empty");
      }

      try {
        Ed25519HDPublicKey.fromBase58(recipientAddress);
      } catch (e) {
        throw ArgumentError("Invalid recipient address: $recipientAddress");
      }

      final rpcClient = parentSolanaWallet.getRpcClient();
      if (rpcClient == null) {
        throw Exception("RPC client not initialized");
      }

      final keyPair = await parentSolanaWallet.getKeyPair();
      final walletAddress = keyPair.address;

      final senderTokenAccount = await _findTokenAccount(
        ownerAddress: walletAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (senderTokenAccount == null) {
        throw Exception(
          "No token account found for mint $tokenMint. "
          "Please ensure you have received tokens first.",
        );
      }

      try {
        final accountInfo = await rpcClient.getAccountInfo(
          senderTokenAccount,
          encoding: Encoding.jsonParsed,
        );
        if (accountInfo.value == null) {
          throw Exception(
            "Sender token account $senderTokenAccount not found on-chain",
          );
        }
      } catch (e) {
        throw Exception("Failed to validate sender token account: $e");
      }

      await rpcClient.getLatestBlockhash();

      final recipientTokenAccount = await _findOrDeriveRecipientTokenAccount(
        recipientAddress: recipientAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (recipientTokenAccount == null || recipientTokenAccount.isEmpty) {
        throw Exception(
          "Cannot determine recipient token account for mint $tokenMint. "
          "Recipient may not have a token account for this mint. "
          "Please ensure the recipient has initialized an Associated Token Account (ATA) first.",
        );
      }

      try {
        final recipientAccountInfo = await rpcClient.getAccountInfo(
          recipientTokenAccount,
          encoding: Encoding.jsonParsed,
        );
        if (recipientAccountInfo.value == null) {
          throw Exception(
            "Recipient token account $recipientTokenAccount does not exist on-chain. "
            "The recipient must initialize their token account before receiving tokens. "
            "You can ask the recipient to accept the token in their wallet app first.",
          );
        }

        final accountData = recipientAccountInfo.value!;

        // Verify account is owned by token program (not System Program).
        if (accountData.owner == '11111111111111111111111111111111') {
          throw Exception(
            "Recipient token account $recipientTokenAccount is owned by the System Program, "
            "not a token program. The account may not be a valid token account.",
          );
        }
      } catch (e) {
        if (e.toString().contains("does not exist") ||
            e.toString().contains("not owned by")) {
          rethrow;
        }
        throw Exception(
          "Failed to validate recipient token account: $e. "
          "Ensure the recipient has initialized their token account.",
        );
      }

      final senderTokenAccountKey = Ed25519HDPublicKey.fromBase58(
        senderTokenAccount,
      );
      final recipientTokenAccountKey = Ed25519HDPublicKey.fromBase58(
        recipientTokenAccount,
      );
      final mintPubkey = Ed25519HDPublicKey.fromBase58(tokenMint);

      String tokenProgramId;
      try {
        final mintInfo = await rpcClient.getAccountInfo(
          tokenMint,
          encoding: Encoding.jsonParsed,
        );
        if (mintInfo.value != null) {
          tokenProgramId = mintInfo.value!.owner;
          Logging.instance.i(
            "$runtimeType prepareSend: Token program owner = $tokenProgramId for mint $tokenMint",
          );
        } else {
          // Fallback to SPL Token.
          tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
          Logging.instance.w(
            "$runtimeType prepareSend: Could not query mint owner, using SPL Token",
          );
        }
      } catch (e) {
        // Fallback to SPL Token on error.
        tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
        Logging.instance.w(
          "$runtimeType prepareSend: Error querying mint owner: $e, using SPL Token",
        );
      }

      final TokenProgramType tokenProgram =
          tokenProgramId != 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA'
              && tokenProgramId.startsWith('Token')
              ? TokenProgramType.token2022Program
              : TokenProgramType.tokenProgram;

      // ignore: unused_local_variable
      final instruction = TokenInstruction.transferChecked(
        source: senderTokenAccountKey,
        destination: recipientTokenAccountKey,
        mint: mintPubkey,
        owner: keyPair.publicKey,
        decimals: tokenDecimals,
        amount: txData.amount!.raw.toInt(),
        tokenProgram: tokenProgram,
      );

      final feeEstimate =
          await _getEstimatedTokenTransferFee(
            senderTokenAccountKey: senderTokenAccountKey,
            recipientTokenAccountKey: recipientTokenAccountKey,
            ownerPublicKey: keyPair.publicKey,
            amount: txData.amount!.raw.toInt(),
            rpcClient: rpcClient,
          ) ??
          5000;

      return txData.copyWith(
        fee: Amount(
          rawValue: BigInt.from(feeEstimate),
          fractionDigits: 9,
        ),
        solanaRecipientTokenAccount: recipientTokenAccount,
      );
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType prepareSend failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      // Validate that prepareSend was called.
      if (txData.fee == null) {
        throw Exception("Transaction not prepared. Call prepareSend() first.");
      }

      if (txData.recipients == null || txData.recipients!.isEmpty) {
        throw ArgumentError("Transaction must have at least one recipient");
      }

      // Get wallet state.
      final rpcClient = parentSolanaWallet.getRpcClient();
      if (rpcClient == null) {
        throw Exception("RPC client not initialized");
      }

      final keyPair = await parentSolanaWallet.getKeyPair();
      final walletAddress = keyPair.address;

      // Get sender's token account.
      final senderTokenAccount = await _findTokenAccount(
        ownerAddress: walletAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (senderTokenAccount == null) {
        throw Exception("Token account not found");
      }

      await rpcClient.getLatestBlockhash();

      // Reuse the recipient token account from prepareSend (already looked up once).
      final recipientTokenAccount = txData.solanaRecipientTokenAccount;

      if (recipientTokenAccount == null || recipientTokenAccount.isEmpty) {
        throw Exception(
          "Recipient token account not found in prepared transaction. "
          "Call prepareSend() first to determine the recipient's token account.",
        );
      }

      // Build SPL token tx instruction.
      final senderTokenAccountKey = Ed25519HDPublicKey.fromBase58(
        senderTokenAccount,
      );
      final recipientTokenAccountKey = Ed25519HDPublicKey.fromBase58(
        recipientTokenAccount,
      );
      final mintPubkey = Ed25519HDPublicKey.fromBase58(tokenMint);

      // Query the actual token program owner (important for Token-2022 variants).
      String tokenProgramId;
      try {
        final mintInfo = await rpcClient.getAccountInfo(
          tokenMint,
          encoding: Encoding.jsonParsed,
        );
        if (mintInfo.value != null) {
          tokenProgramId = mintInfo.value!.owner;
          Logging.instance.i(
            "$runtimeType confirmSend: Token program owner = $tokenProgramId for mint $tokenMint",
          );
        } else {
          // Fallback to SPL Token.
          tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
          Logging.instance.w(
            "$runtimeType confirmSend: Could not query mint owner, using SPL Token",
          );
        }
      } catch (e) {
        // Fallback to SPL Token on error.
        tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
        Logging.instance.w(
          "$runtimeType confirmSend: Error querying mint owner: $e, using SPL Token",
        );
      }

      // Build the TransferChecked instruction.
      final TokenProgramType tokenProgram =
          tokenProgramId != 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA'
              && tokenProgramId.startsWith('Token') // Token-2022 variant.
              ? TokenProgramType.token2022Program
              : TokenProgramType.tokenProgram;

      final instruction = TokenInstruction.transferChecked(
        source: senderTokenAccountKey,
        destination: recipientTokenAccountKey,
        mint: mintPubkey,
        owner: keyPair.publicKey,
        decimals: tokenDecimals,
        amount: txData.amount!.raw.toInt(),
        tokenProgram: tokenProgram,
      );

      // Create message.
      final message = Message(instructions: [instruction]);

      // Sign and broadcast tx.
      final txid = await rpcClient.signAndSendTransaction(message, [keyPair]);

      if (txid.isEmpty) {
        throw Exception(
          "Failed to broadcast transaction: empty signature returned",
        );
      }

      // Create temporary transaction (pending = unconfirmed) and save to db.
      try {
        // Build inputs and outputs for the transaction record.
        final inputs = [
          InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: null,
            scriptSigAsm: null,
            sequence: null,
            outpoint: null,
            addresses: [senderTokenAccount],
            valueStringSats: txData.amount!.raw.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: true,
          ),
        ];

        final outputs = [
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: "00",
            valueStringSats: txData.amount!.raw.toString(),
            addresses: [recipientTokenAccount],
            walletOwns: false, // We don't own recipient account.
          ),
        ];

        // Determine if this is a self-transfer.
        final isToSelf = senderTokenAccount == recipientTokenAccount;

        // Create the temporary transaction record.
        final tempTx = TransactionV2(
          walletId: walletId,
          blockHash: null, // CRITICAL: null indicates pending.
          hash: txid,
          txid: txid,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          height: null, // CRITICAL: null indicates pending.
          inputs: List.unmodifiable(inputs),
          outputs: List.unmodifiable(outputs),
          version: -1,
          type: isToSelf
              ? TransactionType.sentToSelf
              : TransactionType.outgoing,
          subType: TransactionSubType.splToken,
          otherData: jsonEncode({
            "mint": tokenMint,
            "senderTokenAccount": senderTokenAccount,
            "recipientTokenAccount": recipientTokenAccount,
            "isCancelled": false,
            "overrideFee": txData.fee!.toJsonString(),
          }),
        );

        // Persist immediately to database so UI shows transaction right away.
        await mainDB.updateOrPutTransactionV2s([tempTx]);
        Logging.instance.i(
          "$runtimeType confirmSend: Persisted pending transaction $txid to database",
        );
      } catch (e, s) {
        // Log persistence error but don't fail the send operation.
        Logging.instance.w(
          "$runtimeType confirmSend: Failed to persist pending transaction to database: ",
          error: e,
          stackTrace: s,
        );
      }

      // Wait for confirmation.
      final confirmed = await _waitForConfirmation(
        signature: txid,
        maxWaitSeconds: 60,
        rpcClient: rpcClient,
      );

      if (!confirmed) {
        Logging.instance.w(
          "$runtimeType confirmSend: Transaction not confirmed after 60 seconds, "
          "but signature was successfully broadcast: $txid",
        );
      }

      // Return signed TxData.
      return txData.copyWith(txid: txid);
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType confirmSend failed: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    // TODO.
  }

  @override
  Future<void> updateNode() async {
    // No-op for token wallet.
  }

  @override
  Future<void> updateTransactions() async {
    try {
      final rpcClient = parentSolanaWallet.getRpcClient();
      if (rpcClient == null) {
        Logging.instance.w(
          "$runtimeType updateTransactions: RPC client not initialized",
        );
        return;
      }

      final keyPair = await parentSolanaWallet.getKeyPair();
      final walletAddress = keyPair.address;

      // Find token account for this mint.
      final senderTokenAccount = await _findTokenAccount(
        ownerAddress: walletAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (senderTokenAccount == null) {
        return;
      }

      // Fetch recent transactions for this token account.
      final txListIterable = await rpcClient.getTransactionsList(
        Ed25519HDPublicKey.fromBase58(senderTokenAccount),
        encoding: Encoding.jsonParsed,
      );

      final txList = txListIterable.toList();

      if (txList.isEmpty) {
        return;
      }

      final txns = <TransactionV2>[];
      int skippedCount = 0;

      for (int i = 0; i < txList.length; i++) {
        final txDetails = txList[i];
        try {
          // Skip failed transactions or those without metadata.
          if (txDetails.meta == null) {
            skippedCount++;
            continue;
          }

          // Cast transaction to ParsedTransaction if available.
          if (txDetails.transaction is! ParsedTransaction) {
            skippedCount++;
            continue;
          }
          final parsedTx = txDetails.transaction as ParsedTransaction;

          // Get the txid for this transaction
          final txid = parsedTx.signatures.isNotEmpty
              ? parsedTx.signatures[0]
              : "unknown_txid_$i";

          // Check if this transaction already exists in the database.
          // If it does, preserve the overrideFee from the pending transaction.
          dynamic existingOverrideFee;
          try {
            final allTxsForWallet = await mainDB.isar.transactionV2s
                .where()
                .walletIdEqualTo(walletId)
                .findAll();
            for (final tx in allTxsForWallet) {
              if (tx.txid == txid) {
                final existingOtherData = tx.otherData;
                if (existingOtherData != null && existingOtherData.isNotEmpty) {
                  try {
                    final otherDataMap = jsonDecode(existingOtherData);
                    if (otherDataMap is Map &&
                        otherDataMap.containsKey('overrideFee')) {
                      existingOverrideFee = otherDataMap['overrideFee'];
                    }
                  } catch (e) {
                    // Ignore parsing errors.
                  }
                }
                break;
              }
            }
          } catch (e) {
            // Ignore database query errors.
          }

          // Build otherData, preserving overrideFee if it existed.
          final otherDataMap = <String, dynamic>{
            "mint": tokenMint,
            "senderTokenAccount": senderTokenAccount,
            "recipientTokenAccount": senderTokenAccount,
            "isCancelled": (txDetails.meta!.err != null),
          };
          if (existingOverrideFee != null) {
            otherDataMap["overrideFee"] = existingOverrideFee;
          }

          // Create placeholder TransactionV2 object.
          final txn = TransactionV2(
            walletId: walletId,
            blockHash: null,
            hash: txid,
            txid: txid,
            timestamp:
                txDetails.blockTime ??
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
            height: txDetails.slot,
            inputs: [
              InputV2.isarCantDoRequiredInDefaultConstructor(
                scriptSigHex: null,
                scriptSigAsm: null,
                sequence: null,
                outpoint: null,
                addresses: [senderTokenAccount],
                valueStringSats: "0",
                witness: null,
                innerRedeemScriptAsm: null,
                coinbase: null,
                walletOwns: true,
              ),
            ],
            outputs: [
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "00",
                valueStringSats: "0",
                addresses: [senderTokenAccount],
                walletOwns: false,
              ),
            ],
            version: -1,
            type: TransactionType.outgoing,
            subType: TransactionSubType.splToken,
            otherData: jsonEncode(otherDataMap),
          );

          txns.add(txn);
        } catch (e, s) {
          Logging.instance.w(
            "$runtimeType updateTransactions: Failed to parse transaction at index $i",
            error: e,
            stackTrace: s,
          );
          skippedCount++;
          continue;
        }
      }

      // Persist all transactions if any were parsed.
      if (txns.isNotEmpty) {
        await mainDB.updateOrPutTransactionV2s(txns);
        Logging.instance.i(
          "$runtimeType updateTransactions: Synced ${txns.length} transactions (skipped $skippedCount)",
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateTransactions FAILED: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final rpcClient = parentSolanaWallet.getRpcClient();
      if (rpcClient == null) {
        return;
      }

      final keyPair = await parentSolanaWallet.getKeyPair();
      final walletAddress = keyPair.address;

      final senderTokenAccount = await _findTokenAccount(
        ownerAddress: walletAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (senderTokenAccount == null) {
        return;
      }

      final tokenApi = SolanaTokenAPI();
      tokenApi.initializeRpcClient(rpcClient);

      final balanceResponse = await tokenApi.getTokenAccountBalance(
        senderTokenAccount,
      );

      if (balanceResponse.isError) {
        Logging.instance.w(
          "$runtimeType updateBalance failed: ${balanceResponse.exception}",
        );
        return;
      }

      if (balanceResponse.value != null) {
        final info = await mainDB.isar.walletSolanaTokenInfo
            .where()
            .walletIdTokenAddressEqualTo(walletId, tokenMint)
            .findFirst();

        if (info != null) {
          final balanceAmount = Amount(
            rawValue: balanceResponse.value!,
            fractionDigits: tokenDecimals,
          );

          final balance = Balance(
            total: balanceAmount,
            spendable: balanceAmount,
            blockedTotal: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenDecimals,
            ),
            pendingSpendable: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenDecimals,
            ),
          );

          await info.updateCachedBalance(balance, isar: mainDB.isar);
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType updateBalance error: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // Not applicable for Solana tokens.
    return true;
  }

  @override
  Future<void> updateChainHeight() async {
    await parentSolanaWallet.updateChainHeight();
  }

  @override
  Future<void> refresh() async {
    await parentSolanaWallet.refresh();
    await updateBalance();
    await updateTransactions();
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    return parentSolanaWallet.estimateFeeFor(amount, feeRate);
  }

  @override
  Future<FeeObject> get fees async {
    return parentSolanaWallet.fees;
  }

  @override
  Future<bool> pingCheck() async {
    return parentSolanaWallet.pingCheck();
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {}

  Future<String?> _findTokenAccount({
    required String ownerAddress,
    required String mint,
    required RpcClient rpcClient,
  }) async {
    try {
      final result = await rpcClient.getTokenAccountsByOwner(
        ownerAddress,
        TokenAccountsFilter.byMint(mint),
        encoding: Encoding.jsonParsed,
      );

      if (result.value.isEmpty) {
        Logging.instance.w(
          "$runtimeType _findTokenAccount: No token account found for "
          "owner=$ownerAddress, mint=$mint",
        );
        return null;
      }

      final tokenAccountAddress = result.value.first.pubkey;
      Logging.instance.i(
        "$runtimeType _findTokenAccount: Found token account $tokenAccountAddress "
        "for owner=$ownerAddress, mint=$mint",
      );
      return tokenAccountAddress;
    } catch (e) {
      Logging.instance.w("$runtimeType _findTokenAccount error: $e");
      return null;
    }
  }

  Future<String?> _findOrDeriveRecipientTokenAccount({
    required String recipientAddress,
    required String mint,
    required RpcClient rpcClient,
  }) async {
    try {
      // First, try to find an existing token account
      final existingAccount = await _findTokenAccount(
        ownerAddress: recipientAddress,
        mint: mint,
        rpcClient: rpcClient,
      );

      if (existingAccount != null) {
        Logging.instance.i(
          "$runtimeType Found existing token account for recipient: $existingAccount",
        );
        return existingAccount;
      }

      // If no existing account found, try to derive the ATA
      Logging.instance.i(
        "$runtimeType No existing token account found, deriving ATA for recipient",
      );

      try {
        final ataAddress = await _deriveAtaAddress(
          ownerAddress: recipientAddress,
          mint: mint,
          rpcClient: rpcClient,
        );
        if (ataAddress != null) {
          Logging.instance.i("$runtimeType Derived ATA address: $ataAddress");
          return ataAddress;
        } else {
          Logging.instance.w("$runtimeType ATA derivation returned null");
          return null;
        }
      } catch (derivationError) {
        Logging.instance.w(
          "$runtimeType Failed to derive ATA address: $derivationError",
        );
        return null;
      }
    } catch (e) {
      Logging.instance.w(
        "$runtimeType _findOrDeriveRecipientTokenAccount error: $e",
      );
      return null;
    }
  }

  Future<String?> _deriveAtaAddress({
    required String ownerAddress,
    required String mint,
    required RpcClient rpcClient,
  }) async {
    try {
      final ownerPubkey = Ed25519HDPublicKey.fromBase58(ownerAddress);
      final mintPubkey = Ed25519HDPublicKey.fromBase58(mint);

      final tokenApi = SolanaTokenAPI();
      tokenApi.initializeRpcClient(rpcClient);

      String tokenProgramId;
      try {
        final mintInfo = await rpcClient.getAccountInfo(
          mint,
          encoding: Encoding.jsonParsed,
        );
        if (mintInfo.value != null) {
          tokenProgramId = mintInfo.value!.owner;
        } else {
          tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
        }
      } catch (e) {
        tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
      }

      final tokenProgramPubkey = Ed25519HDPublicKey.fromBase58(tokenProgramId);

      const associatedTokenProgramId =
          'ATokenGPvbdGVqstVQmcLsNZAqeEjlCoquUSjfJ5c';
      final associatedTokenProgramPubkey = Ed25519HDPublicKey.fromBase58(
        associatedTokenProgramId,
      );

      final seeds = [
        'account'.codeUnits,
        ownerPubkey.toBase58().codeUnits,
        tokenProgramPubkey.toBase58().codeUnits,
        mintPubkey.toBase58().codeUnits,
      ];

      final ataAddress = await Ed25519HDPublicKey.findProgramAddress(
        seeds: seeds,
        programId: associatedTokenProgramPubkey,
      );

      final ataBase58 = ataAddress.toBase58();

      return ataBase58;
    } catch (e, stackTrace) {
      Logging.instance.w(
        "$runtimeType _deriveAtaAddress error: $e",
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<int?> _getEstimatedTokenTransferFee({
    required Ed25519HDPublicKey senderTokenAccountKey,
    required Ed25519HDPublicKey recipientTokenAccountKey,
    required Ed25519HDPublicKey ownerPublicKey,
    required int amount,
    required RpcClient rpcClient,
  }) async {
    try {
      // Get latest blockhash for message compilation.
      final latestBlockhash = await rpcClient.getLatestBlockhash();

      final mintPubkey = Ed25519HDPublicKey.fromBase58(tokenMint);

      // Query the actual token program owner (important for Token-2022 variants).
      String tokenProgramId;
      try {
        final mintInfo = await rpcClient.getAccountInfo(
          tokenMint,
          encoding: Encoding.jsonParsed,
        );
        tokenProgramId = mintInfo.value?.owner ??
            'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
      } catch (e) {
        tokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';
      }

      // Build the TransferChecked instruction.
      // Determine which token program type to use based on the queried owner.
      final TokenProgramType tokenProgram =
          tokenProgramId != 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA'
              && tokenProgramId.startsWith('Token')
              ? TokenProgramType.token2022Program
              : TokenProgramType.tokenProgram;

      final instruction = TokenInstruction.transferChecked(
        source: senderTokenAccountKey,
        destination: recipientTokenAccountKey,
        mint: mintPubkey,
        owner: ownerPublicKey,
        decimals: tokenDecimals,
        amount: amount,
        tokenProgram: tokenProgram,
      );

      // Compile the message with the blockhash.
      final compiledMessage = Message(instructions: [instruction]).compile(
        recentBlockhash: latestBlockhash.value.blockhash,
        feePayer: ownerPublicKey,
      );

      // Get the fee for this compiled message.
      final feeEstimate = await rpcClient.getFeeForMessage(
        base64Encode(compiledMessage.toByteArray().toList()),
        commitment: Commitment.confirmed,
      );

      if (feeEstimate != null) {
        Logging.instance.i(
          "$runtimeType Estimated token transfer fee: $feeEstimate lamports (from RPC)",
        );
        return feeEstimate;
      }

      Logging.instance.w("$runtimeType getFeeForMessage returned null");
      return null;
    } catch (e) {
      Logging.instance.w(
        "$runtimeType _getEstimatedTokenTransferFee error: $e",
      );
      return null;
    }
  }

  Future<bool> _waitForConfirmation({
    required String signature,
    required int maxWaitSeconds,
    required RpcClient rpcClient,
  }) async {
    final startTime = DateTime.now();

    while (true) {
      try {
        final status = await rpcClient.getSignatureStatuses([
          signature,
        ], searchTransactionHistory: true);

        if (status.value.isNotEmpty) {
          final txStatus = status.value.first;

          // Check if transaction failed
          if (txStatus?.err != null) {
            Logging.instance.e(
              "$runtimeType Transaction failed: ${txStatus?.err}",
            );
            return false;
          }

          // Check if transaction confirmed
          if (txStatus?.confirmationStatus == Commitment.confirmed ||
              txStatus?.confirmationStatus == Commitment.finalized) {
            Logging.instance.i(
              "$runtimeType Transaction confirmed: $signature",
            );
            return true;
          }
        }
      } catch (e) {
        Logging.instance.w(
          "$runtimeType Error checking transaction confirmation: $e",
        );
      }

      // Check timeout
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      if (elapsed > maxWaitSeconds) {
        Logging.instance.w(
          "$runtimeType Transaction confirmation timeout after $maxWaitSeconds seconds",
        );
        return false;
      }

      // Wait before next check (2 seconds)
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
}

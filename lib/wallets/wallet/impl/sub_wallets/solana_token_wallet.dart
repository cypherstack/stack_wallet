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
import 'package:solana/dto.dart' hide Instruction;
import 'package:solana/encoder.dart' show Instruction;
import 'package:solana/solana.dart' hide Wallet;

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
  FilterOperation? get changeAddressFilterOperation =>
      parentSolanaWallet.changeAddressFilterOperation;

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      parentSolanaWallet.receivingAddressFilterOperation;

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.and([
    FilterCondition.equalTo(property: r"contractAddress", value: tokenMint),
    const FilterCondition.equalTo(
      property: r"subType",
      value: TransactionSubType.splToken,
    ),
  ]);

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

      if (recipientTokenAccount.isEmpty) {
        throw Exception(
          "Cannot determine recipient token account for mint $tokenMint. "
          "Recipient may not have a token account for this mint. "
          "Please ensure the recipient has initialized an Associated Token Account (ATA) first.",
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
          tokenProgramId == Token2022Program.programId
          ? TokenProgramType.token2022Program
          : TokenProgramType.tokenProgram;

      final recipientAccountInfo = await rpcClient.getAccountInfo(
        recipientTokenAccount,
        encoding: Encoding.jsonParsed,
      );

      AssociatedTokenAccountInstruction? createAccountInstruction;
      if (recipientAccountInfo.value == null) {
        createAccountInstruction =
            AssociatedTokenAccountInstruction.createAccount(
              funder: keyPair.publicKey,
              address: recipientTokenAccountKey,
              owner: Ed25519HDPublicKey.fromBase58(recipientAddress),
              mint: mintPubkey,
            );
      } else {
        try {
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
      }

      final instruction = TokenInstruction.transferChecked(
        source: senderTokenAccountKey,
        destination: recipientTokenAccountKey,
        mint: mintPubkey,
        owner: keyPair.publicKey,
        decimals: tokenDecimals,
        amount: txData.amount!.raw.toInt(),
        tokenProgram: tokenProgram,
      );

      final instructions = [
        if (createAccountInstruction != null) createAccountInstruction,
        instruction,
      ];

      final feeEstimate =
          await _getEstimatedTokenTransferFee(
            ownerPublicKey: keyPair.publicKey,
            rpcClient: rpcClient,
            instructions: instructions,
            memo: txData.memo,
          ) ??
          5000;

      return txData.copyWith(
        fee: Amount(rawValue: BigInt.from(feeEstimate), fractionDigits: 9),
        solInstructions: instructions,
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

      final instructions = txData.solInstructions;

      if (instructions == null || instructions.isEmpty) {
        throw Exception(
          "Token transaction missing instructions. "
          "Call prepareSend() first.",
        );
      }

      final recipientTokenAccount = await _findOrDeriveRecipientTokenAccount(
        recipientAddress: txData.recipients!.first.address,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      // Create message.
      final message = Message(
        instructions: [
          if (txData.memo != null)
            MemoInstruction(signers: const [], memo: txData.memo!),
          ...instructions,
        ],
      );

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
    await parentSolanaWallet.updateNode();
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
      final myTokenAccount = await _findTokenAccount(
        ownerAddress: walletAddress,
        mint: tokenMint,
        rpcClient: rpcClient,
      );

      if (myTokenAccount == null) {
        return;
      }

      // Fetch recent transactions for this token account.
      final txListIterable = await rpcClient.getTransactionsList(
        Ed25519HDPublicKey.fromBase58(myTokenAccount),
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
          final txid = parsedTx.signatures.isNotEmpty
              ? parsedTx.signatures[0]
              : null;

          if (parsedTx.signatures.length > 1) {
            Logging.instance.w(
              "SOL $walletId found tx with "
              "${parsedTx.signatures.length} signatures",
            );
          }

          if (txid == null) {
            skippedCount++;
            continue;
          }

          final splTransfers = parsedTx.message.instructions
              .map((e) => e.toJson())
              .where(
                (e) =>
                    e.containsKey("parsed") &&
                    e["program"] == "spl-token" &&
                    (e["parsed"]["type"] == "transferChecked" ||
                        e["parsed"]["type"] == "transfer"),
              );

          if (splTransfers.length != 1) {
            Logging.instance.w(
              "SOL $walletId found tx with "
              "${splTransfers.length} spl transfer! Skipping...",
            );
            skippedCount++;
            continue;
          }
          final transfer = splTransfers.first;
          final transferType = transfer["parsed"]["type"] as String;
          final BigInt lamports;
          if (transferType == "transferChecked") {
            lamports = BigInt.parse(
              transfer["parsed"]["info"]["tokenAmount"]["amount"].toString(),
            );
          } else {
            lamports = BigInt.parse(
              transfer["parsed"]["info"]["amount"].toString(),
            );
          }
          final senderAddress = transfer["parsed"]["info"]["source"] as String;
          final receiverAddress =
              transfer["parsed"]["info"]["destination"] as String;

          final TransactionType txType;

          if ((senderAddress == myTokenAccount) &&
              (receiverAddress == senderAddress)) {
            txType = TransactionType.sentToSelf;
          } else if (senderAddress == myTokenAccount) {
            txType = TransactionType.outgoing;
          } else if (receiverAddress == myTokenAccount) {
            txType = TransactionType.incoming;
          } else {
            // probably should never get here? If so, then this fragile parsing
            // is broken which isn't surprising...
            txType = TransactionType.unknown;
          }

          // check for memo
          final memos = parsedTx.message.instructions
              .map((e) => e.toJson())
              .where(
                (e) => e["parsed"] is String && e["program"] == "spl-memo",
              );
          final String? memo = memos.isEmpty
              ? null
              : memos.first["parsed"] as String;

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
                addresses: [senderAddress],
                valueStringSats: lamports.toString(),
                witness: null,
                innerRedeemScriptAsm: null,
                coinbase: null,
                walletOwns: senderAddress == myTokenAccount,
              ),
            ],
            outputs: [
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "00",
                valueStringSats: lamports.toString(),
                addresses: [receiverAddress],
                walletOwns: receiverAddress == myTokenAccount,
              ),
            ],
            version: txDetails.version?.version?.toInt() ?? -1,
            type: txType,
            subType: TransactionSubType.splToken,
            otherData: jsonEncode({
              TxV2OdKeys.contractAddress: tokenMint,
              TxV2OdKeys.isCancelled: (txDetails.meta!.err != null),
              TxV2OdKeys.overrideFee: txDetails.meta!.fee.toString(),
              if (memo != null) TxV2OdKeys.memo: memo,
            }),
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
  Future<void> checkSaveInitialReceivingAddress() async {
    await parentSolanaWallet.checkSaveInitialReceivingAddress();
  }

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

  Future<String> _findOrDeriveRecipientTokenAccount({
    required String recipientAddress,
    required String mint,
    required RpcClient rpcClient,
  }) async {
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

    return await _deriveAtaAddress(
      ownerAddress: recipientAddress,
      mint: mint,
      rpcClient: rpcClient,
    );
  }

  Future<String> _deriveAtaAddress({
    required String ownerAddress,
    required String mint,
    required RpcClient rpcClient,
  }) async {
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
        'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';
    final associatedTokenProgramPubkey = Ed25519HDPublicKey.fromBase58(
      associatedTokenProgramId,
    );

    final seeds = [
      ownerPubkey.bytes,
      tokenProgramPubkey.bytes,
      mintPubkey.bytes,
    ];

    final ataAddress = await Ed25519HDPublicKey.findProgramAddress(
      seeds: seeds,
      programId: associatedTokenProgramPubkey,
    );

    final ataBase58 = ataAddress.toBase58();

    return ataBase58;
  }

  Future<int?> _getEstimatedTokenTransferFee({
    required Ed25519HDPublicKey ownerPublicKey,
    required RpcClient rpcClient,
    required List<Instruction> instructions,
    required String? memo,
  }) async {
    try {
      // Get latest blockhash for message compilation.
      final latestBlockhash = await rpcClient.getLatestBlockhash();

      // Compile the message with the blockhash.
      final compiledMessage =
          Message(
            instructions: [
              if (memo != null) MemoInstruction(signers: const [], memo: memo),
              ...instructions,
            ],
          ).compile(
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

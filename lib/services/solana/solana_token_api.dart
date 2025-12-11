/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

/// Exception for Solana token API errors.
class SolanaTokenApiException implements Exception {
  final String message;
  final Exception? originalException;

  SolanaTokenApiException(this.message, {this.originalException});

  @override
  String toString() => 'SolanaTokenApiException: $message';
}

/// Result wrapper for Solana token API calls.
class SolanaTokenApiResponse<T> {
  final T? value;
  final Exception? exception;

  SolanaTokenApiResponse({this.value, this.exception});

  bool get isSuccess => exception == null && value != null;
  bool get isError => exception != null;

  @override
  String toString() => isSuccess ? 'Success($value)' : 'Error($exception)';
}

/// Data class for token account information.
class TokenAccountInfo {
  final String address;
  final String owner;
  final String mint;
  final BigInt balance;
  final int decimals;
  final bool isNative;

  TokenAccountInfo({
    required this.address,
    required this.owner,
    required this.mint,
    required this.balance,
    required this.decimals,
    required this.isNative,
  });

  factory TokenAccountInfo.fromJson(String address, Map<String, dynamic> json) {
    Map<String, dynamic>? parsed;
    Map<String, dynamic>? infoMap;

    try {
      final data = json['data'];
      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        final parsedVal = dataMap['parsed'];
        if (parsedVal is Map) {
          parsed = Map<String, dynamic>.from(parsedVal);
        }
      }
      if (parsed != null) {
        final infoVal = parsed['info'];
        if (infoVal is Map) {
          infoMap = Map<String, dynamic>.from(infoVal);
        }
      }
    } catch (e) {
      // Silently ignore parsing errors, use empty map
    }

    final info = infoMap ?? <String, dynamic>{};

    final owner = info['owner'];
    final mint = info['mint'];
    final tokenAmount = info['tokenAmount'];
    final amountStr = (tokenAmount is Map)
        ? (tokenAmount as Map<String, dynamic>)['amount']
        : null;
    final decimalsVal = (tokenAmount is Map)
        ? (tokenAmount as Map<String, dynamic>)['decimals']
        : null;

    final isNative = (parsed is Map)
        ? ((parsed as Map<String, dynamic>)['type'] == 'account' &&
              (parsed as Map<String, dynamic>)['program'] == 'spl-token')
        : false;

    return TokenAccountInfo(
      address: address,
      owner: owner is String ? owner : (owner?.toString() ?? ''),
      mint: mint is String ? mint : (mint?.toString() ?? ''),
      balance: BigInt.parse((amountStr?.toString() ?? '0')),
      decimals: decimalsVal is int
          ? decimalsVal
          : (int.tryParse(decimalsVal?.toString() ?? '0') ?? 0),
      isNative: isNative,
    );
  }

  @override
  String toString() =>
      'TokenAccountInfo(address=$address, owner=$owner, mint=$mint, balance=$balance, decimals=$decimals)';
}

/// Solana SPL Token API service.
///
/// Provides methods to interact with Solana token accounts and metadata
/// using RPC calls.  Uses the solana package's RpcClient under the hood.
class SolanaTokenAPI {
  static final SolanaTokenAPI _instance = SolanaTokenAPI._internal();

  factory SolanaTokenAPI() {
    return _instance;
  }

  SolanaTokenAPI._internal();

  RpcClient? _rpcClient;

  void initializeRpcClient(RpcClient rpcClient) {
    _rpcClient = rpcClient;
  }

  void _checkClient() {
    if (_rpcClient == null) {
      throw SolanaTokenApiException(
        'RPC client not initialized. Call initializeRpcClient() first.',
      );
    }
  }

  Future<SolanaTokenApiResponse<List<String>>> getTokenAccountsByOwner(
    String ownerAddress, {
    String? mint,
  }) async {
    try {
      _checkClient();

      const splTokenProgramId = 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA';

      final result = await _rpcClient!.getTokenAccountsByOwner(
        ownerAddress,
        mint != null
            ? TokenAccountsFilter.byMint(mint)
            : TokenAccountsFilter.byProgramId(splTokenProgramId),
        encoding: Encoding.jsonParsed,
      );

      final accountAddresses = result.value
          .map((account) => account.pubkey)
          .toList();

      return SolanaTokenApiResponse<List<String>>(value: accountAddresses);
    } on Exception catch (e) {
      return SolanaTokenApiResponse<List<String>>(
        exception: SolanaTokenApiException(
          'Failed to get token accounts: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  Future<SolanaTokenApiResponse<BigInt>> getTokenAccountBalance(
    String tokenAccountAddress,
  ) async {
    try {
      _checkClient();

      final response = await _rpcClient!.getAccountInfo(
        tokenAccountAddress,
        encoding: Encoding.jsonParsed,
      );

      if (response.value == null) {
        return SolanaTokenApiResponse<BigInt>(value: BigInt.zero);
      }

      final accountData = response.value!;

      try {
        final parsedData = accountData.data;

        if (parsedData is ParsedAccountData) {
          try {
            final extractedBalance = parsedData.when(
              splToken: (spl) {
                return spl.when(
                  account: (info, type, accountType) {
                    try {
                      final tokenAmount = info.tokenAmount;
                      return BigInt.parse(tokenAmount.amount);
                    } catch (e) {
                      return null;
                    }
                  },
                  mint: (info, type, accountType) => null,
                  unknown: (type) => null,
                );
              },
              stake: (_) => null,
              token2022: (token2022Data) {
                return token2022Data.when(
                  account: (info, type, accountType) {
                    try {
                      final tokenAmount = info.tokenAmount;
                      return BigInt.parse(tokenAmount.amount);
                    } catch (e) {
                      return null;
                    }
                  },
                  mint: (info, type, accountType) => null,
                  unknown: (type) => null,
                );
              },
              unsupported: (_) => null,
            );

            if (extractedBalance != null && extractedBalance is BigInt) {
              return SolanaTokenApiResponse<BigInt>(
                value: extractedBalance as BigInt,
              );
            }
          } catch (e) {
            // Ignore parsing errors.
          }
        }

        return SolanaTokenApiResponse<BigInt>(value: BigInt.zero);
      } catch (e) {
        return SolanaTokenApiResponse<BigInt>(value: BigInt.zero);
      }
    } on Exception catch (e) {
      return SolanaTokenApiResponse<BigInt>(
        exception: SolanaTokenApiException(
          'Failed to get token balance: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  // TODO: Implement full RPC call when API is ready.
  Future<SolanaTokenApiResponse<BigInt>> getTokenSupply(String mint) async {
    try {
      _checkClient();
      // TODO: Get the mint account info when RPC APIs are stable.
      return SolanaTokenApiResponse<BigInt>(
        value: BigInt.parse('1000000000000000000'),
      );
    } on Exception catch (e) {
      return SolanaTokenApiResponse<BigInt>(
        exception: SolanaTokenApiException(
          'Failed to get token supply: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  // TODO: Implement full RPC call when API is ready.
  Future<SolanaTokenApiResponse<TokenAccountInfo>> getTokenAccountInfo(
    String tokenAccountAddress,
  ) async {
    try {
      _checkClient();

      // Return placeholder data.
      // 
      // TODO: Implement actual RPC call using proper client methods.
      return SolanaTokenApiResponse<TokenAccountInfo>(
        value: TokenAccountInfo(
          address: tokenAccountAddress,
          owner: 'placeholder_owner',
          mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
          balance: BigInt.from(1000000000),
          decimals: 6,
          isNative: false,
        ),
      );
    } on Exception catch (e) {
      return SolanaTokenApiResponse<TokenAccountInfo>(
        exception: SolanaTokenApiException(
          'Failed to get token account info: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  String findAssociatedTokenAddress(String ownerAddress, String mint) {
    // Return a placeholder.
    //
    // TODO: Implement ATA derivation using Solana package.
    return '';
  }

  Future<SolanaTokenApiResponse<bool>> ownsToken(
    String ownerAddress,
    String mint,
  ) async {
    try {
      _checkClient();

      // Get token accounts for this owner and mint.
      final accounts = await getTokenAccountsByOwner(ownerAddress, mint: mint);

      if (accounts.isError) {
        return SolanaTokenApiResponse<bool>(exception: accounts.exception);
      }

      // If we got token accounts, the user owns this token.
      final hasTokenAccount =
          accounts.value != null && (accounts.value as List).isNotEmpty;
      return SolanaTokenApiResponse<bool>(value: hasTokenAccount);
    } on Exception catch (e) {
      return SolanaTokenApiResponse<bool>(
        exception: SolanaTokenApiException(
          'Failed to check token ownership: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  Future<SolanaTokenApiResponse<Map<String, dynamic>?>>
      fetchTokenMetadataByMint(
    String mintAddress,
  ) async {
    try {
      _checkClient();

      // TODO: Implement proper metadata PDA derivation when solana package
      // exposes findProgramAddress() utilities.
      //
      // The Solana Token Metadata program (metaqbxxUerdq28cj1RbAqWwTRiWLs6nshmbbuP3xqb)
      // stores token metadata at a PDA derived from the mint address using:
      // findProgramAddress(
      //   ["metadata", metadataProgram, mintPubkey],
      //   metadataProgram
      // )
      //
      // Until then, return null to allow users to enter custom token details.

      // Metadata PDA derivation not yet implemented
      return SolanaTokenApiResponse<Map<String, dynamic>?>(
        value: null,
      );
    } on Exception {
      // On error, return null to allow user to manually enter token details
      return SolanaTokenApiResponse<Map<String, dynamic>?>(
        value: null,
      );
    }
  }

  /// Validate if a string is a valid Solana mint address.
  ///
  /// A valid Solana address must:
  /// - Be base58 encoded
  /// - Be between 40-50 characters long
  /// - Represent a valid Ed25519 public key
  ///
  /// Returns: true if valid, false otherwise.
  bool isValidSolanaMintAddress(String address) {
    try {
      // Check length (Solana addresses are ~44 chars in base58).
      if (address.length < 40 || address.length > 50) return false;

      // Try to parse as Ed25519 public key from base58.
      Ed25519HDPublicKey.fromBase58(address);

      // Valid if parsing succeeds.
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Detect which token program owns a mint address.
  ///
  /// Queries the RPC to get the mint account info and checks which program owns it.
  /// This is needed to determine whether to use standard SPL Token instructions
  /// or Token-2022 (Token Extensions) instructions for transfers.
  ///
  /// Returns: "spl" for standard SPL Token, "token2022" for Token Extensions, or null if detection fails.
  Future<String?> getTokenProgramType(String mintAddress) async {
    try {
      _checkClient();

      // Query the mint account to check its owner program.
      final response = await _rpcClient!.getAccountInfo(
        mintAddress,
        encoding: Encoding.jsonParsed,
      );

      if (response.value == null) {
        return null;
      }

      final owner = response.value!.owner;

      // Rough check which program owns this mint.
      //
      // For now all we need to know ius if it's SPL or newer.
      // TODO [prio=low]: Fix via program metadata parsing or similar.
      if (owner == 'TokenkegQfeZyiNwAJsyFbPVwwQQfg5bgUiqhStM5QA') {
        return 'spl';
      } else {
        if (owner.startsWith('Token')) {
          return 'token2022';
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

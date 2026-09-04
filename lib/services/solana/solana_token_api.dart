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

import '../../utilities/default_sol_tokens.dart';

/// A token mint discovered in a wallet, with its decimals when known.
class DiscoveredSolMint {
  const DiscoveredSolMint({
    this.mint = '',
    this.decimals,
    this.rawBalance,
    this.hasConflictingDecimals = false,
  });

  final String mint;
  final int? decimals;
  final BigInt? rawBalance;
  final bool hasConflictingDecimals;
}

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

abstract interface class SolanaTokenDiscoveryClient {
  Future<ProgramAccountsResult> getTokenAccountsByProgram({
    required String walletAddress,
    required String programId,
  });

  Future<AccountResult> getAccountInfo(String mintAddress);
}

class _RpcSolanaTokenDiscoveryClient implements SolanaTokenDiscoveryClient {
  const _RpcSolanaTokenDiscoveryClient(this._client);

  final RpcClient _client;

  @override
  Future<ProgramAccountsResult> getTokenAccountsByProgram({
    required String walletAddress,
    required String programId,
  }) => _client.getTokenAccountsByOwner(
    walletAddress,
    TokenAccountsFilter.byProgramId(programId),
    encoding: Encoding.jsonParsed,
  );

  @override
  Future<AccountResult> getAccountInfo(String mintAddress) =>
      _client.getAccountInfo(mintAddress, encoding: Encoding.jsonParsed);
}

/// Solana SPL Token API service.
///
/// Provides methods to interact with Solana token accounts and metadata
/// using RPC calls.  Uses the solana package's RpcClient under the hood.
class SolanaTokenAPI {
  factory SolanaTokenAPI({
    RpcClient? rpcClient,
    SolanaTokenDiscoveryClient? discoveryClient,
  }) => SolanaTokenAPI._(
    rpcClient,
    discoveryClient ??
        (rpcClient == null ? null : _RpcSolanaTokenDiscoveryClient(rpcClient)),
  );

  SolanaTokenAPI._(this._rpcClient, this._discoveryClient);

  final RpcClient? _rpcClient;
  final SolanaTokenDiscoveryClient? _discoveryClient;

  void _checkClient() {
    if (_rpcClient == null) {
      throw SolanaTokenApiException('RPC client not configured.');
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
  fetchTokenMetadataByMint(String mintAddress) async {
    try {
      // Resolve name/symbol/logo from the bundled known token list when the
      // mint matches a well known token.
      for (final token in DefaultSolTokens.list) {
        if (token.address == mintAddress) {
          return SolanaTokenApiResponse<Map<String, dynamic>?>(
            value: {
              "name": token.name,
              "symbol": token.symbol,
              "decimals": token.decimals,
              "logoUri": token.logoUri,
            },
          );
        }
      }

      // On-chain metadata lookup is not implemented here: it would require
      // deriving the Token Metadata program PDA
      // (metaqbxxUerdq28cj1RbAqWwTRiWLs6nshmbbuP3xqb) from the mint and
      // decoding the Metaplex account, which the solana package does not yet
      // expose helpers for. Returning null lets callers fall back to a
      // mint-derived placeholder name/symbol while still using the correct
      // on-chain decimals.
      return SolanaTokenApiResponse<Map<String, dynamic>?>(value: null);
    } on Exception {
      // On error, return null to allow user to manually enter token details
      return SolanaTokenApiResponse<Map<String, dynamic>?>(value: null);
    }
  }

  /// Discover all SPL token mints held by a wallet.
  ///
  /// Queries the wallet's token accounts for both the standard SPL Token
  /// program and the Token2022 program, then extracts the unique mint
  /// addresses from those accounts along with the number of decimals each
  /// mint is configured with. The decimals are read directly from the parsed
  /// token account data ('tokenAmount.decimals'), which mirrors the value
  /// stored on the mint account, so balances are scaled correctly.
  Future<SolanaTokenApiResponse<List<DiscoveredSolMint>>>
  discoverTokensForWallet({required String walletAddress}) async {
    try {
      final client = _discoveryClient;
      if (client == null) {
        throw SolanaTokenApiException('RPC client not configured.');
      }

      const splTokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
      const token2022ProgramId = 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb';

      final splResponse = await client.getTokenAccountsByProgram(
        walletAddress: walletAddress,
        programId: splTokenProgramId,
      );

      final token2022Response = await client.getTokenAccountsByProgram(
        walletAddress: walletAddress,
        programId: token2022ProgramId,
      );

      final accounts = [...splResponse.value, ...token2022Response.value];

      final byMint = <String, DiscoveredSolMint>{};
      for (final account in accounts) {
        final extracted = _extractMintFromParsedTokenAccount(
          account.account.data,
        );
        final mint = extracted.mint;
        final balance = extracted.rawBalance;
        if (mint.isEmpty || balance == null) {
          continue;
        }

        final existing = byMint[mint];
        if (existing == null) {
          byMint[mint] = extracted;
        } else {
          final conflict =
              existing.hasConflictingDecimals ||
              existing.decimals != null &&
                  extracted.decimals != null &&
                  existing.decimals != extracted.decimals;
          final decimals = conflict
              ? null
              : existing.decimals ?? extracted.decimals;
          byMint[mint] = DiscoveredSolMint(
            mint: mint,
            decimals: decimals,
            rawBalance: existing.rawBalance! + balance,
            hasConflictingDecimals: conflict,
          );
        }
      }

      // For any mint whose decimals could not be read from the token account
      // data, fetch the mint account directly and read its decimals.
      final resolved = <DiscoveredSolMint>[];
      for (final entry in byMint.values) {
        // Positive wrapped/native token accounts are holdings too; closed or
        // zero-balance accounts are not.
        if (entry.rawBalance! <= BigInt.zero) {
          continue;
        }
        if (entry.decimals != null) {
          resolved.add(entry);
        } else {
          final decimals = await _fetchMintDecimals(entry.mint);
          resolved.add(
            DiscoveredSolMint(
              mint: entry.mint,
              decimals: decimals,
              rawBalance: entry.rawBalance,
              hasConflictingDecimals:
                  decimals == null && entry.hasConflictingDecimals,
            ),
          );
        }
      }

      return SolanaTokenApiResponse<List<DiscoveredSolMint>>(value: resolved);
    } on Exception catch (e) {
      return SolanaTokenApiResponse<List<DiscoveredSolMint>>(
        exception: SolanaTokenApiException(
          'Failed to discover tokens: ${e.toString()}',
          originalException: e,
        ),
      );
    }
  }

  /// Both token programs store a mint's decimals as a u8, so anything outside
  /// 0..255 came from a malformed or hostile node. The value ends up as
  /// Amount.fractionDigits on every send and balance for that token, where a
  /// negative one throws and a huge one makes Decimal arithmetic crawl, so
  /// treat it as unknown rather than persisting it to the token catalog.
  static int? _validMintDecimals(int? decimals) {
    if (decimals == null || decimals < 0 || decimals > 255) {
      return null;
    }
    return decimals;
  }

  /// Fetch the number of decimals configured on a token's mint account.
  ///
  /// Used as a fallback when the decimals could not be read from a parsed
  /// token account. Returns null if the mint account cannot be read or parsed.
  Future<int?> _fetchMintDecimals(String mintAddress) async {
    try {
      final response = await _discoveryClient!.getAccountInfo(mintAddress);

      final data = response.value?.data;
      if (data is ParsedAccountData) {
        return data.when(
          splToken: (spl) => spl.when(
            account: (info, type, accountType) => null,
            mint: (info, type, accountType) =>
                _validMintDecimals(info.decimals),
            unknown: (type) => null,
          ),
          token2022: (token2022data) => token2022data.when(
            account: (info, type, accountType) => null,
            mint: (info, type, accountType) =>
                _validMintDecimals(info.decimals),
            unknown: (type) => null,
          ),
          stake: (_) => null,
          unsupported: (_) => null,
        );
      }
    } catch (_) {
      // Ignore and report unknown decimals.
    }

    return null;
  }

  /// Extract the mint address and decimals from a parsed token account's data.
  ///
  /// Handles both standard SPL Token and Token2022 account data. The decimals
  /// come from 'tokenAmount.decimals' on the holding, which matches the value
  /// stored on the mint account. Returns an empty mint when the data is not a
  /// token account or cannot be parsed, and null decimals when unavailable.
  DiscoveredSolMint _extractMintFromParsedTokenAccount(dynamic data) {
    try {
      if (data is ParsedAccountData) {
        return data.when(
          splToken: (spl) => spl.when(
            account: (info, type, accountType) => DiscoveredSolMint(
              mint: info.mint,
              decimals: _validMintDecimals(info.tokenAmount.decimals),
              rawBalance: BigInt.tryParse(info.tokenAmount.amount),
            ),
            mint: (info, type, accountType) => const DiscoveredSolMint(),
            unknown: (type) => const DiscoveredSolMint(),
          ),
          token2022: (token2022data) => token2022data.when(
            account: (info, type, accountType) => DiscoveredSolMint(
              mint: info.mint,
              decimals: _validMintDecimals(info.tokenAmount.decimals),
              rawBalance: BigInt.tryParse(info.tokenAmount.amount),
            ),
            mint: (info, type, accountType) => const DiscoveredSolMint(),
            unknown: (type) => const DiscoveredSolMint(),
          ),
          stake: (_) => const DiscoveredSolMint(),
          unsupported: (_) => const DiscoveredSolMint(),
        );
      }

      if (data is Map<String, dynamic>) {
        final parsed = data['parsed'];
        if (parsed is Map<String, dynamic>) {
          final info = parsed['info'];
          if (info is Map<String, dynamic>) {
            final mint = info['mint'];
            if (mint is String) {
              int? decimals;
              BigInt? rawBalance;
              final tokenAmount = info['tokenAmount'];
              if (tokenAmount is Map) {
                final d = tokenAmount['decimals'];
                decimals = _validMintDecimals(
                  d is int ? d : int.tryParse(d?.toString() ?? ''),
                );
                rawBalance = BigInt.tryParse(
                  tokenAmount['amount']?.toString() ?? '',
                );
              }
              return DiscoveredSolMint(
                mint: mint,
                decimals: decimals,
                rawBalance: rawBalance,
              );
            }
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors and treat as no mint found.
    }

    return const DiscoveredSolMint();
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

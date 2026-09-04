import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana/dto.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/services/solana/solana_token_api.dart';
import 'package:stackwallet/wallets/isar/providers/solana/discovered_sol_tokens_provider.dart';

class _FakeDiscoveryClient implements SolanaTokenDiscoveryClient {
  _FakeDiscoveryClient(this.responses, {this.mintAccounts = const {}});

  final List<Future<ProgramAccountsResult> Function()> responses;
  final Map<String, AccountResult> mintAccounts;
  final programIds = <String>[];
  final mintLookups = <String>[];
  var _index = 0;

  @override
  Future<ProgramAccountsResult> getTokenAccountsByProgram({
    required String walletAddress,
    required String programId,
  }) {
    programIds.add(programId);
    return responses[_index++]();
  }

  @override
  Future<AccountResult> getAccountInfo(String mintAddress) async {
    mintLookups.add(mintAddress);
    return mintAccounts[mintAddress] ??
        (throw StateError("Unexpected mint lookup: $mintAddress"));
  }
}

void main() {
  ProgramAccount tokenAccount({
    required String mint,
    required String amount,
    required int decimals,
    bool token2022 = false,
  }) => ProgramAccount(
    pubkey: "account-$mint-$amount",
    account: Account(
      lamports: 1,
      owner: token2022 ? "token-2022" : "spl-token",
      executable: false,
      rentEpoch: BigInt.zero,
      data: token2022
          ? ParsedAccountData.token2022(
              SplTokenProgramAccountData.account(
                type: "account",
                info: SplTokenAccountDataInfo(
                  tokenAmount: TokenAmount(
                    amount: amount,
                    decimals: decimals,
                    uiAmountString: null,
                  ),
                  state: "initialized",
                  isNative: false,
                  mint: mint,
                  owner: "owner",
                ),
              ),
            )
          : ParsedAccountData.splToken(
              SplTokenProgramAccountData.account(
                type: "account",
                info: SplTokenAccountDataInfo(
                  tokenAmount: TokenAmount(
                    amount: amount,
                    decimals: decimals,
                    uiAmountString: null,
                  ),
                  state: "initialized",
                  isNative: false,
                  mint: mint,
                  owner: "owner",
                ),
              ),
            ),
    ),
  );

  ProgramAccountsResult response(List<ProgramAccount> accounts) =>
      ProgramAccountsResult(
        context: Context(slot: BigInt.one),
        value: accounts,
      );

  AccountResult mintAccount(int decimals) => AccountResult(
    context: Context(slot: BigInt.one),
    value: Account(
      lamports: 1,
      owner: "spl-token",
      executable: false,
      rentEpoch: BigInt.zero,
      data: ParsedAccountData.splToken(
        SplTokenProgramAccountData.mint(
          type: "mint",
          info: MintAccountDataInfo(
            mintAuthority: null,
            freezedAuthority: null,
            isInitialized: true,
            decimals: decimals,
            supply: "1",
          ),
        ),
      ),
    ),
  );

  test("discovers positive SPL and Token-2022 balances only", () async {
    final client = _FakeDiscoveryClient([
      () async => response([
        tokenAccount(mint: "closed", amount: "0", decimals: 6),
        tokenAccount(mint: "malformed", amount: "invalid", decimals: 6),
        tokenAccount(mint: "held", amount: "5", decimals: 8),
      ]),
      () async => response([
        tokenAccount(mint: "held", amount: "7", decimals: 8, token2022: true),
        tokenAccount(
          mint: "token-2022",
          amount: "1",
          decimals: 2,
          token2022: true,
        ),
      ]),
    ]);

    final result = await SolanaTokenAPI(
      discoveryClient: client,
    ).discoverTokensForWallet(walletAddress: "owner");

    expect(result.exception, isNull);
    expect(result.value!.map((mint) => mint.mint), ["held", "token-2022"]);
    expect(result.value!.first.rawBalance, BigInt.from(12));
    expect(result.value!.first.decimals, 8);
    expect(client.programIds, [
      "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
      "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
    ]);
  });

  test(
    "conflicting decimals remain unresolved when mint lookup fails",
    () async {
      final client = _FakeDiscoveryClient([
        () async => response([
          tokenAccount(mint: "conflict", amount: "1", decimals: 6),
          tokenAccount(mint: "conflict", amount: "1", decimals: 8),
          tokenAccount(mint: "conflict", amount: "1", decimals: 6),
        ]),
        () async => response(const []),
      ]);

      final result = await SolanaTokenAPI(
        discoveryClient: client,
      ).discoverTokensForWallet(walletAddress: "owner");

      expect(result.value!.single.mint, "conflict");
      expect(result.value!.single.decimals, isNull);
      expect(result.value!.single.hasConflictingDecimals, isTrue);
      expect(
        await resolveDiscoveredSolanaContracts(
          mints: result.value!,
          fetchMetadata: (_) async => SolanaTokenApiResponse(value: null),
        ),
        isEmpty,
      );
    },
  );

  test("concurrent API instances retain their own RPC clients", () async {
    final releaseFirst = Completer<ProgramAccountsResult>();
    final firstClient = _FakeDiscoveryClient([
      () => releaseFirst.future,
      () async => response(const []),
    ]);
    final secondClient = _FakeDiscoveryClient([
      () async =>
          response([tokenAccount(mint: "second", amount: "1", decimals: 6)]),
      () async => response(const []),
    ]);

    final firstFuture = SolanaTokenAPI(
      discoveryClient: firstClient,
    ).discoverTokensForWallet(walletAddress: "first-owner");
    final secondFuture = SolanaTokenAPI(
      discoveryClient: secondClient,
    ).discoverTokensForWallet(walletAddress: "second-owner");
    releaseFirst.complete(
      response([tokenAccount(mint: "first", amount: "1", decimals: 4)]),
    );

    expect((await firstFuture).value!.single.mint, "first");
    expect((await secondFuture).value!.single.mint, "second");
    expect(firstClient.programIds, hasLength(2));
    expect(secondClient.programIds, hasLength(2));
  });

  test("unknown decimals are skipped instead of becoming zero", () async {
    final contracts = await resolveDiscoveredSolanaContracts(
      mints: [
        DiscoveredSolMint(mint: "known", decimals: 6, rawBalance: BigInt.one),
        DiscoveredSolMint(mint: "unknown", rawBalance: BigInt.one),
      ],
      fetchMetadata: (_) async => SolanaTokenApiResponse(value: null),
    );

    expect(contracts.single.address, "known");
    expect(contracts.single.decimals, 6);
  });

  test("unknown metadata uses a mint-derived placeholder", () async {
    final contracts = await resolveDiscoveredSolanaContracts(
      mints: [
        DiscoveredSolMint(
          mint: "1234567890abcdef",
          decimals: 9,
          rawBalance: BigInt.one,
        ),
      ],
      fetchMetadata: (_) async => SolanaTokenApiResponse(value: null),
    );

    expect(contracts.single.name, "Token 1234...cdef");
    expect(contracts.single.symbol, "1234");
    expect(contracts.single.decimals, 9);
  });

  test("RPC failure is returned without partial discovery", () async {
    final client = _FakeDiscoveryClient([
      () async => throw Exception("offline"),
    ]);

    final result = await SolanaTokenAPI(
      discoveryClient: client,
    ).discoverTokensForWallet(walletAddress: "owner");

    expect(result.value, isNull);
    expect(result.exception, isA<SolanaTokenApiException>());
    expect(result.exception.toString(), contains("offline"));
  });

  test("decimals outside the u8 range are re-read from the mint", () async {
    final client = _FakeDiscoveryClient(
      [
        () async => response([
          tokenAccount(mint: "hostile", amount: "5", decimals: -7),
        ]),
        () async => response(const []),
      ],
      mintAccounts: {"hostile": mintAccount(6)},
    );

    final result = await SolanaTokenAPI(
      discoveryClient: client,
    ).discoverTokensForWallet(walletAddress: "owner");

    expect(client.mintLookups, ["hostile"]);
    expect(result.value!.single.decimals, 6);
  });

  test("decimals no source can vouch for stay unknown", () async {
    final client = _FakeDiscoveryClient(
      [
        () async => response([
          tokenAccount(mint: "hostile", amount: "5", decimals: 1000000),
        ]),
        () async => response(const []),
      ],
      mintAccounts: {"hostile": mintAccount(-3)},
    );

    final result = await SolanaTokenAPI(
      discoveryClient: client,
    ).discoverTokensForWallet(walletAddress: "owner");

    expect(result.value!.single.decimals, isNull);
    expect(
      await resolveDiscoveredSolanaContracts(
        mints: result.value!,
        fetchMetadata: (_) async => SolanaTokenApiResponse(value: null),
      ),
      isEmpty,
    );
  });

  group("reading the discovery provider", () {
    var runs = 0;

    ProviderContainer containerWithDiscovery() {
      runs = 0;
      final container = ProviderContainer(
        overrides: [
          pDiscoveredSolanaTokens.overrideWithProvider(
            (params) => FutureProvider.autoDispose<List<SolContract>>((
              ref,
            ) async {
              runs++;
              // Stands in for the RPC round trip; anything asynchronous at all
              // outlives the autoDispose garbage collection pass.
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return [
                SolContract(
                  address: params.walletId,
                  name: "name",
                  symbol: "sym",
                  decimals: 6,
                ),
              ];
            }),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test("delivers the discovered tokens", () async {
      final container = containerWithDiscovery();

      final discovered = await readDiscoveredSolanaTokens(
        container,
        walletId: "wallet-a",
        walletAddress: "address-a",
      );

      expect(discovered.single.address, "wallet-a");
      expect(runs, 1);

      // Why the helper exists: an unlistened read is disposed before the
      // provider can emit.
      await expectLater(
        container.read(
          pDiscoveredSolanaTokens((
            walletId: "wallet-b",
            walletAddress: "address-b",
          )).future,
        ),
        throwsStateError,
      );
    });

    test("rediscovers on the next visit", () async {
      final container = containerWithDiscovery();

      for (var visit = 0; visit < 2; visit++) {
        await readDiscoveredSolanaTokens(
          container,
          walletId: "wallet-a",
          walletAddress: "address-a",
        );
        await pumpEventQueue();
      }

      expect(runs, 2);
    });
  });

  test("only genuinely new contracts are auto-selected", () {
    SolContract contract(String mint) =>
        SolContract(address: mint, name: mint, symbol: mint, decimals: 6);

    final added = newDiscoveredSolanaContracts(
      knownContracts: [contract("existing")],
      discoveredContracts: [
        contract("existing"),
        contract("new"),
        contract("new"),
      ],
    );

    expect(added.map((contract) => contract.address), ["new"]);
  });
}

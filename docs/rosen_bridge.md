# Rosen Bridge swaps

The Swap tab offers **Rosen Bridge** for native FIRO ↔ rsFIRO on Ethereum mainnet. Both assets use 8 decimals. Only estimated quotes based on the send amount are supported. Bridge fees are deducted from the deposit; FIRO mining fees or ETH gas are additional.

FIRO deposits use the wallet's transparent balance. The transaction contains a zero-value OP_RETURN output with Rosen metadata; coin selection includes that output's serialized size. Immediately before broadcast, the signed raw transaction is checked for complete transparent inputs, the exact bridge lock payment and exactly one zero-value OP_RETURN containing the stored metadata. Missing, changed or duplicate metadata is rejected. Spark sends reject OP_RETURN data. A FIRO payout must also use a transparent mainnet address.

rsFIRO deposits call the token's ERC20 `transfer(lockAddress, amount)` function with Rosen metadata appended to the calldata and zero ETH value. The sender needs ETH for gas. Funding checks the mainnet chain ID, token decimals, token balance, gas estimate, destination, amount, metadata and current source-chain height. Selecting an Ethereum receiving wallet registers rsFIRO in its token list. Ethereum funding retains the wallet's existing restriction on Tor.

Bridge records use the existing swap persistence and polling. Broadcast transaction IDs are captured before local wallet-history updates; saved pending deposits remain ongoing swaps after restart. Polling matches the exact source transaction, source token, chains, destination, amount and encoded fees. `COMPLETED` requires a payout transaction ID before the swap becomes `Finished`; an unobserved transaction remains pending.

## Protocol and production configuration

Verified on 2026-09-17 against the Rosen production app, configuration version **7.1.1**:

| Value | Mainnet configuration |
| --- | --- |
| rsFIRO Ethereum contract | `0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2` |
| Ethereum lock address | `0x451698faa07fc68301af622a3ad42205f13c6e4b` |
| FIRO lock address | `aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y` |
| FIRO Ergo token | `581d7df25808881b2b8b9b4e03e2f637c46a94f74a69a5da36434125bacb4e08` |
| Minimum-fee configuration token | `e2ed4d64393222db666f20e67803e9e6fbe6d64531e14ff52ddd95615b0cbf17` |

These identifiers are pinned in `rosen_api.dart`. Reverify them against Rosen's deployed configuration when updating the integration. The [production configuration bundle](https://app.rosen.tech/_next/static/immutable/chunks/3uty44qqykf4p.js) supplied these values; the repository's generated configuration file intentionally contains empty defaults.

Metadata is `destinationChain:uint8 || bridgeFee:uint64BE || networkFee:uint64BE || addressLength:uint8 || addressBytes`. Ethereum's chain code is `3`, and its address is 20 raw bytes. FIRO's chain code is `7`, and its address is encoded as the P2PKH or P2SH output script.

Fee configuration comes from the unspent Ergo box containing both the pinned minimum-fee token and FIRO Ergo token. R4–R9 are decoded directly from serialized Sigma values. The applicable schedule activates strictly after its source-chain height. The bridge fee is `max(baseFee, amount * feeRatio ~/ 10000)`; the network fee is selected for the destination chain. All calculations use `BigInt`. Discovery uses Rosen scanner heights; funding rechecks with the wallet's source-chain tip. A scheduled fee change within 10 FIRO or 50 Ethereum blocks prevents funding until a stable quote is available.

Status requests use `https://app.rosen.tech/api/v1/events` with the `sourceTxId*` filter and exact matching after the response. Missing or unrecognized status data never marks a swap complete.

## Quote validity and refresh

Rosen FIRO/Ethereum requests have no fixed expiry timestamp or guaranteed duration in minutes. The encoded fees must satisfy the fee schedule applicable at the source transaction's mining height. Rosen's UI caches fee calculations for 10 minutes; that cache duration is not a request validity period. Its FIRO/Ethereum fee lookahead is 10/50 blocks, respectively, and its QR dialog warns that delayed submission can fail when fees change.

Stack re-fetches Rosen fees when creating a swap, preparing funding and confirming the send. A change to either fee component requires refreshing the quote, including decreases or changes that leave the total fee unchanged. Initial confirmation refreshes through the existing estimate API and shows the updated amount for review. An unfunded saved swap refreshes its fees, payout amount and bridge metadata together, rebuilds the transaction and returns to confirmation. It never automatically broadcasts the refreshed transaction. A funded swap cannot be refreshed and remains an ongoing swap while the bridge processes it.

Other Stack providers use the same estimate/confirmation machinery. ChangeNOW's expired `rateId` response is recognized, but previously produced an ordinary trade-creation error; there is no existing automatic stale-quote recovery or expiry timer shared by providers. Rosen uses the existing dialog and confirmation components with an explicit **Refresh quote** action.

Pinned upstream implementation references:

- [FIRO metadata and payment URI](https://github.com/rosen-bridge/ui/blob/8d8183c61cc1ab588a3cce08e74fbf2e9bc2e1c1/networks/firo/src/utils.ts)
- [Ethereum transfer calldata](https://github.com/rosen-bridge/ui/blob/8d8183c61cc1ab588a3cce08e74fbf2e9bc2e1c1/networks/evm/src/generateTxParameters.ts)
- [Fee schedule selection](https://github.com/rosen-bridge/utils/blob/7379a610271f34e54cedad68b6c2bb89b792b44d/packages/minimum-fee/lib/minimumFeeBox.ts) and [register layout](https://github.com/rosen-bridge/utils/blob/7379a610271f34e54cedad68b6c2bb89b792b44d/packages/minimum-fee/lib/utils.ts)
- [FIRO address codec](https://github.com/rosen-bridge/utils/blob/7379a610271f34e54cedad68b6c2bb89b792b44d/packages/address-codec-chains/firo/lib/firo.ts)
- [Event response and status mapping](https://github.com/rosen-bridge/ui/blob/8d8183c61cc1ab588a3cce08e74fbf2e9bc2e1c1/apps/rosen/src/backend/events/repository.ts)
- [Time-sensitive request warning](https://github.com/rosen-bridge/ui/blob/8d8183c61cc1ab588a3cce08e74fbf2e9bc2e1c1/apps/rosen/src/app/%28main%29/%28bridge%29/SubmitButton.tsx#L154-L156) and [fee cache lifetime](https://github.com/rosen-bridge/ui/blob/8d8183c61cc1ab588a3cce08e74fbf2e9bc2e1c1/apps/rosen/src/networks/firo/server.ts#L25-L28)

## Verification

The standalone fee check requires only Dart:

```sh
dart --enable-asserts test/rosen_fees_check.dart
```

After completing the repository's [build setup](building.md), including generated configuration, dependencies and required native libraries:

```sh
bash scripts/ensure_test_app_config.sh
flutter test test/services/exchange/rosen/rosen_protocol_test.dart test/wallets/firo_op_return_test.dart test/services/exchange/rosen_registration_test.dart
```

The fee check, 11 isolated protocol/OP_RETURN tests and read-only live fee/status endpoint checks were exercised during implementation and review. The tests include real native FIRO signing and validation of serialized outputs, rejection of altered or missing bridge outputs, and real web3dart signing through a mock `eth_sendRawTransaction` endpoint for both P2PKH and P2SH FIRO destinations. The Ethereum tests inspect the signed envelope for mainnet, the token contract, zero ETH and the complete metadata-bearing calldata. The `uint8` result from `decimals()` was verified to decode as `BigInt` with the pinned web3dart 3.0.1 dependency.

Review traced fresh mobile/desktop swaps, wallet-initiated swaps and resumed swaps from history through the shared Rosen prepare/confirm functions. Plain-address recipient QR scans now enable Next for Rosen, which does not use a refund-address field. No full Flutter build, complete application test run, or live bridge transfer was performed. Mobile and desktop funding, persistence, and completion still need validation in the configured application with real wallets before release.

Quote-refresh checks additionally cover fee increases/decreases, equal-total fee-component changes, preserving source amounts and destinations, regenerating metadata in both directions, stale/funded-save rejection and concurrent refresh protection. The standalone fee check ran directly; isolated harnesses exercised the actual refresh methods with fake network/wallet/database dependencies. Regression tests using real Hive are included in `rosen_registration_test.dart` but require the configured Flutter test environment and were not run here.

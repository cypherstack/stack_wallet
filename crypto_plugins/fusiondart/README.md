# FusionDart

A Dart package for interacting with CashFusion servers.

# WARNING

 - Do not test this with a wallet with tokens.

Do not import/inject CashToken, SLP, and other non-standard outputs into this package.  Fusiondart itself does not currently check for tokens and their use in CashFusion transactions will almost certainly lead to their loss.

## Features

 - [x] Testnet support
 - [x] Connect to CashFusion servers
 - [x] Send and receive CashFusion messages and status updates
 - [x] Register for CashFusion tiers
 - [x] Send and receive CashFusion transactions

## Getting started

### Building

FusionDart uses [coinlib](https://github.com/peercoin/coinlib) for cryptocurrency calculations, which [needs to be built](https://github.com/peercoin/coinlib/tree/master/coinlib#building-for-linux).  Build it according to their documentation ([macOS instructions here](https://github.com/peercoin/coinlib/tree/master/coinlib#building-for-macos)).

## Usage

See [cypherstack/stack_wallet/lib/services/mixins/fusion_wallet_interface.dart](https://github.com/cypherstack/stack_wallet/blob/fusion/lib/services/mixins/fusion_wallet_interface.dart) for a working example.  It follows this basic pattern:

```dart
import 'package:fusiondart/fusiondart.dart';

// Use server host and port which ultimately come from text fields.
fusion.FusionParams serverParams = fusion.FusionParams(
   serverHost: "fusion.servo.cash",
   serverPort: 8789,
   serverSsl: true,
   genesisHashHex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
   mode: fusion.FusionMode.normal, // normal, fanout, or consolidate.
   torForOver: false,
   enableDebugPrint: true, // Set to false for release.
);

// Instantiate a Fusion object with custom parameters.
_mainFusionObject = fusion.Fusion(serverParams);

// Pass wallet functions to the Fusion object.
await _mainFusionObject!.initFusion(
   getTransactionsByAddress: _getTransactionsByAddress,
   getUnusedReservedChangeAddresses: _getUnusedReservedChangeAddresses,
   getSocksProxyAddress: _getSocksProxyAddress,
   getChainHeight: _getChainHeight,
   updateStatusCallback: _updateStatus,
   checkUtxoExists: _checkUtxoExists,
   getTransactionJson: _getTransactionJson,
   getPrivateKeyForPubKey: _getPrivateKeyForPubKey,
   broadcastTransaction: _broadcastTransaction,
   unReserveAddresses: _unReserveAddresses,
);


// Fuse UTXOs.
await _mainFusionObject!.fuse(
   inputsFromWallet: coinList,
   network: fusion.Utilities.testNet,
);
```

You will need to define the injected methods `_getTransactionsByAddress`, `_getUnusedReservedChangeAddresses`, etc.

## Contributing

See https://github.com/cypherstack/fusiondart/issues for a list of issues to which you may contribute.  Please PR against the `staging` branch.

## Building Dart Files from fusion.proto

This section describes how to generate Dart files based on the `fusion.proto` file.

### Prerequisites

- Ensure that you have the `protoc` command-line tool installed.
- Navigate to the directory containing your `fusion.proto` file.

### Steps

1. Open your terminal and navigate to the directory where your `fusion.proto` file is located.
2. Run the following script ([fusiondart/lib/src/protobuf/build-proto-fusion.sh](https://github.com/cypherstack/fusiondart/blob/staging/lib/src/protobuf/build-proto-fusion.sh)) to generate the Dart files:

    ```bash
    #!/bin/bash

    # This script will build the dart files based on fusion.proto.

    # The path to your .proto file. Adjust this if necessary.
    PROTO_FILE="fusion.proto"

    # Run the protoc command.
    protoc --dart_out=grpc:. $PROTO_FILE
    ```

3. After running the script, Dart files will be generated in the same directory as your `.proto` file.
4. Manually copy any generated Dart files that you need to your `lib` folder.

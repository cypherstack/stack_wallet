import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

/// An ElectrumX server on a loopback port. Its chain is empty until [pay] is
/// called; wallets then see the payment like any confirmed transaction.
class FakeElectrumX {
  FakeElectrumX._(this._server, this._coin) {
    _server.listen(_serve);
  }

  static Future<FakeElectrumX> start(Bip39HDCurrency coin) async =>
      FakeElectrumX._(
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
        coin,
      );

  static const _tip = 800000;
  static const _serverVersion = 'ElectrumX 1.16.0';

  final ServerSocket _server;
  final Bip39HDCurrency _coin;
  final _sockets = <Socket>{};
  final _payments = <_Payment>[];

  int get port => _server.port;

  /// Adds a confirmed payment of [sats] to [address].
  void pay(String address, {int sats = 10000}) {
    final number = _payments.length + 1;
    final transaction = coinlib.Transaction(
      inputs: [
        // A coinbase input, so wallets have no earlier transaction to look up.
        // Its script makes every payment a different transaction.
        coinlib.RawInput(
          prevOut: coinlib.OutPoint(Uint8List(32), 0xffffffff),
          scriptSig: Uint8List.fromList([2, number & 0xff, number >> 8]),
        ),
      ],
      outputs: [
        coinlib.Output.fromAddress(
          BigInt.from(sats),
          coinlib.Address.fromString(address, _coin.networkParams),
        ),
      ],
    );
    _payments.add(
      _Payment(
        address: address,
        scriptHash: _coin.addressToScriptHash(address: address),
        sats: sats,
        height: _tip - 10,
        transaction: transaction,
      ),
    );
  }

  Future<void> close() async {
    await _server.close();
    for (final socket in _sockets.toList()) {
      socket.destroy();
    }
  }

  void _serve(Socket socket) {
    void drop() {
      _sockets.remove(socket);
      socket.destroy();
    }

    _sockets.add(socket);
    socket.done.ignore();
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            // One JSON-RPC request, or a batch of them, per line.
            Object? reply;
            try {
              final message = jsonDecode(line);
              reply = message is List
                  ? [for (final request in message) ?_reply(request as Map)]
                  : _reply(message as Map);
            } on Object {
              reply = _error(null, -32700, 'not a JSON-RPC request');
            }
            if (reply == null || (reply is List && reply.isEmpty)) return;
            socket.write('${jsonEncode(reply)}\n');
          },
          onError: (Object _) => drop(),
          onDone: drop,
          cancelOnError: true,
        );
  }

  Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  Map<String, Object?>? _reply(Map<dynamic, dynamic> request) {
    // A request without an id is a notification and gets no reply.
    if (!request.containsKey('id')) return null;
    final id = request['id'];
    try {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': _result(
          request['method'] as String,
          request['params'] as List? ?? const [],
        ),
      };
    } on _RpcError catch (error) {
      return _error(id, error.code, error.message);
    } on Object catch (error) {
      // Answer anyway, so a request this server cannot handle fails at once
      // instead of timing out.
      return _error(id, -32603, 'fake ElectrumX: $error');
    }
  }

  Object? _result(String method, List<dynamic> params) {
    Iterable<_Payment> paymentsTo() =>
        _payments.where((payment) => payment.scriptHash == params.first);

    switch (method) {
      case 'server.version':
        return [_serverVersion, '1.4'];
      case 'server.features':
        return {
          'genesis_hash': _coin.genesisHash,
          'hash_function': 'sha256',
          'server_version': _serverVersion,
          'protocol_min': '1.4',
          'protocol_max': '1.4.2',
          'pruning': null,
          'hosts': <String, Object?>{},
        };
      case 'server.ping':
      case 'blockchain.scripthash.subscribe':
        return null;
      case 'blockchain.headers.subscribe':
        return {'height': _tip, 'hex': '00' * 80};
      case 'blockchain.estimatefee':
      case 'blockchain.relayfee':
        return 0.00001;
      case 'blockchain.scripthash.get_history':
        return [
          for (final payment in paymentsTo())
            {'tx_hash': payment.txid, 'height': payment.height},
        ];
      case 'blockchain.scripthash.listunspent':
        return [
          for (final payment in paymentsTo())
            {
              'tx_hash': payment.txid,
              'tx_pos': 0,
              'height': payment.height,
              'value': payment.sats,
            },
        ];
      case 'blockchain.scripthash.get_balance':
        return {
          'confirmed': paymentsTo().fold(0, (sum, p) => sum + p.sats),
          'unconfirmed': 0,
        };
      case 'blockchain.transaction.get':
        final payment = _payments
            .where((payment) => payment.txid == params.first)
            .firstOrNull;
        if (payment == null) {
          throw const _RpcError(
            2,
            "daemon error: DaemonError({'code': -5, 'message': 'No such "
            "mempool or blockchain transaction. Use gettransaction for "
            "wallet transactions.'})",
          );
        }
        final verbose = params.length > 1 && params[1] == true;
        return verbose ? payment.verbose(_tip) : payment.transaction.toHex();
      default:
        throw _RpcError(-32601, 'unknown method "$method"');
    }
  }
}

class _Payment {
  _Payment({
    required this.address,
    required this.scriptHash,
    required this.sats,
    required this.height,
    required this.transaction,
  });

  final String address;
  final String scriptHash;
  final int sats;
  final int height;
  final coinlib.Transaction transaction;

  String get txid => transaction.txid;

  /// The transaction as `blockchain.transaction.get` returns it when verbose.
  Map<String, Object?> verbose(int tip) {
    final input = transaction.inputs.single;
    final output = transaction.outputs.single;
    return {
      'txid': txid,
      'hash': txid,
      'version': transaction.version,
      'size': transaction.size,
      'vsize': transaction.size,
      'locktime': transaction.locktime,
      'vin': [
        {
          'coinbase': coinlib.bytesToHex(input.scriptSig),
          'sequence': input.sequence,
        },
      ],
      'vout': [
        {
          'value': sats / 100000000,
          'n': 0,
          'scriptPubKey': {
            'hex': coinlib.bytesToHex(output.scriptPubKey),
            'address': address,
          },
        },
      ],
      'hex': transaction.toHex(),
      'blockhash': '00' * 32,
      'confirmations': tip - height + 1,
      'time': 1700000000,
      'blocktime': 1700000000,
    };
  }
}

class _RpcError implements Exception {
  const _RpcError(this.code, this.message);

  final int code;
  final String message;
}

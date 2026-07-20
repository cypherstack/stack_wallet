import '../wallets/api/xrp/xrp_rpc_client.dart';

/// Returns true if the rippled JSON-RPC node at [host]:[port] responds to
/// `server_info` with a validated ledger within the timeout.
Future<bool> testXrpNodeConnection(String host, int port) async {
  try {
    final state = await XrpRpcClient.serverState(
      nodeInfo: (host: host, port: port),
    ).timeout(const Duration(milliseconds: 2000));
    return state.ledgerIndex > 0;
  } catch (_) {
    return false;
  }
}

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart' as web3;

Future<bool> testEthNodeConnection(String host) async {
  web3.Web3Client client = web3.Web3Client(host, Client());
  try {
    await client.getBlockNumber();
    return true;
  } catch (_) {
    return false;
  }
}

import 'package:flutter_libarti/flutter_libarti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

final pTorService = Provider((_) => TorService.sharedInstance);

class TorService {
  static final sharedInstance = TorService();
  final _tor = Tor();

  int get port => _tor.port;

  Future<void> start() async {
    final dir = await StackFileSystem.applicationTorDirectory();
    await _tor.start(torDir: dir);
    return;
  }

  Future<void> stop() async {
    return await _tor.disable();
  }
}

// Local-only Epic/Epicmail settings used by the regtest harness.
//
// Production builds are unchanged unless STACK_EPIC_REGTEST is explicitly
// enabled at compile time.
abstract final class EpicRegtestConfig {
  static const enabled = bool.fromEnvironment('STACK_EPIC_REGTEST');

  static const nodeHost = String.fromEnvironment(
    'EPIC_REGTEST_NODE_HOST',
    defaultValue: 'http://127.0.0.1',
  );
  static const nodePort = int.fromEnvironment(
    'EPIC_REGTEST_NODE_PORT',
    defaultValue: 43413,
  );
  static const relayHost = String.fromEnvironment(
    'EPIC_REGTEST_RELAY_HOST',
    defaultValue: '127.0.0.1',
  );
  static const relayPort = int.fromEnvironment(
    'EPIC_REGTEST_RELAY_PORT',
    defaultValue: 43420,
  );

  static const chain = enabled ? 'usertesting' : 'mainnet';
  static const relayScheme = enabled ? 'ws' : 'wss';
  static const relayUnsecure = enabled;

  /// Returns the requested desktop data directory and fails closed when a
  /// regtest build could otherwise open the user's normal Stack data.
  static String? desktopDataDir(List<String> args) {
    if (args.length == 2 && args.first == '-d' && args.last.trim().isNotEmpty) {
      return args.last;
    }
    if (enabled) {
      throw ArgumentError(
        'STACK_EPIC_REGTEST requires an isolated desktop data directory: '
        'pass -a=-d -a=/path/to/disposable/stack-data to flutter run',
      );
    }
    return null;
  }
}

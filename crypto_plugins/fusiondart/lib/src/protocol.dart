/// A class that contains all the constants used in the protocol.
///
/// Refer to Electron-Cash [Electron-Cash/electroncash_plugins/fusion/server.py](https://github.com/Electron-Cash/Electron-Cash/blob/48ac434f9c7d94b335e1a31834ee2d7d47df5802/electroncash_plugins/fusion/server.py#L59).
abstract final class Protocol {
  // Define the version of the protocol in use.
  static const VERSION = 'alpha13';

  // Define a unique ID for the Fusion protocol.
  static const FUSE_ID = 'FUZ\x00';

  // Safety limits to prevent the loss of funds or excessive fees.
  // Note: If entering into the same fusion multiple times, limits apply separately for each player.

  // Maximum fee rate (in sat/kbyte) allowed for individual transaction components.
  static const MAX_COMPONENT_FEERATE = 5000;

  // The largest 'excess fee' that we are willing to pay in a fusion (fees beyond.
  // those needed to pay for our components' inclusion).
  static const MAX_EXCESS_FEE = 10000;

  // Maximum number of transaction components (inputs + outputs + blanks) allowed, even if the server allows more.
  static const MAX_COMPONENTS = 40;
  // The largest total fee we are willing to pay (our contribution to transaction
  // size should not exceed 7 kB even with 40 largest components).
  static const MAX_FEE = MAX_COMPONENT_FEERATE * 7 + MAX_EXCESS_FEE;
  // For privacy reasons, don't submit less than this many distinct tx components.
  // (distinct tx inputs, and tx outputs)
  static const MIN_TX_COMPONENTS = 11;

  // Minimum output value for a transaction component
  static const MIN_OUTPUT = 10000;

  // Timeout values and time windows for covert operations in [seconds]
  static const COVERT_CONNECT_TIMEOUT = 15;
  static const COVERT_CONNECT_WINDOW = 15;
  static const COVERT_SUBMIT_TIMEOUT = 3;
  static const COVERT_SUBMIT_WINDOW = 5;

  // Number of spare connections for covert operations.
  static const COVERT_CONNECT_SPARES = 6;

  // Maximum allowable clock discrepancy in [seconds].
  static const MAX_CLOCK_DISCREPANCY = 5;

  // Warm-up time and slop value for the protocol in [seconds].
  static const WARMUP_TIME = 30;
  static const WARMUP_SLOP = 3;

  // Time spent expecting commitments in the protocol in [seconds].
  static const TS_EXPECTING_COMMITMENTS = 3;

  // Start time for submitting components in the protocol in [seconds].
  static const T_START_COMPS = 5;

  // Time spent expecting covert components in the protocol in [seconds].
  static const TS_EXPECTING_COVERT_COMPONENTS = 15;

  // Start time for submitting signatures in the protocol in [seconds].
  static const T_START_SIGS = 20;

  // Time spent expecting covert signatures in the protocol in [seconds].
  static const TS_EXPECTING_COVERT_SIGNATURES = 30;

  // Time spent expecting conclusion in the protocol in [seconds].
  static const T_EXPECTING_CONCLUSION = 35;

  // Start time for closing the protocol session normally or with blame.
  static const T_START_CLOSE = 45;
  static const T_START_CLOSE_BLAME = 80;

  // Standard timeout value for miscellaneous operations in [seconds].
  static const STANDARD_TIMEOUT = 3;

  // Time allowed for verifying blame in the protocol in [seconds].
  static const BLAME_VERIFY_TIME = 5;
}

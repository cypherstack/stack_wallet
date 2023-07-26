  

class Protocol {
  static const VERSION = 'alpha13';

  static const FUSE_ID = 'FUZ\x00';


// Safety limits to prevent loss of funds / limit fees:
  //(Note that if we enter multiply into the same fusion, our limits apply
  //separately for each "player".)
  //
  //Deny server that asks for more than this component feerate (sat/kbyte).
  static const MAX_COMPONENT_FEERATE = 5000;
  //The largest 'excess fee' that we are willing to pay in a fusion (fees beyond
  //those needed to pay for our components' inclusion)
  static const MAX_EXCESS_FEE = 10000;
  // Even if the server allows more, put at most this many inputs+outputs+blanks
  static const MAX_COMPONENTS = 40;
  // The largest total fee we are willing to pay (our contribution to transaction
  // size should not exceed 7 kB even with 40 largest components).
  static const MAX_FEE = MAX_COMPONENT_FEERATE * 7 + MAX_EXCESS_FEE;
  // For privacy reasons, don't submit less than this many distinct tx components.
  // (distinct tx inputs, and tx outputs)
  static const MIN_TX_COMPONENTS = 11;

  static const MIN_OUTPUT = 10000;

  static const COVERT_CONNECT_TIMEOUT = 15.0;
  static const COVERT_CONNECT_WINDOW = 15.0;
  static const COVERT_SUBMIT_TIMEOUT = 3.0;
  static const COVERT_SUBMIT_WINDOW = 5.0;

  static const COVERT_CONNECT_SPARES = 6;

  static const MAX_CLOCK_DISCREPANCY = 5.0;

  static const WARMUP_TIME = 30.0;
  static const WARMUP_SLOP = 3.0;

  static const TS_EXPECTING_COMMITMENTS = 3.0;

  static const T_START_COMPS = 5.0;

  static const TS_EXPECTING_COVERT_COMPONENTS = 15.0;

  static const T_START_SIGS = 20.0;

  static const TS_EXPECTING_COVERT_SIGNATURES = 30.0;

  static const T_EXPECTING_CONCLUSION = 35.0;

  static const T_START_CLOSE = 45.0;
  static const T_START_CLOSE_BLAME = 80.0;

  static const STANDARD_TIMEOUT = 3.0;
  static const BLAME_VERIFY_TIME = 5.0;
}


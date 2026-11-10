/// The transaction may have been accepted, but its outcome could not be
/// established after the connection lost the broadcast response.
class BroadcastOutcomeUnknown implements Exception {
  const BroadcastOutcomeUnknown({
    required this.txid,
    required this.cause,
    this.confirmedTxids = const [],
  });

  static const title = 'Transaction status unknown';

  final String? txid;
  final Object cause;
  final List<String> confirmedTxids;

  @override
  String toString() =>
      'The transaction may already have been accepted by the network. '
      'Check your wallet history and the recipient before sending again.'
      '${txid == null ? '' : '\nTransaction ID: $txid'}'
      '${confirmedTxids.isEmpty ? '' : '\nOther transactions already sent: ${confirmedTxids.join(', ')}. Do not retry the full payment.'}';
}

// inscription data from litescribe /address/inscriptions endpoint
class InscriptionData {
  final String inscriptionId;
  final int inscriptionNumber;
  final String address;
  final String preview;
  final String content;
  final int contentLength;
  final String contentType;
  final String contentBody;
  final int timestamp;
  final String genesisTransaction;
  final String location;
  final String output;
  final int outputValue;
  final int offset;

  InscriptionData({
    required this.inscriptionId,
    required this.inscriptionNumber,
    required this.address,
    required this.preview,
    required this.content,
    required this.contentLength,
    required this.contentType,
    required this.contentBody,
    required this.timestamp,
    required this.genesisTransaction,
    required this.location,
    required this.output,
    required this.outputValue,
    required this.offset,
  });

  factory InscriptionData.fromJson(Map<String, dynamic> json) {
    return InscriptionData(
      inscriptionId: json['inscriptionId'] as String,
      inscriptionNumber: json['inscriptionNumber'] as int,
      address: json['address'] as String,
      preview: json['preview'] as String,
      content: json['content'] as String,
      contentLength: json['contentLength'] as int,
      contentType: json['contentType'] as String,
      contentBody: json['contentBody'] as String,
      timestamp: json['timestamp'] as int,
      genesisTransaction: json['genesisTransaction'] as String,
      location: json['location'] as String,
      output: json['output'] as String,
      outputValue: json['outputValue'] as int,
      offset: json['offset'] as int,
    );
  }

  /// Parse the response from an ord server's /inscription/{id} endpoint.
  /// [contentUrl] should be pre-built as `$baseUrl/content/$inscriptionId`.
  factory InscriptionData.fromOrdJson(
    Map<String, dynamic> json,
    String contentUrl,
  ) {
    final inscriptionId = json['inscription_id'] as String;
    final satpoint = json['satpoint'] as String? ?? '';
    // satpoint format: "txid:vout:offset"
    final satpointParts = satpoint.split(':');
    if (satpointParts.length < 2 || satpointParts[0].isEmpty) {
      throw FormatException(
        'Invalid satpoint for inscription $inscriptionId: "$satpoint"',
      );
    }
    final output = '${satpointParts[0]}:${satpointParts[1]}';
    final offset = satpointParts.length >= 3
        ? int.tryParse(satpointParts[2]) ?? 0
        : 0;

    return InscriptionData(
      inscriptionId: inscriptionId,
      inscriptionNumber: json['inscription_number'] as int? ?? 0,
      address: json['address'] as String? ?? '',
      preview: contentUrl,
      content: contentUrl,
      contentLength: json['content_length'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? '',
      contentBody: '',
      timestamp: json['timestamp'] as int? ?? 0,
      genesisTransaction: inscriptionId.split('i').first,
      location: satpoint,
      output: output,
      outputValue: json['output_value'] as int? ?? 0,
      offset: offset,
    );
  }

  @override
  String toString() {
    return 'InscriptionData {'
        ' inscriptionId: $inscriptionId,'
        ' inscriptionNumber: $inscriptionNumber,'
        ' address: $address,'
        ' preview: $preview,'
        ' content: $content,'
        ' contentLength: $contentLength,'
        ' contentType: $contentType,'
        ' contentBody: $contentBody,'
        ' timestamp: $timestamp,'
        ' genesisTransaction: $genesisTransaction,'
        ' location: $location,'
        ' output: $output,'
        ' outputValue: $outputValue,'
        ' offset: $offset'
        ' }';
  }
}

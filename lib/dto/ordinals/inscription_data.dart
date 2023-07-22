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

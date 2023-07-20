import 'package:stackwallet/dto/ordinals/litescribe_response.dart';

class AddressInscriptionResponse extends LitescribeResponse<AddressInscriptionResponse> {
  final int status;
  final String message;
  final AddressInscriptionResult result;

  AddressInscriptionResponse({
    required this.status,
    required this.message,
    required this.result,
  });

  factory AddressInscriptionResponse.fromJson(Map<String, dynamic> json) {
    return AddressInscriptionResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      result: AddressInscriptionResult.fromJson(json['result'] as Map<String, dynamic>),
    );
  }
}

class AddressInscriptionResult {
  final List<AddressInscription> list;
  final int total;

  AddressInscriptionResult({
    required this.list,
    required this.total,
  });

  factory AddressInscriptionResult.fromJson(Map<String, dynamic> json) {
    return AddressInscriptionResult(
      list: (json['list'] as List).map((item) => AddressInscription.fromJson(item as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
    );
  }
}

class AddressInscription {
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

  AddressInscription({
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

  factory AddressInscription.fromJson(Map<String, dynamic> json) {
    return AddressInscription(
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
}

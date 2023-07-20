import 'package:stackwallet/dto/ordinals/litescribe_response.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';

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
  final List<InscriptionData> list;
  final int total;

  AddressInscriptionResult({
    required this.list,
    required this.total,
  });

  factory AddressInscriptionResult.fromJson(Map<String, dynamic> json) {
    return AddressInscriptionResult(
      list: (json['list'] as List).map((item) => InscriptionData.fromJson(item as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
    );
  }
}

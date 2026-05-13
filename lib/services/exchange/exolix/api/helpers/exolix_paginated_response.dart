import '../dto/exolix_base_dto.dart';

class ExolixPaginatedResponse<T> {
  final List<T> data;
  final int count;

  ExolixPaginatedResponse({required this.data, required this.count});

  factory ExolixPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final dynamic rawData = json["data"];
    final List<T> items = (rawData is List)
        ? rawData
              .map((e) => itemFromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
        : <T>[];
    return ExolixPaginatedResponse(
      data: items,
      count: int.parse(json["count"].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "data": data.map((e) {
        if (e is ExolixBaseDto) return e.toMap();
        return e.toString();
      }).toList(),
      "count": count,
    };
  }

  @override
  String toString() => toMap().toString();
}

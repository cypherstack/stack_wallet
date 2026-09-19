abstract class ExolixBaseDto {
  Map<String, dynamic> toMap();

  @override
  String toString() => toMap().toString();
}

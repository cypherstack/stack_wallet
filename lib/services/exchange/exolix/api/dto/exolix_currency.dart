import 'exolix_base_dto.dart';
import 'exolix_network.dart';

/// A currency entry.
class ExolixCurrency extends ExolixBaseDto {
  final String code;
  final String name;
  final String? icon;
  final String? notes;

  /// Only populated when the listing was requested with withNetworks=true.
  final List<ExolixNetwork> networks;

  ExolixCurrency({
    required this.code,
    required this.name,
    required this.icon,
    required this.notes,
    required this.networks,
  });

  factory ExolixCurrency.fromJson(Map<String, dynamic> json) {
    final dynamic rawNetworks = json["networks"];
    final List<ExolixNetwork> nets = (rawNetworks is List)
        ? rawNetworks
              .map(
                (e) =>
                    ExolixNetwork.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
        : [];
    return ExolixCurrency(
      code: json["code"] as String? ?? "",
      name: json["name"] as String? ?? "",
      icon: json["icon"] as String?,
      notes: json["notes"] as String?,
      networks: nets,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "code": code,
      "name": name,
      "icon": icon,
      "notes": notes,
      "networks": networks.map((n) => n.toMap()).toList(),
    };
  }
}

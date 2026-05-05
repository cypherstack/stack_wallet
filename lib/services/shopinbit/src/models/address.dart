class Address {
  final String? company;
  final String? vat;
  final String firstName;
  final String lastName;
  final String street;
  final String zip;
  final String city;
  final String country;
  final String? state;

  Address({
    this.company,
    this.vat,
    required this.firstName,
    required this.lastName,
    required this.street,
    required this.zip,
    required this.city,
    required this.country,
    this.state,
  });

  Map<String, dynamic> toJson() => {
    'company': company,
    'vat': vat,
    'firstName': firstName,
    'lastName': lastName,
    'street': street,
    'zip': zip,
    'city': city,
    'country': country,
    'state': state,
  };

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      company: json['company'] as String?,
      vat: json['vat'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      street: json['street'] as String,
      zip: json['zip'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      state: json['state'] as String?,
    );
  }
}

class AddressModel {
  final int? id;
  final String label;
  final String addressLine;
  final double latitude;
  final double longitude;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) {
    return AddressModel(
      id: j['id'],
      label: j['label'] ?? 'Home',
      addressLine: j['address_line'] ?? '',
      latitude: (j['latitude'] is String)
          ? double.parse(j['latitude'])
          : (j['latitude']?.toDouble() ?? 0),
      longitude: (j['longitude'] is String)
          ? double.parse(j['longitude'])
          : (j['longitude']?.toDouble() ?? 0),
      isDefault: j['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'address_line': addressLine,
    'latitude': latitude,
    'longitude': longitude,
    'is_default': isDefault,
  };
}

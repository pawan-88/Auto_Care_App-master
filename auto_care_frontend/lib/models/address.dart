class AddressModel {
  final int? id;
  final String addressType;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String? createdAt;

  AddressModel({
    this.id,
    required this.addressType,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    print('🔵 Parsing address JSON: $json');

    try {
      final address = AddressModel(
        id: json['id'],
        addressType: json['address_type'] ?? 'home',
        addressLine1: json['address_line1'] ?? '',
        addressLine2: json['address_line2'],
        landmark: json['landmark'],
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        pincode: json['pincode'] ?? '',
        latitude: (json['latitude'] is String)
            ? double.parse(json['latitude'])
            : (json['latitude']?.toDouble() ?? 0.0),
        longitude: (json['longitude'] is String)
            ? double.parse(json['longitude'])
            : (json['longitude']?.toDouble() ?? 0.0),
        isDefault: json['is_default'] ?? false,
        createdAt: json['created_at'],
      );

      print(
        '✅ Address parsed successfully: ${address.displayLabel} - ${address.city}',
      );
      return address;
    } catch (e) {
      print('❌ Error parsing address: $e');
      print('❌ Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'address_type': addressType,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'landmark': landmark,
    'city': city,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'is_default': isDefault,
  };

  // Helper methods for UI display
  String get fullAddress {
    List<String> parts = [
      addressLine1,
      if (addressLine2?.isNotEmpty == true) addressLine2!,
      if (landmark?.isNotEmpty == true) landmark!,
      city,
      state,
      pincode,
    ];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  String get displayLabel {
    switch (addressType) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'other':
        return 'Other';
      default:
        return 'Address';
    }
  }

  // Compatibility methods for existing code
  String getAddressTypeLabel() => displayLabel;
  String getShortAddress() => fullAddress;

  // Backwards compatibility
  String get label => displayLabel;
  String get addressLine => fullAddress;
}

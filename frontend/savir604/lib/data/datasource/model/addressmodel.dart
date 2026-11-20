class AddressModel {
  String? addressId;
  String? addressUsersid;
  String? addressName;
  String? addressCity;
  String? addressStreet;
  String? addressphone;
  String? addressLat;
  String? addressLong;

  AddressModel({
    this.addressId,
    this.addressUsersid,
    this.addressName,
    this.addressCity,
    this.addressStreet,
    this.addressphone,
    this.addressLat,
    this.addressLong,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    addressId = json['address_id'].toString();
    addressUsersid = json['address_usersid'].toString();
    addressName = json['address_name'].toString();
    addressCity = json['address_city'].toString();
    addressStreet = json['address_street'].toString();
    addressphone = json['address_phone'].toString();
    addressLat = json['address_lat']?.toString();
    addressLong = json['address_long']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address_id'] = addressId;
    data['address_usersid'] = addressUsersid;
    data['address_name'] = addressName;
    data['address_city'] = addressCity;
    data['address_street'] = addressStreet;
    data['address_phone'] = addressphone;
    data['address_lat'] = addressLat;
    data['address_long'] = addressLong;
    return data;
  }

  double? get resolvedLatitude {
    return _parseCoordinate(addressLat) ??
        _parseCoordinatePair('$addressName $addressStreet')?.latitude;
  }

  double? get resolvedLongitude {
    return _parseCoordinate(addressLong) ??
        _parseCoordinatePair('$addressName $addressStreet')?.longitude;
  }
}

class _CoordinatePair {
  const _CoordinatePair({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

double? _parseCoordinate(String? value) {
  if (value == null) {
    return null;
  }

  final text = value.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  final number = double.tryParse(text);
  if (number == null || number == 0) {
    return null;
  }

  return number;
}

_CoordinatePair? _parseCoordinatePair(String? value) {
  if (value == null) {
    return null;
  }

  final text = value.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  final match = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*[,;|\s]+\s*(-?\d+(?:\.\d+)?)',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }

  final latitude = double.tryParse(match.group(1) ?? '');
  final longitude = double.tryParse(match.group(2) ?? '');
  if (latitude == null || longitude == null) {
    return null;
  }

  if (latitude == 0 && longitude == 0) {
    return null;
  }

  return _CoordinatePair(latitude: latitude, longitude: longitude);
}

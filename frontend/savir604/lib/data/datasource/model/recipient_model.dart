class RecipientModel {
  const RecipientModel({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.addressName,
    required this.addressLine,
    this.locationNote = '',
    this.building = '',
    this.floor = '',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String addressName;
  final String addressLine;
  final String locationNote;
  final String building;
  final String floor;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  RecipientModel copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? addressName,
    String? addressLine,
    String? locationNote,
    String? building,
    String? floor,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return RecipientModel(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressName: addressName ?? this.addressName,
      addressLine: addressLine ?? this.addressLine,
      locationNote: locationNote ?? this.locationNote,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? ''}',
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      addressName: '${json['address_name'] ?? ''}',
      addressLine: '${json['address_line'] ?? ''}',
      locationNote: '${json['location_note'] ?? ''}',
      building: '${json['building'] ?? ''}',
      floor: '${json['floor'] ?? ''}',
      latitude: json['latitude'] == null
          ? null
          : double.tryParse('${json['latitude']}'),
      longitude: json['longitude'] == null
          ? null
          : double.tryParse('${json['longitude']}'),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      'phone': phone,
      'address_name': addressName,
      'address_line': addressLine,
      'location_note': locationNote,
      'building': building,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  String get shortAddress {
    final buffer = <String>[
      if (addressName.trim().isNotEmpty) addressName.trim(),
      if (addressLine.trim().isNotEmpty) addressLine.trim(),
    ];
    return buffer.join(' - ');
  }

  double? get resolvedLatitude {
    return _parseCoordinate(latitude) ??
        _parseCoordinatePair('$addressName $addressLine')?.latitude;
  }

  double? get resolvedLongitude {
    return _parseCoordinate(longitude) ??
        _parseCoordinatePair('$addressName $addressLine')?.longitude;
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

double? _parseCoordinate(double? value) {
  if (value == null || value == 0) {
    return null;
  }

  return value;
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

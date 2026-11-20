class DriverTripDestination {
  const DriverTripDestination({
    required this.latitude,
    required this.longitude,
    required this.passengerName,
    required this.tripStatus,
    required this.tripId,
    this.destinationLabel,
  });

  final double latitude;
  final double longitude;
  final String passengerName;
  final String tripStatus;
  final String tripId;
  final String? destinationLabel;

  factory DriverTripDestination.fromArguments(Map<dynamic, dynamic>? args) {
    final lat = double.tryParse(
      '${args?['destination_lat'] ?? args?['lat'] ?? ''}',
    );
    final lng = double.tryParse(
      '${args?['destination_lng'] ?? args?['lng'] ?? ''}',
    );

    return DriverTripDestination(
      latitude: lat ?? 36.2021,
      longitude: lng ?? 37.1343,
      passengerName: '${args?['passenger_name'] ?? 'Ahmad Darwish'}',
      tripStatus: '${args?['trip_status'] ?? 'On the way'}',
      tripId: '${args?['trip_id'] ?? 'demo-trip-001'}',
      destinationLabel: args?['destination_label']?.toString(),
    );
  }
}

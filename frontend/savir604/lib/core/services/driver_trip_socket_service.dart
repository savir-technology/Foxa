import 'dart:async';

import 'package:tks/features/location/domain/entities/driver_location.dart';

abstract class DriverTripSocketService {
  Future<void> connect(String tripId);
  Future<void> emitDriverLocation({
    required String tripId,
    required DriverLocation location,
  });
  Stream<Map<String, dynamic>> get events;
  Future<void> disconnect();
}

class DriverTripSocketStubService implements DriverTripSocketService {
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isClosed = false;

  @override
  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  @override
  Future<void> connect(String tripId) async {
    if (_isClosed) {
      return;
    }

    _eventsController.add({
      'type': 'connected',
      'trip_id': tripId,
    });
  }

  @override
  Future<void> emitDriverLocation({
    required String tripId,
    required DriverLocation location,
  }) async {
    if (_isClosed) {
      return;
    }

    _eventsController.add({
      'type': 'driver_location',
      'trip_id': tripId,
      'payload': location.toJson(),
    });
  }

  @override
  Future<void> disconnect() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    await _eventsController.close();
  }
}

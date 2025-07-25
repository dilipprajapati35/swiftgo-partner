// lib/services/driver_location_service.dart

import 'dart:async';
import 'package:flutter_arch/services/socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // --- NEW --- Import for LatLng

class DriverLocationService {
  Timer? _locationTimer;
  final String tripId;
  final Function(LatLng)? onLocationUpdate; // --- NEW --- Callback for UI updates

  final SocketService _socketService = SocketService();

  DriverLocationService({
    required this.tripId,
    this.onLocationUpdate, // --- NEW ---
  });

  void startSendingLocation() async {
    print('🚗 Starting driver location broadcasting for trip: $tripId (Official Guide Implementation)');

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    print('📡 Driver is now broadcasting location every 8 seconds (following official guide)...');

    _sendCurrentLocation();

    _locationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _sendCurrentLocation();
    });
  }

  void _sendCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      // --- NEW --- Use the callback to update the local UI
      onLocationUpdate?.call(LatLng(position.latitude, position.longitude));
      
      _sendLocationUpdate(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting or sending location: $e');
    }
  }

  void _sendLocationUpdate(double latitude, double longitude) {
    if (_socketService.socket == null || !_socketService.socket!.connected) {
      print('⚠️ Socket not connected. Location update for trip $tripId skipped.');
      return;
    }

    // Following official guide: Message Name: updateDriverLocation
    final payload = {
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
    };

    _socketService.emit('updateDriverLocation', payload);
    print('� Driver location broadcast: lat: $latitude, lon: $longitude (trip: $tripId)');
  }

  void stopSendingLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print('🛑 Stopped live tracking broadcasts for trip: $tripId (Official Guide cleanup)');
  }
}
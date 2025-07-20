import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverLocationService {
  Timer? _locationTimer;
  final String driverToken;

  DriverLocationService({required this.driverToken});

  // Call this function when the driver starts their trip
  void startSendingLocation() async {
    // First, check for location permissions
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    // Start a timer to send location every 10 seconds
    _locationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );

        // Send the location to the backend
        await _sendLocationUpdate(position.latitude, position.longitude);

      } catch (e) {
        print('Error getting or sending location: $e');
      }
    });
  }

  Future<void> _sendLocationUpdate(double latitude, double longitude) async {
    // IMPORTANT: Replace with your server address
    final Uri url = Uri.parse('http://34.93.60.221:3001/driver/dashboard/location');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $driverToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        print('Location sent successfully: $latitude, $longitude');
      } else {
        print('Failed to send location:  [31m${response.body} [0m');
      }
    } catch (e) {
      print('Error in _sendLocationUpdate: $e');
    }
  }

  // Call this function when the driver's trip ends
  void stopSendingLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print('Stopped sending location updates.');
  }
} 
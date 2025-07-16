import 'package:flutter/material.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';
import 'package:flutter_arch/services/driver_location_service.dart';
import 'dart:async'; // Added for Timer

class TripPassengersScreen extends StatefulWidget {
  final String tripId;
  final LatLngModel startCoordinates;
  final LatLngModel endCoordinates;
  const TripPassengersScreen({Key? key, required this.tripId, required this.startCoordinates, required this.endCoordinates}) : super(key: key);

  @override
  State<TripPassengersScreen> createState() => _TripPassengersScreenState();
}

class _TripPassengersScreenState extends State<TripPassengersScreen> {
  bool _isLoading = true;
  bool _isUnlocking = false;
  bool _isTripUnlocked = false;
  List<Map<String, dynamic>> _passengers = [];
  GoogleMapController? _mapController;
  DriverLocationService? _locationService; // Add this field
  MySecureStorage secureStorage = MySecureStorage();

  // Add for passenger location tracking
  List<Map<String, dynamic>> _passengerLocations = [];
  Timer? _passengerLocationTimer;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
  }

  @override
  void dispose() {
    _locationService?.stopSendingLocation(); // Stop location updates
    _passengerLocationTimer?.cancel(); // Stop passenger location polling
    super.dispose();
  }

  Future<void> _fetchPassengers() async {
    setState(() { _isLoading = true; });
    try {
      final passengers = await DioHttp().getTripPassengers(context, widget.tripId);
      setState(() {
        _passengers = passengers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load passengers')),
      );
    }
  }

  // Fetch passenger locations for driver tracking
  Future<void> _fetchPassengerLocations() async {
    try {
      final locations = await DioHttp().getPassengerLocations(context, widget.tripId);
      setState(() {
        _passengerLocations = locations;
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _unlockTrip() async {
    setState(() { _isUnlocking = true; });
    try {
      final response = await DioHttp().startTrip(context, widget.tripId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride unlocked!')),
        );
        // Start sending location after unlocking the ride
        if (_locationService == null) {
          final token = await secureStorage.readToken();
          _locationService = DriverLocationService(driverToken: token!);
          _locationService!.startSendingLocation();
        }
        await _fetchPassengers();
        setState(() { _isTripUnlocked = true; });
        // Start periodic fetching of passenger locations
        _passengerLocationTimer = Timer.periodic(Duration(seconds: 10), (_) => _fetchPassengerLocations());
        // Fetch immediately as well
        _fetchPassengerLocations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlock ride')),
        );
      }
    } catch (e) {
      // Optionally handle error
    }
    setState(() { _isUnlocking = false; });
  }

  Set<Marker> _buildPassengerMarkers() {
    // Use _passengerLocations if trip is unlocked, else use _passengers
    final locations = _isTripUnlocked ? _passengerLocations : _passengers;
    return locations.where((p) => (p['latitude'] ?? 0) != null && (p['longitude'] ?? 0) != null && p['latitude'] != null && p['longitude'] != null)
      .map((p) {
        final lat = p['latitude'];
        final lng = p['longitude'];
        if (lat == null || lng == null) return null;
        return Marker(
          markerId: MarkerId(p['bookingId'] ?? p['name'] ?? ''),
          position: LatLng(
            (lat).toDouble(),
            (lng).toDouble(),
          ),
          infoWindow: InfoWindow(title: p['fullName'] ?? p['name'] ?? 'Passenger'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      })
      .whereType<Marker>()
      .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final start = LatLng(widget.startCoordinates.latitude, widget.startCoordinates.longitude);
    final end = LatLng(widget.endCoordinates.latitude, widget.endCoordinates.longitude);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Passengers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map at the top
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  child: GoogleMap(
                    onMapCreated: (c) => _mapController = c,
                    initialCameraPosition: CameraPosition(
                      target: start,
                      zoom: 13.5,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: Colors.blue,
                        width: 5,
                        points: [start, end],
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: start,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Start'),
                      ),
                      Marker(
                        markerId: const MarkerId('end'),
                        position: end,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: const InfoWindow(title: 'End'),
                      ),
                      ..._buildPassengerMarkers(),
                    },
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                if (!_isTripUnlocked)
                  DraggableScrollableSheet(
                    initialChildSize: 0.38,
                    minChildSize: 0.25,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _UnlockRideCard(
                              pickupAddress: _passengers.isNotEmpty ? (_passengers[0]['pickupStopName'] ?? 'Pickup Address') : 'Pickup Address',
                              distance: '25 km',
                              duration: '10 min',
                              speed: '45 kph',
                              onUnlock: !_isUnlocking ? _unlockTrip : null,
                              isUnlocking: _isUnlocking,
                            ),
                            const SizedBox(height: 16),
                            _PassengersListCard(passengers: _passengers),
                          ],
                        ),
                      );
                    },
                  ),
                if (_isTripUnlocked)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _PassengersListCard(passengers: _passengers),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PassengerInfoCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double rating;
  final String reviews;
  final String distance;
  final String time;
  final VoidCallback? onCall;

  const _PassengerInfoCard({
    Key? key,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.time,
    this.onCall,
  }) : super(key: key);

  factory _PassengerInfoCard.placeholder() => _PassengerInfoCard(
        name: 'No passenger',
        avatarUrl: null,
        rating: 0,
        reviews: '0',
        distance: '-',
        time: '-',
        onCall: null,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 32) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating > 0 ? rating.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text('($reviews reviews)', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onCall != null)
                  ElevatedButton(
                    onPressed: onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Call'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('DISTANCE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Column(
                  children: [
                    const Text('TIME', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengersListCard extends StatelessWidget {
  final List<Map<String, dynamic>> passengers;
  const _PassengersListCard({Key? key, required this.passengers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: passengers.isEmpty
            ? const Center(child: Text('No passengers found.'))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passengers.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final p = passengers[index];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: p['passengerProfilePhotoUrl'] != null
                            ? NetworkImage(p['passengerProfilePhotoUrl'])
                            : null,
                        child: p['passengerProfilePhotoUrl'] == null
                            ? const Icon(Icons.person, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['passengerName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              p['pickupStopName'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 2),
                          const Text('5.0', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),     
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _UnlockRideCard extends StatelessWidget {
  final String pickupAddress;
  final String distance;
  final String duration;
  final String speed;
  final VoidCallback? onUnlock;
  final bool isUnlocking;

  const _UnlockRideCard({
    required this.pickupAddress,
    required this.distance,
    required this.duration,
    required this.speed,
    this.onUnlock,
    this.isUnlocking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text("PICKUP ADDRESS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoColumn(icon: Icons.map, label: "DISTANCE", value: distance),
                _InfoColumn(icon: Icons.access_time, label: "DURATION", value: duration),
                _InfoColumn(icon: Icons.speed, label: "SPEED", value: speed),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B53F4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isUnlocking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Unlock Ride", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B53F4)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
} 
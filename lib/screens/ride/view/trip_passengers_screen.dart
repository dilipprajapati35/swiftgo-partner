import 'package:flutter/material.dart';
import 'package:flutter_arch/screens/homepage/view/ride_call_screen.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';
import 'package:flutter_arch/services/driver_location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Added for Timer
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  List<LatLng> _routePolyline = [];
  PolylinePoints polylinePoints = PolylinePoints();
  LatLng? _currentDriverLocation; // Add this to track driver's current location
  StreamSubscription<Position>? _positionStreamSubscription; // Add this for location stream

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
    _fetchRoutePolyline();
    _checkTripStatus(); // Check if trip is already unlocked
  }

  Future<void> _checkTripStatus() async {
    try {
      // First check if we have stored the unlock status locally
      String? storedStatus = await secureStorage.readSecureData('trip_${widget.tripId}_unlocked');
      if (storedStatus == 'true') {
        setState(() {
          _isTripUnlocked = true;
        });
        
        // Start location service if trip is unlocked
        if (_locationService == null) {
          final token = await secureStorage.readToken();
          if (token != null) {
            _locationService = DriverLocationService(driverToken: token);
            _locationService!.startSendingLocation();
            // Start live location tracking for map
            _startLiveLocationTracking();
          }
        }
        return;
      }
      
      // If not stored locally, check if trip is already started/unlocked by checking passenger status
      final passengers = await DioHttp().getTripPassengers(context, widget.tripId);
      
      // Check if any passenger has been processed (indicates trip was unlocked)
      bool hasProcessedPassengers = passengers.any((p) => p['status'] != null && 
          (p['status'].toString().toUpperCase() == 'ONGOING' || 
           p['status'].toString().toUpperCase() == 'NO_SHOW'));
      
      setState(() {
        _isTripUnlocked = hasProcessedPassengers;
      });
      
      // Store the status locally if trip is unlocked
      if (hasProcessedPassengers) {
        await secureStorage.writeSecureData('trip_${widget.tripId}_unlocked', 'true');
        
        // Start location service
        if (_locationService == null) {
          final token = await secureStorage.readToken();
          if (token != null) {
            _locationService = DriverLocationService(driverToken: token);
            _locationService!.startSendingLocation();
            // Start live location tracking for map
            _startLiveLocationTracking();
          }
        }
      }
    } catch (e) {
      // If there's an error, assume trip is not unlocked
      setState(() {
        _isTripUnlocked = false;
      });
    }
  }

  @override
  void dispose() {
    _locationService?.stopSendingLocation(); // Stop location updates
    _positionStreamSubscription?.cancel(); // Cancel location stream
    super.dispose();
  }

  // Start tracking driver's live location
  void _startLiveLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // Listen to location changes and update driver marker on map
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentDriverLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Move camera to follow driver
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentDriverLocation!),
        );
      }
    });
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
          // Start live location tracking for map
          _startLiveLocationTracking();
        }
        
        // Store the unlock status locally
        await secureStorage.writeSecureData('trip_${widget.tripId}_unlocked', 'true');
        
        await _fetchPassengers();
        setState(() { _isTripUnlocked = true; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlock ride')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlock ride. Please try again.')),
      );
    }
    setState(() { _isUnlocking = false; });
  }

  Future<void> _fetchRoutePolyline() async {
    final start = widget.startCoordinates;
    final end = widget.endCoordinates;
    const String googleAPIKey = 'AIzaSyCXvZ6f1LTP07lD6zhqnozAG20MzlUjis8';
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleAPIKey,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.status == 'OK' && result.points.isNotEmpty) {
      setState(() {
        _routePolyline = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      });
    } else {
      setState(() {
        _routePolyline = [
          LatLng(start.latitude, start.longitude),
          LatLng(end.latitude, end.longitude),
        ];
      });
    }
  }

  Set<Marker> _buildPassengerMarkers() {
    Set<Marker> markers = {};
    
    // Add driver marker if location is available
    if (_currentDriverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentDriverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver (You)', snippet: 'Current Location'),
      ));
    }
    
    // Add passenger markers
    final locations = _passengers;
    final passengerMarkers = locations.where((p) => (p['latitude'] ?? 0) != null && (p['longitude'] ?? 0) != null && p['latitude'] != null && p['longitude'] != null)
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
    
    markers.addAll(passengerMarkers);
    return markers;
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
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentDriverLocation ?? start, // Start with driver location if available
                      zoom: 13.5,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: Colors.blue,
                        width: 5,
                        points: _routePolyline.isNotEmpty ? _routePolyline : [start, end],
                      ),
                    },
                    markers: {
                      // Start marker
                      Marker(
                        markerId: const MarkerId('start'),
                        position: start,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Start'),
                      ),
                      // End/Destination marker
                      Marker(
                        markerId: const MarkerId('end'),
                        position: end,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: const InfoWindow(title: 'Destination'),
                      ),
                      // Driver and passenger markers
                      ..._buildPassengerMarkers(),
                    },
                    zoomControlsEnabled: false,
                    myLocationEnabled: false, // Disable default location to use custom driver marker
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
                            _PassengersListCard(
                              passengers: _passengers,
                              onPassengerStatusChanged: _fetchPassengers,
                            ),
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
                      child: _PassengersListCard(
                        passengers: _passengers,
                        onPassengerStatusChanged: _fetchPassengers,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PassengersListCard extends StatelessWidget {
  final List<Map<String, dynamic>> passengers;
  final VoidCallback? onPassengerStatusChanged;
  const _PassengersListCard({Key? key, required this.passengers, this.onPassengerStatusChanged}) : super(key: key);

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
                  return InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) => _PassengerDetailModal(passenger: p),
                      ).then((result) {
                        // Refresh passenger list if status was changed
                        if (result == 'refresh' && onPassengerStatusChanged != null) {
                          onPassengerStatusChanged!();
                        }
                      });
                    },
                    child: Row(
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
                              // Show status if available
                              if (p['status'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p['status'].toString().toUpperCase() == 'ONGOING' 
                                        ? Colors.green[100] 
                                        : p['status'].toString().toUpperCase() == 'NO_SHOW'
                                        ? Colors.red[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p['status'].toString().toUpperCase() == 'ONGOING' 
                                        ? 'Onboarded' 
                                        : p['status'].toString().toUpperCase() == 'NO_SHOW'
                                        ? 'No Show'
                                        : p['status'].toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: p['status'].toString().toUpperCase() == 'ONGOING' 
                                          ? Colors.green[800] 
                                          : p['status'].toString().toUpperCase() == 'NO_SHOW'
                                          ? Colors.red[800]
                                          : Colors.grey[800],
                                    ),
                                  ),
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
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PassengerDetailModal extends StatefulWidget {
  final Map<String, dynamic> passenger;
  const _PassengerDetailModal({Key? key, required this.passenger}) : super(key: key);

  @override
  State<_PassengerDetailModal> createState() => _PassengerDetailModalState();
}

class _PassengerDetailModalState extends State<_PassengerDetailModal> {
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.passenger['status']?.toString().toUpperCase();
  }

  Future<void> _onboardPassenger() async {
    setState(() { _isLoading = true; });
    try {
      final response = await DioHttp().onboardPassenger(context, widget.passenger['bookingId']);
      if (response.statusCode == 200) {
        setState(() { _status = 'ONGOING'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger onboarded!')),
        );
        // Close the modal and refresh the passenger list
        Navigator.of(context).pop('refresh');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to onboard passenger')),
      );
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _declinePassenger() async {
    setState(() { _isLoading = true; });
    try {
      final response = await DioHttp().declinePassenger(context, widget.passenger['bookingId']);
      if (response.statusCode == 200) {
        setState(() { _status = 'NO_SHOW'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger declined (no-show).')),
        );
        // Close the modal and refresh the passenger list
        Navigator.of(context).pop('refresh');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline passenger')),
      );
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passenger;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: p['passengerProfilePhotoUrl'] != null
                          ? NetworkImage(p['passengerProfilePhotoUrl'])
                          : null,
                      child: p['passengerProfilePhotoUrl'] == null
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['passengerName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        Row(
                          children: [
                            ...List.generate(4, (i) => Icon(Icons.star, color: Colors.blue, size: 20)),
                            Icon(Icons.star, color: Colors.grey[300], size: 20),
                            const SizedBox(width: 6),
                            Text('35 REVIEWS', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: const [
                    Text('DISTANCE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('0.2 mi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                Column(
                  children: const [
                    Text('TIME', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('8 min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RideCallScreen(),));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Call'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _status == 'ONGOING' ? Colors.green[100] : _status == 'NO_SHOW' ? Colors.red[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status == 'ONGOING' ? 'Onboarded' : _status == 'NO_SHOW' ? 'No Show' : _status!,
                  style: TextStyle(
                    color: _status == 'ONGOING' ? Colors.green[800] : _status == 'NO_SHOW' ? Colors.red[800] : Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            // Only show action buttons if passenger hasn't been processed yet
            if (_status == null || (_status != 'ONGOING' && _status != 'NO_SHOW'))
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onboardPassenger,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Onboard', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _declinePassenger,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Decline', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            // Show message when passenger has already been processed
            if (_status == 'ONGOING' || _status == 'NO_SHOW')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: _status == 'ONGOING' ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status == 'ONGOING' ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  _status == 'ONGOING' 
                      ? 'This passenger has already been onboarded' 
                      : 'This passenger was marked as no-show',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _status == 'ONGOING' ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
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
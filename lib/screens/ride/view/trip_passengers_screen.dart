
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_arch/screens/homepage/view/ride_call_screen.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:flutter_arch/services/socket_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';
import 'package:flutter_arch/services/driver_location_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class TripPassengersScreen extends StatefulWidget {
  final String tripId;
  final LatLngModel startCoordinates;
  final LatLngModel endCoordinates;
  final List<dynamic>? middleStops;
  const TripPassengersScreen({
    Key? key,
    required this.tripId,
    required this.startCoordinates,
    required this.endCoordinates,
    this.middleStops,
  }) : super(key: key);

  @override
  State<TripPassengersScreen> createState() => _TripPassengersScreenState();
}

class _TripPassengersScreenState extends State<TripPassengersScreen> {
  bool _isLoading = true;
  bool _isUnlocking = false;
  bool _isTripUnlocked = false;
  bool _isLoadingRoute = false; // Add route loading state
  List<Map<String, dynamic>> _passengers = [];
  GoogleMapController? _mapController;
  DriverLocationService? _locationService;
  final SocketService _socketService = SocketService(); // Keep socket service instance
  MySecureStorage secureStorage = MySecureStorage();
  List<LatLng> _routePolyline = [];
  PolylinePoints polylinePoints = PolylinePoints();
  LatLng? _currentDriverLocation;

  // --- REMOVED --- Redundant stream subscription
  // StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
    _fetchRoutePolyline();
    _checkTripStatus(); // Check if trip is already active
  }

  @override
  void dispose() {
    // --- UPDATED --- Clean up following official guide
    print('🚪 Cleaning up live tracking system...');
    
    // Step 1: Stop location broadcasting
    _locationService?.stopSendingLocation();
    _locationService = null;
    
    // Step 2: Leave driver room to clean up WebSocket resources
    _socketService.leaveDriverRoom(widget.tripId);
    
    print('✅ Live tracking cleanup completed.');
    super.dispose();
  }
  
  // --- UPDATED --- Centralized function to start location services following official guide
  void _startBroadcastingAndTracking() {
    print('🚀 Starting live tracking system following official guide...');
    
    // Step 1: Ensure socket is ready and initialize connection
    _socketService.initializeSocket(); 
    
    // Step 2: Join driver room for this specific trip
    _socketService.joinDriverRoom(widget.tripId);
    
    // Step 3: Notify that trip has started (enables canTrack: true for passengers)
    _socketService.notifyTripStarted(widget.tripId);
    
    // Step 4: Start location broadcasting service
    if (_locationService == null) {
      _locationService = DriverLocationService(
        tripId: widget.tripId,
        // This callback updates our local map UI
        onLocationUpdate: (LatLng newLocation) {
          if (mounted) {
            setState(() {
              _currentDriverLocation = newLocation;
            });
            // Animate camera to the new location
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(newLocation),
            );
          }
        },
      );
      // Start GPS broadcasting every 8 seconds via WebSocket
      _locationService!.startSendingLocation();
      
      print('✅ Live tracking system activated! Passengers can now track in real-time.');
    }
  }


  Future<void> _checkTripStatus() async {
    try {
      String? storedStatus =
          await secureStorage.readSecureData('trip_${widget.tripId}_unlocked');
      if (storedStatus == 'true') {
        print('🔄 Resuming active trip - re-enabling live tracking system...');
        if (mounted) {
          setState(() {
            _isTripUnlocked = true;
          });
          // --- UPDATED --- Resume live tracking following official guide
          _startBroadcastingAndTracking(); 
        }
      }
    } catch (e) {
      print("Error checking trip status from storage: $e");
    }
  }
  
  // --- REMOVED --- The entire _startLiveLocationTracking() method is no longer needed.
  // It has been replaced by the callback in `_startBroadcastingAndTracking`.
  
  Future<void> _fetchPassengers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final passengers =
          await DioHttp().getTripPassengers(context, widget.tripId);
      if (mounted) {
        setState(() {
          _passengers = passengers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load passengers')),
        );
      }
    }
  }

  Future<void> _unlockTrip() async {
    setState(() => _isUnlocking = true);
    try {
      print('🚗 Driver tapping "Unlock Ride" button - following official guide...');
      
      // ✨ Step 1 from Official Guide: Call the Smart API Endpoint
      // POST /driver/trips/{tripId}/start
      final response = await DioHttp().startTrip(context, widget.tripId);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Trip status updated to ACTIVE in database');
        print('📲 Push notifications sent to all passengers on this trip');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride unlocked! Live tracking enabled. Passengers notified.')),
          );
        }

        // ✨ Step 2 from Official Guide: Start Live WebSocket Broadcasting
        // This enables real-time tracking for passengers
        _startBroadcastingAndTracking();

        // Step 3: Save trip status for persistence across app restarts
        await secureStorage.writeSecureData('trip_${widget.tripId}_unlocked', 'true');

        await _fetchPassengers();
        if (mounted) {
          setState(() {
            _isTripUnlocked = true;
          });
        }
      } else {
        print('❌ Failed to start trip - API returned ${response.statusCode}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to unlock ride')),
          );
        }
      }
    } catch (e) {
      print('❌ Error starting trip: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlock ride. Please try again.')),
        );
      }
    }
    if (mounted) {
      setState(() => _isUnlocking = false);
    }
  }

  Future<void> _fetchRoutePolyline() async {
    setState(() => _isLoadingRoute = true);
    
    final start = widget.startCoordinates;
    final end = widget.endCoordinates;
    
    print('🗺️ Fetching accurate road route from (${start.latitude}, ${start.longitude}) to (${end.latitude}, ${end.longitude})');
    
    // TODO: Replace with your actual Google Maps API key
    // Get your API key from: https://console.cloud.google.com/google/maps-apis/credentials
    const String googleAPIKey = 'AIzaSyCXvZ6f1LTP07lD6zhqnozAG20MzlUjis8'; // Replace with your actual API key
    
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleAPIKey,
        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(end.latitude, end.longitude),
          mode: TravelMode.driving,
          wayPoints: [], // Add waypoints if needed
          avoidHighways: false,
          avoidTolls: false,
          avoidFerries: true,
          optimizeWaypoints: true,
        ),
      );
      
      if (mounted && result.status == 'OK' && result.points.isNotEmpty) {
        print('✅ Route fetched successfully with ${result.points.length} points');
        setState(() {
          _routePolyline = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
          _isLoadingRoute = false;
        });
        
        // Auto-fit camera to show the entire route
        _fitCameraToRoute();
      } else {
        print('⚠️ Route API failed: ${result.status} - ${result.errorMessage}');
        // Fallback to straight line if API fails
        if (mounted) {
          setState(() {
            _routePolyline = [
              LatLng(start.latitude, start.longitude),
              LatLng(end.latitude, end.longitude),
            ];
            _isLoadingRoute = false;
          });
        }
        
        // Show user feedback about route issue
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to fetch detailed route. Showing direct path. (${result.status})'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error fetching route: $e');
      // Fallback to straight line on error
      if (mounted) {
        setState(() {
          _routePolyline = [
            LatLng(start.latitude, start.longitude),
            LatLng(end.latitude, end.longitude),
          ];
          _isLoadingRoute = false;
        });
      }
      
      // Show user feedback about error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading route. Showing direct path.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Auto-fit camera to show the entire route with padding
  void _fitCameraToRoute() {
    if (_mapController == null || _routePolyline.isEmpty) return;
    
    try {
      // Calculate bounds from all route points
      double minLat = _routePolyline.first.latitude;
      double maxLat = _routePolyline.first.latitude;
      double minLng = _routePolyline.first.longitude;
      double maxLng = _routePolyline.first.longitude;
      
      for (LatLng point in _routePolyline) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
      
      // Create bounds with some padding
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      // Animate camera to show the entire route
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          100.0, // Padding around the route
        ),
      );
      
      print('📍 Camera fitted to show entire route');
    } catch (e) {
      print('Error fitting camera to route: $e');
    }
  }

  // Helper: get all stops from the trip (from API response), fallback to widget values if not available
  List<Map<String, dynamic>>? _getStops() {
    if (_passengers.isNotEmpty && _passengers[0]['tripStops'] is List) {
      final stops = List<Map<String, dynamic>>.from(_passengers[0]['tripStops'] ?? []);
      if (stops.isNotEmpty) return stops;
    }
    return null;
  }

  // Helper: get middle stops from widget parameter if provided, else from API stops
  List<dynamic> _getMiddleStops() {
    if (widget.middleStops != null && widget.middleStops!.isNotEmpty) {
      return widget.middleStops!;
    }
    final stops = _getStops();
    if (stops != null && stops.length > 2) {
      return stops.sublist(1, stops.length - 1);
    }
    return [];
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    final stops = _getStops();
    // Pickup marker (first stop from stops if available, else widget)
    if (stops != null && stops.isNotEmpty) {
      final pickup = stops.first;
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: LatLng((pickup['latitude'] ?? 0).toDouble(), (pickup['longitude'] ?? 0).toDouble()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: 'Route Start • ${_routePolyline.isNotEmpty ? "${_routePolyline.length} points" : "Direct line"}',
        ),
      ));
      // Destination marker (last stop)
      final destination = stops.last;
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: LatLng((destination['latitude'] ?? 0).toDouble(), (destination['longitude'] ?? 0).toDouble()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: 'Route End • Tap to view details',
        ),
      ));
    } else {
      // Fallback: use widget.startCoordinates and widget.endCoordinates
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: LatLng(widget.startCoordinates.latitude, widget.startCoordinates.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: 'Route Start • ${_routePolyline.isNotEmpty ? "${_routePolyline.length} points" : "Direct line"}',
        ),
      ));
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: LatLng(widget.endCoordinates.latitude, widget.endCoordinates.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: 'Route End • Tap to view details',
        ),
      ));
    }
    // Middle stops (from widget.middleStops if provided, else from stops)
    final middleStops = _getMiddleStops();
    for (int i = 0; i < middleStops.length; i++) {
      final stop = middleStops[i];
      double lat = 0, lng = 0;
      String? stopName;
      if (stop is Map<String, dynamic>) {
        lat = (stop['latitude'] ?? 0).toDouble();
        lng = (stop['longitude'] ?? 0).toDouble();
        stopName = stop['name']?.toString();
      } else if (stop is LatLngModel) {
        lat = stop.latitude;
        lng = stop.longitude;
      } else if (stop.runtimeType.toString().contains('StopModel')) {
        // Handle StopModel via reflection (forwards compatibility)
        try {
          lat = stop.latitude?.toDouble() ?? 0;
          lng = stop.longitude?.toDouble() ?? 0;
          stopName = stop.name?.toString();
        } catch (_) {}
      }
      markers.add(Marker(
        markerId: MarkerId('middle_stop_${i+1}'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Middle Stop',
          snippet: stopName != null ? stopName : 'Stop ${i+1}',
        ),
      ));
    }
    // Driver marker (if available)
    if (_currentDriverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentDriverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Current Location',
          snippet: 'Live tracking active',
        ),
      ));
    }
    // Passenger markers (unchanged)
    final passengerMarkers = _passengers
        .where((p) => p['latitude'] != null && p['longitude'] != null)
        .map((p) {
      return Marker(
        markerId: MarkerId(p['bookingId']?.toString() ?? UniqueKey().toString()),
        position: LatLng(
          p['latitude'],
          p['longitude'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: p['name'] ?? 'Passenger',
          snippet: p['pickupStopName'] ?? '',
        ),
      );
    });
    markers.addAll(passengerMarkers);
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Fit camera to route once map is ready
                    if (_routePolyline.isNotEmpty) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _fitCameraToRoute();
                      });
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentDriverLocation ?? LatLng(widget.startCoordinates.latitude, widget.startCoordinates.longitude),
                    zoom: 13.5,
                  ),
                  polylines: {
                    if (_routePolyline.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('route'),
                        color: const Color(0xFF3B53F4), // Match app theme color
                        width: 6,
                        points: _routePolyline,
                        patterns: [], // Solid line
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                        geodesic: true, // Follow Earth's curvature for accuracy
                      ),
                  },
                  // --- UPDATED --- Simplified marker building
                  markers: _buildMarkers(), 
                  zoomControlsEnabled: false,
                  myLocationEnabled: false, // We use our custom marker instead
                  myLocationButtonEnabled: true,
                ),
                DraggableScrollableSheet(
                  initialChildSize: _isTripUnlocked ? 0.3 : 0.45,
                  minChildSize: _isTripUnlocked ? 0.15 : 0.45,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: _isTripUnlocked
                          ? _buildPassengerList(scrollController)
                          : _buildUnlockCard(scrollController),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 80), // Account for app bar
          if (_routePolyline.isNotEmpty) ...[
            FloatingActionButton(
              onPressed: _fitCameraToRoute,
              backgroundColor: const Color(0xFF3B53F4),
              heroTag: "center_route",
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
              tooltip: 'Center on Route',
              mini: true,
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: _isLoadingRoute ? null : _fetchRoutePolyline,
              backgroundColor: _isLoadingRoute ? Colors.grey : Colors.orange,
              heroTag: "refresh_route",
              child: _isLoadingRoute 
                  ? const SizedBox(
                      width: 20, 
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              tooltip: _isLoadingRoute ? 'Loading Route...' : 'Refresh Route',
              mini: true,
            ),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  Widget _buildUnlockCard(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _UnlockRideCard(
          pickupAddress: _passengers.isNotEmpty
              ? (_passengers[0]['pickupStopName'] ?? 'Pickup Address')
              : 'Pickup Address',
          distance: '25 km',
          duration: '10 min',
          speed: '45 kph',
          onUnlock: !_isUnlocking ? _unlockTrip : null,
          isUnlocking: _isUnlocking,
        ),
        const SizedBox(height: 16),
        if (_passengers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Passengers for Identification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_passengers.length} passenger${_passengers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _PreTripPassengerList(passengers: _passengers),
        ],
      ],
    );
  }

  Widget _buildPassengerList(ScrollController scrollController) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trip Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_passengers.length} passenger${_passengers.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _PassengersListCard(
                passengers: _passengers,
                onPassengerStatusChanged: _fetchPassengers,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// Pre-trip passenger list for identification purposes
class _PreTripPassengerList extends StatelessWidget {
  final List<Map<String, dynamic>> passengers;
  
  const _PreTripPassengerList({Key? key, required this.passengers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: passengers.map((passenger) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: passenger['passengerProfilePhotoUrl'] != null
                        ? NetworkImage(passenger['passengerProfilePhotoUrl'])
                        : null,
                    child: passenger['passengerProfilePhotoUrl'] == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passenger['passengerName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passenger['pickupStopName'] ?? 'Pickup location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      passenger['status']?.toString().toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// --- The rest of the file (_PassengersListCard, _PassengerDetailModal, _UnlockRideCard, _InfoColumn) remains unchanged ---
// --- Paste the full original code for the helper widgets below this line ---

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
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All passengers have been processed',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can continue with the trip',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
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
      if (mounted && (response.statusCode == 200 || response.statusCode == 201)) {
        setState(() { _status = 'ONGOING'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger onboarded!')),
        );
        Navigator.of(context).pop('refresh');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to onboard passenger')),
        );
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _declinePassenger() async {
    setState(() { _isLoading = true; });
    try {
      final response = await DioHttp().declinePassenger(context, widget.passenger['bookingId']);
      if (mounted && (response.statusCode == 200 || response.statusCode == 201)) {
        setState(() { _status = 'NO_SHOW'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger declined (no-show).')),
        );
        Navigator.of(context).pop('refresh');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline passenger')),
        );
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RideCallScreen()));
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
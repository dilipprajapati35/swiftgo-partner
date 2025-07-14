import 'package:flutter/material.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';

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
  List<Map<String, dynamic>> _passengers = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
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

  Future<void> _unlockBooking(String bookingId) async {
    setState(() { _isUnlocking = true; });
    try {
      final response = await DioHttp().unlockBooking(context, bookingId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride unlocked!')),
        );
        await _fetchPassengers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlock ride')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlock ride')),
      );
    }
    setState(() { _isUnlocking = false; });
  }

  Set<Marker> _buildPassengerMarkers() {
    return _passengers.where((p) => p['pickupLocation'] != null).map((p) {
      final loc = p['pickupLocation'];
      return Marker(
        markerId: MarkerId(p['bookingId'] ?? p['name'] ?? ''),
        position: LatLng(
          (loc['latitude'] ?? 0).toDouble(),
          (loc['longitude'] ?? 0).toDouble(),
        ),
        infoWindow: InfoWindow(title: p['name'] ?? 'Passenger'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
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
          : Column(
              children: [
                SizedBox(
                  height: 260,
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
                  ),
                ),
                Expanded(
                  child: _passengers.isEmpty
                      ? const Center(child: Text('No passengers found.'))
                      : ListView.separated(
                          itemCount: _passengers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _passengers[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(p['name'] ?? 'Unknown'),
                              subtitle: Text('Status: ${p['status'] ?? '-'}'),
                              trailing: (p['status'] == 'CONFIRMED')
                                  ? ElevatedButton(
                                      onPressed: _isUnlocking ? null : () => _unlockBooking(p['bookingId']),
                                      child: _isUnlocking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Unlock Ride'),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 
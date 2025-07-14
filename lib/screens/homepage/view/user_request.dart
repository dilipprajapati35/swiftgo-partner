import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_call_screen.dart';

class UserRequestScreen extends StatefulWidget {
  const UserRequestScreen({Key? key}) : super(key: key);

  @override
  State<UserRequestScreen> createState() => _UserRequestScreenState();
}

class _UserRequestScreenState extends State<UserRequestScreen> {
  GoogleMapController? _mapController;

  // Example coordinates (New York)
  final LatLng _origin = const LatLng(40.7138, -74.0060);
  final LatLng _destination = const LatLng(40.7074, -74.0113);

  List<LatLng> get _polylinePoints => [
    _origin,
    const LatLng(40.7110, -74.0080),
    _destination,
  ];

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map background
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (_origin.latitude + _destination.latitude) / 2,
                  (_origin.longitude + _destination.longitude) / 2,
                ),
                zoom: 15.0,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  width: 6,
                  points: _polylinePoints,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('origin'),
                  position: _origin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position: _destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
          // Top card with locations
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radio_button_checked, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('My current location', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('105 William St, Chicago, US', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom card with driver info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  // Driver avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/images/avatar.png'), // Replace with your asset
                  ),
                  const SizedBox(width: 12),
                  // Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Ronnie Frank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(5, (index) => Icon(Icons.star, color: Colors.blue, size: 16)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('35 REVIEWS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _infoColumn('DISTANCE', '0.2 mi'),
                            const SizedBox(width: 16),
                            _infoColumn('TIME', '8 min'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Call button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RideCallScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Call', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
} 
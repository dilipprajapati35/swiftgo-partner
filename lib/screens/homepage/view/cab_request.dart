import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CabRequestScreen extends StatefulWidget {
  const CabRequestScreen({Key? key}) : super(key: key);

  @override
  State<CabRequestScreen> createState() => _CabRequestScreenState();
}

class _CabRequestScreenState extends State<CabRequestScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(19.0760, 72.8777); // Mumbai as default

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
                target: _center,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
          // Top address/search bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '311 Nitzsche Points Suite 259',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.close),
                ],
              ),
            ),
          ),
          // Central marker with circle and dots (mockup)
          Positioned.fill(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.navigation, color: Colors.blue, size: 48),
                  ),
                  // Example: other blue dots (mockup, not interactive)
                  ..._buildMapDots(),
                ],
              ),
            ),
          ),
          // Bottom card with drivers
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDriverTile(
                    name: 'Ronnie Frank',
                    car: 'Mercedes-Benz',
                    rating: 5,
                    distance: '0.5 mi',
                  ),
                  _buildDriverTile(
                    name: 'Luke Hoffman',
                    car: 'Rolls Royce',
                    rating: 5,
                    distance: '0.7 mi',
                  ),
                  _buildDriverTile(
                    name: 'Bobby Lyons',
                    car: 'Volkswagen',
                    rating: 5,
                    distance: '0.77 mi',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mockup for blue dots on the map
  List<Widget> _buildMapDots() {
    return [
      Positioned(
        left: 40,
        top: 60,
        child: _mapDot(),
      ),
      Positioned(
        right: 50,
        top: 80,
        child: _mapDot(),
      ),
      Positioned(
        left: 80,
        bottom: 60,
        child: _mapDot(),
      ),
      Positioned(
        right: 70,
        bottom: 90,
        child: _mapDot(),
      ),
    ];
  }

  Widget _mapDot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildDriverTile({
    required String name,
    required String car,
    required int rating,
    required String distance,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(car),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.blue, size: 16)),
          ),
          const SizedBox(height: 4),
          Text(distance, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 
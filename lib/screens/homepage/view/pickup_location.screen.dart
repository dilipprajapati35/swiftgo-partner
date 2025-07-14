import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/app_primary_button.dart';
import 'package:flutter_arch/common/enums/trip_type.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_fonts/google_fonts.dart';

enum FavoriteType { home, work, other }

class PickupLocationPage extends StatefulWidget {
  const PickupLocationPage({super.key, required this.isPickup, this.initialAddress});
  final bool isPickup;
  final String? initialAddress;

  @override
  State<PickupLocationPage> createState() => _PickupLocationPageState();
}

class _PickupLocationPageState extends State<PickupLocationPage> {
  GoogleMapController? _mapController;
  LatLng _currentMapCenter =
      const LatLng(19.0760, 72.8777); // Example: Mumbai

  // Add trip type state
  TripType _selectedTrip = TripType.oneWay;

  // State for the "Save as Favorite" modal
  FavoriteType _selectedFavoriteType = FavoriteType.other; // Default selection
  final TextEditingController _otherFavoriteNameController =
      TextEditingController();

  final List<Map<String, dynamic>> _locationSuggestions = [];
  
  // New state variables for pickup and destination
  String? _selectedPickupAddress;
  String? _selectedDestinationAddress;
  LatLng? _selectedPickupLatLng;
  LatLng? _selectedDestinationLatLng;
  bool _isSelectingPickup = true; // Track which location we're selecting
  
  // Real-time location selection variables
  String _currentMapAddress = "Loading address...";
  bool _isLoadingAddress = false;
  bool _isGettingCurrentLocation = false;
  
  // Separate state for pickup and destination
  String? _pickupAddress;
  String? _destinationAddress;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  bool _isLoadingPickupAddress = false;
  bool _isLoadingDestinationAddress = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing values if provided
    _selectedPickupAddress = widget.initialAddress;
    _selectedDestinationAddress = null;
    
    // Clear and add suggestions with proper data
    _locationSuggestions.clear();
    _locationSuggestions.addAll([
      {
        "address": "Lanco Hills",
        "isOrigin": true,
        "isFavorite": false,
        "favoriteType": null,
        "favoriteName": null,
      },
      {
        "address": "Wipro Circle",
        "isOrigin": false,
        "isFavorite": false,
        "favoriteType": null,
        "favoriteName": null,
      },
    ]);
    
    // Get initial address for the map center
    _getAddressFromCoordinates(_currentMapCenter);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _otherFavoriteNameController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // You might want to style the map here if needed
    // controller.setMapStyle(_mapStyleJson); // If you have a JSON map style
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
  }

  void _onCameraIdle() {
    // Called when the camera movement has ended.
    // Fetch address for _currentMapCenter here
    log("Map moved to: $_currentMapCenter");
    _getAddressFromCoordinates(_currentMapCenter);
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    if (_isLoadingAddress) return;
    
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _formatAddress(place);
        
        setState(() {
          _currentMapAddress = address;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _currentMapAddress = "Address not found";
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentMapAddress = "Error getting address";
        _isLoadingAddress = false;
      });
      print('Error getting address: $e');
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    
    return addressParts.join(', ');
  }

  void _selectLocation(String address, LatLng latLng) {
    if (_isSelectingPickup) {
      setState(() {
        _selectedPickupAddress = address;
        _selectedPickupLatLng = latLng;
        _pickupAddress = address;
        _pickupLatLng = latLng;
        _isSelectingPickup = false; // Switch to destination selection
      });
      toast("Pickup location selected. Now select destination.");
    } else {
      setState(() {
        _selectedDestinationAddress = address;
        _selectedDestinationLatLng = latLng;
        _destinationAddress = address;
        _destinationLatLng = latLng;
      });
      toast("Destination selected. Both locations are ready!");
    }
  }

  void _selectCurrentMapLocation() {
    if (_isLoadingAddress || _currentMapAddress == "Loading address..." || _currentMapAddress == "Address not found" || _currentMapAddress == "Error getting address") {
      toast("Please wait for address to load or move the map to a different location");
      return;
    }
    
    _selectLocation(_currentMapAddress, _currentMapCenter);
  }

  void _selectPickupFromMap() {
    if (_isLoadingAddress || _currentMapAddress == "Loading address..." || _currentMapAddress == "Address not found" || _currentMapAddress == "Error getting address") {
      toast("Please wait for address to load or move the map to a different location");
      return;
    }
    
    setState(() {
      _selectedPickupAddress = _currentMapAddress;
      _selectedPickupLatLng = _currentMapCenter;
      _pickupAddress = _currentMapAddress;
      _pickupLatLng = _currentMapCenter;
      _isSelectingPickup = false; // Switch to destination selection
    });
    toast("Pickup location selected. Now select destination.");
  }

  void _selectDestinationFromMap() {
    if (_isLoadingAddress || _currentMapAddress == "Loading address..." || _currentMapAddress == "Address not found" || _currentMapAddress == "Error getting address") {
      toast("Please wait for address to load or move the map to a different location");
      return;
    }
    
    setState(() {
      _selectedDestinationAddress = _currentMapAddress;
      _selectedDestinationLatLng = _currentMapCenter;
      _destinationAddress = _currentMapAddress;
      _destinationLatLng = _currentMapCenter;
    });
    toast("Destination selected. Both locations are ready!");
  }

  String _getBottomButtonText() {
    if (_pickupAddress == null) {
      return "Select Pickup Location";
    } else if (_destinationAddress == null) {
      return "Select Destination Location";
    } else {
      return "Confirm Both Locations";
    }
  }

  VoidCallback _getBottomButtonAction() {
    if (_pickupAddress == null) {
      return _selectPickupFromMap;
    } else if (_destinationAddress == null) {
      return _selectDestinationFromMap;
    } else {
      return _confirmLocations;
    }
  }

  void _changePickupLocation() {
    setState(() {
      _pickupAddress = null;
      _pickupLatLng = null;
      _selectedPickupAddress = null;
      _selectedPickupLatLng = null;
    });
  }

  void _changeDestinationLocation() {
    setState(() {
      _destinationAddress = null;
      _destinationLatLng = null;
      _selectedDestinationAddress = null;
      _selectedDestinationLatLng = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingCurrentLocation) return;
    
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        toast("Location services are disabled. Please enable location services.");
        setState(() {
          _isGettingCurrentLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          toast("Location permission denied");
          setState(() {
            _isGettingCurrentLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        toast("Location permissions are permanently denied. Please enable in settings.");
        setState(() {
          _isGettingCurrentLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentMapCenter = currentLocation;
        _isGettingCurrentLocation = false;
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 15.0),
        );
      }

      // Get address for current location
      _getAddressFromCoordinates(currentLocation);
      
      toast("Current location updated");
      
    } catch (e) {
      setState(() {
        _isGettingCurrentLocation = false;
      });
      toast("Error getting current location: $e");
      print('Error getting current location: $e');
    }
  }

  void _confirmLocations() {
    if (_selectedPickupAddress == null || _selectedDestinationAddress == null) {
      toast("Please select both pickup and destination locations");
      return;
    }

    if (_selectedPickupLatLng == null || _selectedDestinationLatLng == null) {
      toast("Location coordinates are required");
      return;
    }

    // Return both locations to the calling page
    Navigator.pop(context, {
      'pickupAddress': _selectedPickupAddress,
      'destinationAddress': _selectedDestinationAddress,
      'pickupLatLng': _selectedPickupLatLng,
      'destinationLatLng': _selectedDestinationLatLng,
      'tripType': _selectedTrip,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyWhite,
      appBar: _buildAppBar(context),
      bottomSheet: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: 12,
              left: 20,
              right: 20,
              top: 12
              ),
              child: AppPrimaryButton(
            text: _getBottomButtonText(),
            onTap: _getBottomButtonAction(),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Add the round trip / one-way radio button row here
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Row(
                  children: [
                    Radio<TripType>(
                      value: TripType.roundTrip,
                      groupValue: _selectedTrip,
                      onChanged: (TripType? value) {
                        setState(() {
                          _selectedTrip = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text(
                      'Round trip',
                      style: GoogleFonts.nunito(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 20),
                    Radio<TripType>(
                      value: TripType.oneWay,
                      groupValue: _selectedTrip,
                      onChanged: (TripType? value) {
                        setState(() {
                          _selectedTrip = value!;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text(
                      'One-way trip',
                      style: GoogleFonts.nunito(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              
              
              
              // Show location rows based on trip type
              if (_selectedTrip == TripType.roundTrip) ...[
                // Pickup location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _pickupAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _pickupAddress == null,
                  onTap: _pickupAddress == null ? _selectPickupFromMap : _changePickupLocation,
                  pickup: true,
                  isSelected: _pickupAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
                7.height,
                // Destination location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _destinationAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _destinationAddress == null,
                  onTap: _destinationAddress == null ? _selectDestinationFromMap : _changeDestinationLocation,
                  pickup: false,
                  isSelected: _destinationAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
                7.height,
                // Return pickup location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _pickupAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _pickupAddress == null,
                  onTap: _pickupAddress == null ? _selectPickupFromMap : null,
                  pickup: true,
                  isSelected: _pickupAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
                7.height,
                // Return destination location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _destinationAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _destinationAddress == null,
                  onTap: _destinationAddress == null ? _selectDestinationFromMap : null,
                  pickup: false,
                  isSelected: _destinationAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
                12.height,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Enter time ',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF132235),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      4.height,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xffE9F0F7)),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '00:00 AM',
                            hintStyle: GoogleFonts.nunito(
                              color: const Color(0xFF6C7A9C),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Pickup location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _pickupAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _pickupAddress == null,
                  onTap: _pickupAddress == null ? _selectPickupFromMap : _changePickupLocation,
                  pickup: true,
                  isSelected: _pickupAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
                7.height,
                // Destination location (selected or current map)
                _buildLocationItem(
                  context: context,
                  address: _destinationAddress ?? _currentMapAddress,
                  isLoading: _isLoadingAddress && _destinationAddress == null,
                  onTap: _destinationAddress == null ? _selectDestinationFromMap : _changeDestinationLocation,
                  pickup: false,
                  isSelected: _destinationAddress != null,
                ).paddingSymmetric(horizontal: 16, vertical: 0),
              ],
              // Map takes the remaining space
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentMapCenter,
                        zoom: 15.0,
                      ),
                      myLocationButtonEnabled:
                          true, // Shows the "My Location" button
                      myLocationEnabled:
                          true, // Shows the blue dot for current location (requires permission)
                      zoomControlsEnabled: true, // Shows zoom + / - buttons
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                    ),
                    IgnorePointer(
                      child: Image.asset(
                        AppAssets.pin,
                        height: 29,
                      ),
                    ),
                    // Custom current location button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: "currentLocation",
                        onPressed: _getCurrentLocation,
                        backgroundColor: AppColor.buttonColor,
                        child: _isGettingCurrentLocation
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom home indicator like bar
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 60, // Center it
            right: MediaQuery.of(context).size.width / 2 - 60,
            bottom: 8,
            child: Container(
              height: 5,
              width: 120,
              decoration: BoxDecoration(
                color: AppColor.greyShade5.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Or AppColor.greyWhite
        statusBarIconBrightness: Brightness.dark, // For dark icons
      ),
      backgroundColor: AppColor.greyWhite,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: AppColor.greyShade1),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isSelectingPickup ? "Select Pickup Location" : "Select Destination Location", 
        style: AppStyle.title3
      ),
      centerTitle: false, // Aligns title to the left of center (after leading)
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Image.asset(
            AppAssets.logoSmall, // Use logoSmall as it fits better in AppBar
            height: 24, // Adjust as needed
          ),
        ),
      ],
    );
  }

  void _handleFavoriteTap(int index) {
    final suggestion = _locationSuggestions[index];
    if (suggestion['isFavorite']) {
      // It's already a favorite, so unfavorite it
      setState(() {
        suggestion['isFavorite'] = false;
        suggestion['favoriteType'] = null;
        suggestion['favoriteName'] = null;
      });
      toast("${suggestion['address']} removed from favorites.");
      // Add API call here to update backend if necessary
    } else {
      // Not a favorite, show the modal to save it
      // Reset modal state before showing
      _selectedFavoriteType =
          FavoriteType.other; // Default to 'Other' or first option
      _otherFavoriteNameController.clear();
      _showSaveAsFavoriteModal(context, index);
    }
  }

  Widget _buildLocationItem({
    required BuildContext context,
    required String address,
    required bool isLoading,
    required VoidCallback? onTap,
    required bool pickup,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.buttonColor.withOpacity(0.1) : AppColor.greyWhite,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColor.buttonColor : AppColor.greyShade6,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.greyShade5.withOpacity(0.6),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              pickup ? AppAssets.pickupLocation : AppAssets.destination,
              height: 24,
              width: 24,
            ),
            6.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? "Loading address..." : (pickup ? "Pickup location" : "Destination location"),
                    style: AppStyle.caption1w400.copyWith(
                      color: AppColor.greyShade3,
                      fontSize: 12,
                    ),
                  ),
                  2.height,
                  Text(
                    address,
                    style: AppStyle.subheading.copyWith(
                        color: AppColor.greyShade1,
                        fontSize: 16,
                        height: 21 / 16,
                        letterSpacing: 0),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            12.width,
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.buttonColor,
                ),
              )
            else if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColor.buttonColor,
                size: 22,
              )
            else
              Icon(
                Icons.my_location,
                color: AppColor.buttonColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMapLocationItem({
    required BuildContext context,
    required String address,
    required bool isLoading,
    required VoidCallback onTap,
    required bool pickup,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: AppColor.greyWhite,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColor.greyShade6,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.greyShade5.withOpacity(0.6),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              pickup ? AppAssets.pickupLocation : AppAssets.destination,
              height: 24,
              width: 24,
            ),
            6.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? "Loading address..." : (_isSelectingPickup ? "Pickup location" : "Destination location"),
                    style: AppStyle.caption1w400.copyWith(
                      color: AppColor.greyShade3,
                      fontSize: 12,
                    ),
                  ),
                  2.height,
                  Text(
                    address,
                    style: AppStyle.subheading.copyWith(
                        color: AppColor.greyShade1,
                        fontSize: 16,
                        height: 21 / 16,
                        letterSpacing: 0),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            12.width,
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.buttonColor,
                ),
              )
            else
              Icon(
                Icons.my_location,
                color: AppColor.buttonColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSuggestionItem({
    required BuildContext context,
    required String address,
    // required Color dotColor, // Replaced by pickup/destination asset
    required bool isFavorite,
    required VoidCallback onTap,
    // required VoidCallback onFavoriteTap, // Replaced by _handleFavoriteTap(index)
    required int
        itemIndex, // Pass index to identify which item is being favorited
    required bool pickup,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Min height to ensure consistent row height even with no vertical padding
        constraints: const BoxConstraints(minHeight: 50), // Adjust as needed
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 0), // Added some vertical padding
        decoration: BoxDecoration(
          color: AppColor.greyWhite,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColor
                .greyShade6, // Make sure AppColor.greyShade6 is defined
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.greyShade5.withOpacity(0.6),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              pickup ? AppAssets.pickupLocation : AppAssets.destination,
              height: 24,
              width: 24,
            ),
            6.width,
            Expanded(
              child: Text(
                address,
                style: AppStyle.subheading.copyWith(
                    color: AppColor.greyShade1,
                    fontSize: 16,
                    height: 21 / 16,
                    letterSpacing: 0),
                overflow: TextOverflow.ellipsis,
                maxLines: 1, // Ensure it doesn't wrap excessively
              ),
            ),
            12.width,
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : AppColor.greyShade3,
                size: 22,
              ),
              onPressed: () =>
                  _handleFavoriteTap(itemIndex), // Use the new handler
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          ],
        ),
      ),
    );
  }
  // In _PickupLocationPageState

  // In _PickupLocationPageState

  void _showSaveAsFavoriteModal(BuildContext pageContext, int suggestionIndex) {
    final suggestion = _locationSuggestions[suggestionIndex];
    final String address =
        'Plot No. 9, Lanco Hills, Near State Bank of india, Shivapuri Colony, Mupps Panchavati Colony, Manikonda, Hyderabad ';
    // final String address = suggestion['address'];

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled:
          true, // Important for content that might exceed half screen
      backgroundColor:
          Colors.transparent, // Make sheet transparent for custom shape
      builder: (BuildContext modalContext) {
        // Use StatefulBuilder to manage state within the modal (like radio button selection)
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              // Padding to avoid keyboard overlap
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        top: 75), // Space for the close button
                    padding: const EdgeInsets.all(16.0).copyWith(
                        top: 20), // Top padding for content below close button
                    decoration: const BoxDecoration(
                      color: AppColor.greyWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      // In case content overflows
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Save as favourite",
                            style: AppStyle.title3
                                .copyWith(fontSize: 20), // Using existing style
                          ),
                          12.height,
                          Text(
                            address,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.subheading,
                          ),
                          20.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            // crossAxisAlignment: CrossAxisAlignment.start,
                            children: FavoriteType.values.map((type) {
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedFavoriteType = type;
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Radio<FavoriteType>(
                                        value: type,
                                        groupValue: _selectedFavoriteType,
                                        onChanged: (FavoriteType? value) {
                                          if (value != null) {
                                            setModalState(() {
                                              _selectedFavoriteType = value;
                                            });
                                          }
                                        },
                                        activeColor: AppColor.buttonColor,
                                      ),
                                      Text(
                                        type
                                            .toString()
                                            .split('.')
                                            .last
                                            .capitalizeFirstLetter()!,
                                        style: AppStyle.body.copyWith(
                                            color: AppColor.greyShade1,
                                            fontSize: 15,
                                            fontWeight:
                                                _selectedFavoriteType == type
                                                    ? FontWeight.bold
                                                    : FontWeight.normal),
                                      ),
                                      const Spacer(), // Pushes next radio to right
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_selectedFavoriteType == FavoriteType.other) ...[
                            20.height,
                            TextFormField(
                              controller: _otherFavoriteNameController,
                              style: AppStyle.body.copyWith(
                                  color: AppColor.greyShade1, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "Name your favorite (Ex. Gym)",
                                labelText: "Other",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                hintStyle: AppStyle.greyTextField
                                    .copyWith(fontSize: 15),
                                prefixIcon: Icon(Icons.favorite,
                                    color: AppColor.buttonColor, size: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide:
                                      BorderSide(color: AppColor.greyShade5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide:
                                      BorderSide(color: AppColor.greyShade5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                      color: AppColor.buttonColor, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                          30.height,
                          AppPrimaryButton(
                            text: "Save",
                            onTap: () {
                              // Logic to save the favorite
                              setState(() {
                                // This setState is for the main page
                                final favSuggestion =
                                    _locationSuggestions[suggestionIndex];
                                favSuggestion['isFavorite'] = true;
                                favSuggestion['favoriteType'] =
                                    _selectedFavoriteType;
                                if (_selectedFavoriteType ==
                                    FavoriteType.other) {
                                  favSuggestion['favoriteName'] =
                                      _otherFavoriteNameController.text.trim();
                                  if (favSuggestion['favoriteName'].isEmpty) {
                                    toast(
                                        "Please enter a name for 'Other' favorite.",
                                        bgColor: Colors.red);
                                    return;
                                  }
                                } else {
                                  favSuggestion['favoriteName'] = null;
                                }
                              });
                              toast(
                                  "Saved as favorite: ${suggestion['address']}");
                              Navigator.pop(
                                  pageContext); // Close the modal sheet
                              // Add API call here
                            },
                          ),
                          10.height, // For bottom safe area if any
                        ],
                      ),
                    ),
                  ),
                  // Close ('X') button positioned on top of the sheet
                  Positioned(
                    top: 0,
                    child: InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color:
                                AppColor.greyShade1, // Dark background for 'X'
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2))
                            ]),
                        child: const Icon(Icons.close,
                            color: AppColor.greyWhite, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

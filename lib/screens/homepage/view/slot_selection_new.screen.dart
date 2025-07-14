import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/app_primary_button.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/screens/homepage/model/tripModel.dart';
import 'package:flutter_arch/screens/homepage/view/seat_selection.screen.dart';
import 'package:flutter_arch/screens/payment/view/paymentScreen2.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';


class ChooseSlotPage extends StatefulWidget {
  final String? selectedDate;
  final String? selectedTimePeriod;
  final String pickupAddress;
  final String destinationAddress;
  final LatLng? pickupLatLng;
  final LatLng? destinationLatLng;

  const ChooseSlotPage({
    super.key,
    this.selectedDate,
    this.selectedTimePeriod,
    required this.pickupAddress,
    required this.destinationAddress,
    this.pickupLatLng,
    this.destinationLatLng,
  });

  @override
  State<ChooseSlotPage> createState() => _ChooseSlotPageState();
}

class _ChooseSlotPageState extends State<ChooseSlotPage> {
  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _selectedTripId;
  late BookSeatModal _bookSeatModal;

  @override
  void initState() {
    super.initState();
    _bookSeatModal = BookSeatModal(
      onBookNow: (List<SeatInfo> selectedSeats) {
        if (selectedSeats.isNotEmpty) {
          // Find the selected trip
          final selectedTrip =
              _trips.firstWhere((trip) => trip.scheduledTripId == _selectedTripId);

          // Navigate to payment with all booking data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen2(
                selectedSeats: selectedSeats,
                scheduledTripId: _bookSeatModal.scheduledTripId ?? "",
                pickupStopId: selectedTrip.pickupStopId,
                dropOffStopId: selectedTrip.destinationStopId,
              ),
            ),
          );
        }
      },
    );
    searchTrips();
  }

  void searchTrips() async {
    setState(() {
      _isLoading = true;
    });

    final dioHttp = DioHttp();
    try {
      // Use the selected date and time period, or default to tomorrow
      String searchDate = widget.selectedDate ?? 
          DateTime.now().add(Duration(days: 1)).toString().split(' ')[0];
      String searchTimePeriod = widget.selectedTimePeriod ?? (DateTime.now().hour < 12 ? 'AM' : 'PM');
      
      // Check if we have valid coordinates
      if (widget.pickupLatLng == null || widget.destinationLatLng == null) {
        toast("Location coordinates are required for trip search");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Debug: Print the payload being sent
      print('Search Trips Payload:');
      print('Origin: ${widget.pickupLatLng!.latitude}, ${widget.pickupLatLng!.longitude}');
      print('Destination: ${widget.destinationLatLng!.latitude}, ${widget.destinationLatLng!.longitude}');
      print('Date: $searchDate');
      print('Time Period: $searchTimePeriod');
      
      final trips = await dioHttp.searchTrips(
        context,
        widget.pickupLatLng!.latitude,
        widget.pickupLatLng!.longitude,
        widget.destinationLatLng!.latitude,
        widget.destinationLatLng!.longitude,
        searchDate,
        searchTimePeriod,
      );
      
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching trips: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      appBar: _buildAppBar(context),
      bottomSheet: Container(
        child: Padding(
          padding: EdgeInsets.only(
              bottom: 12,
              left: 20,
              right: 20,
              top: 12),
          child: AppPrimaryButton(
            text: "Select Seat",
            onTap: () {
              if (_selectedTripId != null) {
                // Find selected trip
                TripModel selectedTrip = _trips.firstWhere((trip) => trip.scheduledTripId == _selectedTripId);
                
                // Show seat selection modal with trip data
                _bookSeatModal.show(
                  context,
                  routeId: selectedTrip.scheduledTripId,
                  pickupId: selectedTrip.pickupStopId,
                  dropoffId: selectedTrip.destinationStopId,
                  pickupAddress: selectedTrip.pickupLocationName,
                  destinationAddress: selectedTrip.destinationLocationName,
                );
              } else {
                toast("Please select a trip first", bgColor: Colors.orange);
              }
            },
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColor.buttonColor))
          : _trips.isEmpty
              ? Center(
                  child:
                      Text("No trips available", style: AppStyle.subheading))
              : RefreshIndicator(
                  onRefresh: () async {
                    searchTrips();
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 70.0 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return _TripCard(
                        tripData: trip,
                        isSelected: _selectedTripId == trip.scheduledTripId,
                        onTap: () {
                          setState(() {
                            _selectedTripId = trip.scheduledTripId;
                          });
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        16.height,
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.greyWhite,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: AppColor.greyShade1),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text("Choose trip",
          style: AppStyle.title3.copyWith(color: AppColor.greyShade1)),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Image.asset(
            AppAssets.logoSmall,
            height: 24,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel tripData;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripCard({
    required this.tripData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format departure time
    String hour = tripData.departureDateTime.hour.toString().padLeft(2, '0');
    String minute = tripData.departureDateTime.minute.toString().padLeft(2, '0');
    String day = tripData.departureDateTime.day.toString().padLeft(2, '0');
    String month = tripData.departureDateTime.month.toString().padLeft(2, '0');
    String amPm = tripData.departureDateTime.hour >= 12 ? 'PM' : 'AM';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColor.greyWhite,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? AppColor.buttonColor
                : AppColor.greyShade5.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.greyShade5.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section: DateTime, Route Name, Price, Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day/$month/${tripData.departureDateTime.year}, $hour:$minute $amPm',
                        style: AppStyle.caption1w600.copyWith(
                            color: AppColor.greyShade2,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      8.height,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColor.buttonColor,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          tripData.routeName,
                          style: AppStyle.caption1w600.copyWith(
                              color: AppColor.greyWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 16 / 12),
                        ),
                      ),
                      4.height,
                      Text(
                        'Duration: ${tripData.durationText}',
                        style: AppStyle.caption1w400.copyWith(
                            color: AppColor.greyShade3,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _CustomCheckbox(isSelected: isSelected),
                    6.height,
                    Text(
                      '₹${tripData.price}',
                      style: AppStyle.body.copyWith(
                        color: AppColor.buttonColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    4.height,
                    Text(
                      '${tripData.availableSeats} seats',
                      style: AppStyle.caption1w400.copyWith(
                          color: AppColor.greyShade3,
                          fontSize: 11),
                    ),
                  ],
                )
              ],
            ),
            12.height,
            Divider(color: AppColor.greyShade5.withOpacity(0.7)),
            12.height,
            // Bottom section: Pickup and Destination
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pickup icon
                    Image.asset(
                      AppAssets.pickupLocation,
                      width: 24,
                      height: 24,
                    ),
                    // Dashed line to destination
                    _buildDashedConnector(),
                    // Destination icon
                    Image.asset(
                      AppAssets.destination,
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Pickup
                      _buildLocationRow(
                          "Pickup", tripData.pickupLocationName, Color(0xFF08875D)),
                      12.height,
                      // Destination
                      _buildLocationRow("Destination",
                          tripData.destinationLocationName, Color(0xFFE02D3C)),
                    ],
                  ),
                ),
              ],
            ),
            8.height,
            // Vehicle info
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.greyShade7,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: AppColor.greyShade3),
                  8.width,
                  Expanded(
                    child: Text(
                      '${tripData.vehicleInfo.type} - ${tripData.vehicleInfo.model}',
                      style: AppStyle.caption1w400.copyWith(
                          color: AppColor.greyShade3,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String type, String address, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: AppStyle.caption1w600.copyWith(
                    height: 16 / 12,
                    color: dotColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              2.height,
              Text(
                address,
                style: AppStyle.subheading.copyWith(
                    color: AppColor.greyShade2,
                    fontSize: 14,
                    height: 22 / 14,
                    fontWeight: FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashedConnector() {
    const double lineHeight = 25.0;
    const double dashHeight = 4.0;
    const double dashSpace = 2.0;
    int dashCount = (lineHeight / (dashHeight + dashSpace)).floor();

    return Container(
      height: lineHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(dashCount, (index) {
          return Container(
            width: 1,
            height: dashHeight,
            color: AppColor.greyShade5.withOpacity(0.8),
            margin: const EdgeInsets.only(bottom: dashSpace),
          );
        }),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool isSelected;
  const _CustomCheckbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? AppColor.buttonColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isSelected
              ? AppColor.buttonColor
              : AppColor.greyShade3.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import 'package:provider/provider.dart';
import 'package:flutter_arch/screens/ride/provider/rideProvider.dart';

class Cancelled extends StatefulWidget {
  const Cancelled({super.key});

  @override
  State<Cancelled> createState() => _CancelledState();
}

class _CancelledState extends State<Cancelled> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RideProvider>(context, listen: false).fetchRides(context, 'cancelled');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, child) {
        final isLoading = rideProvider.isLoading('cancelled');
        final error = rideProvider.getError('cancelled');
        final rides = rideProvider.getCancelledRides();
        if (isLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (error != null) {
          return Center(child: Text(error));
        } else if (rides.isEmpty) {
          return Center(child: Text('No cancelled rides found'));
        }
        return SingleChildScrollView(
          child: Column(
            children: rides.map((ride) => _buildRideCard(ride)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return GestureDetector(
      onTap: () {
        
      },
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 16, top: 16),
                  child: _buildRideCardContent(ride),
                ),
              ],
            ),
          ),
          Divider(thickness: 6, color: Color(0xffF8FAFC)),
        ],
      ),
    );
  }

  Widget _buildRideCardContent(RideModel ride) {
    return Column(
      children: [
        _buildTopRow(ride),
        SizedBox(height: 6),
        _buildDatePaymentRow(ride),
        SizedBox(height: 8),
        _buildTypeDurationRow(ride),
        SizedBox(height: 12),
        Divider(thickness: 0.4, height: 0),
        _buildPickupTile(ride),
        ..._buildMiddleStops(ride),
        _buildDestinationTile(ride),
        Divider(height: 0, thickness: 0.4),
        _buildReasonRow(),
      ],
    );
  }

  Widget _buildTopRow(RideModel ride) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(ride.rideType, style: GoogleFonts.nunito(fontSize: 13, color: Color(0xff364B63))),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffD3DDE7),
          ),
        ),
        // Optionally split rideType for more details if needed
        SizedBox(width: 170),
        Icon(Icons.currency_rupee, size: 17),
        Text(
          ride.price,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 17, color: Color(0xff132235)),
        ),
      ],
    );
  }

  Widget _buildDatePaymentRow(RideModel ride) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(ride.dateTime, style: GoogleFonts.nunito()),
        Row(
          children: [
            Image.asset(
              ride.paymentMethod.toLowerCase() == 'cash'
                  ? 'assets/images/moneys.png'
                  : 'assets/images/Card Flags.png',
              fit: BoxFit.values[1],
            ),
            SizedBox(width: 3),
            Text(
              ride.paymentMethod,
              style: GoogleFonts.nunito(fontSize: 13, color: Color(0xff132235)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeDurationRow(RideModel ride) {
    return Row(
      children: [
        Container(
          height: 19,
          width: 121,
          decoration: BoxDecoration(
            color: Color(0xff3E57B4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              ride.tripInfo,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupTile(RideModel ride) {
    final pickup = ride.pickupStop;
    return ListTile(
      dense: true,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xffDAEDE7), width: 5),
              color: Color(0xff08875D),
              shape: BoxShape.circle,
            ),
          ),
          DottedDashedLine(
            height: 20,
            width: 0,
            axis: Axis.vertical,
            dashColor: Color(0xffE9F0F7),
            dashSpace: 4,
          ),
        ],
      ),
      title: Text('Pickup', style: GoogleFonts.nunito(color: Color(0xff08875D), fontSize: 12)),
      subtitle: Text(
        overflow: TextOverflow.ellipsis,
        pickup != null ? pickup.name : '-',
        style: GoogleFonts.nunito(fontSize: 17),
      ),
    );
  }
  // Show all middle stops (if any) between pickup and destination
  List<Widget> _buildMiddleStops(RideModel ride) {
    final stops = ride.middleStops;
    return stops.map((stop) {
      return ListTile(
        dense: true,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DottedDashedLine(
              height: 20,
              width: 0,
              axis: Axis.vertical,
              dashColor: Color(0xffE9F0F7),
              dashSpace: 4,
            ),
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xffF2E4E4), width: 5),
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        title: Text('Middle Stop', style: GoogleFonts.nunito(color: Colors.orange, fontSize: 12)),
        subtitle: Text(
          stop.name,
          style: GoogleFonts.nunito(fontSize: 17),
        ),
      );
    }).toList();
  }

  Widget _buildDestinationTile(RideModel ride) {
    final dest = ride.destinationStop;
    return ListTile(
      dense: true,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          DottedDashedLine(
            height: 20,
            width: 0,
            axis: Axis.vertical,
            dashColor: Color(0xffE9F0F7),
            dashSpace: 4,
          ),
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xffF2E4E4), width: 5),
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      title: Text('Destination', style: GoogleFonts.nunito(color: Colors.red, fontSize: 12)),
      subtitle: Text(
        overflow: TextOverflow.ellipsis,
        dest != null ? dest.name : '-',
        style: GoogleFonts.nunito(fontSize: 17),
      ),
    );
  }

  Widget _buildReasonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 16, right: 5),
          child: Icon(Icons.info, color: Color(0xffE02D3C), size: 24),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
          child: Text(
            'Driver is not responding',
            style: GoogleFonts.nunito(
              color: Color(0xffE02D3C),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}
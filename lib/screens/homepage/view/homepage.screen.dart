import 'package:flutter/material.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/app_primary_button.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/screens/main_navigation/main_navigation.dart';
import 'package:flutter_arch/screens/ride/view/myride.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:nb_utils/nb_utils.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() { isLoading = true; });
    try {
      final dio = DioHttp();
      final data = await dio.getDriverDashboard(context);
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        dashboardData = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysEarnings = dashboardData?['todaysEarnings'] ?? {};
    final totalBalance = dashboardData?['totalBalance'] ?? {};
    final tripSummaryCounts = dashboardData?['tripSummaryCounts'] ?? {};
    final todaysStats = dashboardData?['todaysStats'] ?? {};
    final currency = (todaysEarnings['currency'] ?? 'INR') == 'INR' ? '₹' : '';
    final balanceCurrency = (totalBalance['currency'] ?? 'INR') == 'INR' ? '₹' : '';
    final rides = todaysStats['rides']?.toString() ?? '0';
    final hours = todaysStats['hours']?.toString() ?? '0';
    final upcomingCount = tripSummaryCounts['upcoming'] ?? 0;
    final completedCount = tripSummaryCounts['completedToday'] ?? 0;
    final cancelledCount = tripSummaryCounts['cancelledToday'] ?? 0;

    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Stack for header and floating card
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Blue header
                          Container(
                            width: double.infinity,
                            height: 150, // Smaller height for header
                            decoration: BoxDecoration(
                              color: AppColor.buttonColor,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    'Dashbord',
                                    style: AppStyle.title.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 20,
                                  child: Image.asset(AppAssets.logoSmall, height: 32),
                                ),
                              ],
                            ),
                          ),
                          // Floating Today's Earnings Card
                          Positioned(
                            left: 20,
                            right: 20,
                            top: 90, // Adjust this value for overlap
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Today', style: AppStyle.body.copyWith(color: AppColor.greyShade2)),
                                  4.height,
                                  Text('$currency${todaysEarnings['amount'] ?? 0}', style: AppStyle.title.copyWith(fontSize: 24, color: AppColor.buttonColor, fontWeight: FontWeight.bold)),
                                  12.height,
                                  Row(
                                    children: [
                                      Icon(Icons.directions_car, size: 18, color: AppColor.greyShade2),
                                      4.width,
                                      Text('${rides} Rides', style: AppStyle.caption1w400.copyWith(color: AppColor.greyShade2)),
                                      16.width,
                                      Icon(Icons.access_time, size: 18, color: AppColor.greyShade2),
                                      4.width,
                                      Text('${hours}H', style: AppStyle.caption1w400.copyWith(color: AppColor.greyShade2)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 80), // Space below the floating card
                      // Total Balance Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Balance', style: AppStyle.body.copyWith(color: AppColor.greyShade2)),
                              4.height,
                              Text('$balanceCurrency${totalBalance['amount'] ?? 0}', style: AppStyle.title.copyWith(fontSize: 22, color: AppColor.buttonColor, fontWeight: FontWeight.bold)),
                              12.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('View Payment History', style: AppStyle.body.copyWith(color: AppColor.buttonColor)),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColor.buttonColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.height,
                      // Request Cab Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppPrimaryButton(
                          text: 'Request cab',
                          onTap: () {
                            // Navigate to request cab screen
                            
                          },
                        ),
                      ),
                      16.height,
                      // Upcoming Trips
                      _buildTripSection(
                        title: 'Upcoming trips',
                        count: upcomingCount,
                        name: 'Megan Fox',
                        rating: 4.8,
                        tripType: 'Upcoming',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Myride(initialTabIndex: 0),
                            ),
                          );
                        },
                      ),
                      // Completed Trips
                      _buildTripSection(
                        title: 'Completed trips',
                        count: completedCount,
                        name: 'Megan Fox',
                        rating: 4.8,
                        tripType: 'Completed',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Myride(initialTabIndex: 1),
                            ),
                          );
                        },
                      ),
                      // Cancelled Trips
                      _buildTripSection(
                        title: 'Cancelled trips',
                        count: cancelledCount,
                        name: 'Megan Fox',
                        rating: 4.8,
                        tripType: 'Cancelled',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Myride(initialTabIndex: 2),
                            ),
                          );
                        },
                      ),
                      24.height,
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTripSection({required String title, required int count, required String name, required double rating, required String tripType, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColor.buttonColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppColor.buttonColor, size: 22),
                      ),
                      12.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppStyle.body.copyWith(fontWeight: FontWeight.bold)),
                          2.height,
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              2.width,
                              Text(rating.toString(), style: AppStyle.caption1w400),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.buttonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Navigation', style: AppStyle.body.copyWith(color: AppColor.buttonColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  10.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$title ($count)', style: AppStyle.caption1w400),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AppColor.greyShade2),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

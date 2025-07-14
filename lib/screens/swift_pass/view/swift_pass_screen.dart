import 'package:flutter/material.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:nb_utils/nb_utils.dart';

class SwiftPassScreen extends StatelessWidget {
  const SwiftPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final String mainAmount = '12,491.22';
    final String totalBalance = '1544.00';
    final int totalRides = 244;
    final String totalTime = '25D 12H';
    final List<Map<String, String>> dailyEarnings = [
      {'date': 'Today: 25/04/2024', 'amount': '1,000'},
      {'date': 'Yesterday: 24/04/2024', 'amount': '2,524'},
      {'date': '23/04/2024', 'amount': '1,300'},
      {'date': '22/04/2024', 'amount': '2,600'},
      {'date': '21/04/2024', 'amount': '3,500'},
    ];
    final List<int> chartData = [1200, 500, 1800, 700, 2000, 1700, 1400];
    final List<String> chartLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Stack for header and floating card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blue header
                  Container(
                    width: double.infinity,
                    height: 150,
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
                            'Earnings',
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
                  // Floating Last 1 Month Card
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 90,
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
                          Center(
                            child: Text('Last 1 Month', style: AppStyle.body.copyWith(color: AppColor.greyShade2)),
                          ),
                          4.height,
                          Center(
                            child: Text('₹ $mainAmount', style: AppStyle.title.copyWith(fontSize: 24, color: AppColor.buttonColor, fontWeight: FontWeight.bold)),
                          ),
                          12.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car, size: 18, color: AppColor.greyShade2),
                              4.width,
                              Text('$totalRides Rides', style: AppStyle.caption1w400.copyWith(color: AppColor.greyShade2)),
                              16.width,
                              Icon(Icons.access_time, size: 18, color: AppColor.greyShade2),
                              4.width,
                              Text(totalTime, style: AppStyle.caption1w400.copyWith(color: AppColor.greyShade2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80),
              // Total Balance Card with Withdrawal and Chart
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Balance', style: AppStyle.body.copyWith(color: AppColor.greyShade2)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColor.buttonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Withdrawal', style: AppStyle.body.copyWith(color: AppColor.buttonColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      4.height,
                      Text('₹ $totalBalance', style: AppStyle.title.copyWith(fontSize: 22, color: AppColor.buttonColor, fontWeight: FontWeight.bold)),
                      12.height,
                      // Simple bar chart mockup
                      SizedBox(
                        height: 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(chartData.length, (i) {
                            return Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 12,
                                    height: (chartData[i] / 2200) * 60 , // scale for demo
                                    decoration: BoxDecoration(
                                      color: AppColor.buttonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  4.height,
                                  Text(chartLabels[i], style: AppStyle.caption1w400.copyWith(fontSize: 12, color: AppColor.greyShade2)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              16.height,
              // Daily Earning Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Earning', style: AppStyle.body.copyWith(color: AppColor.greyShade2)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColor.buttonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('View All', style: AppStyle.body.copyWith(color: AppColor.buttonColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      12.height,
                      ...dailyEarnings.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColor.buttonColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                8.width,
                                Text(e['date']!, style: AppStyle.body.copyWith(fontSize: 14)),
                              ],
                            ),
                            Text('₹${e['amount']}', style: AppStyle.body.copyWith(color: Color(0xff08875D), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
40.height,            ],
          ),
        ),
      ),
    );
  }
} 
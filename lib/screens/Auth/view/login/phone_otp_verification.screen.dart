import 'package:flutter/material.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/screens/Auth/view/registration/registration.screen.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:flutter_arch/widget/snack_bar.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';


class PhoneOtpVerificationScreen extends StatefulWidget {
  const PhoneOtpVerificationScreen({super.key, this.phoneNumber});
  final String? phoneNumber;

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}



class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  TextEditingController otpController = TextEditingController();
  DioHttp dio = DioHttp();
  bool isLoading = false;

    @override
  void initState() {
    super.initState();
    
    // Removed auto-fill functionality - users will enter OTP manually
  }
  Future<bool> verifyOtpWithApi(String otp) async {
    if (widget.phoneNumber == null) return false;

    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await dio.phoneVerifyOtp(context, widget.phoneNumber!, otp);

      setState(() {
        isLoading = false;
      });

      // Save accessToken if present in the response
      if (response.statusCode == 201 && response.data['accessToken'] != null) {
        final accessToken = response.data['accessToken'];
        final storage = MySecureStorage();
        await storage.writeToken(accessToken);
        return true;
      }
      return false;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      MySnackBar.showSnackBar(context, "OTP verification failed");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.arrow_back, size: 28).onTap(() {
                  Navigator.pop(context);
                }),
                Image.asset(AppAssets.logoSmall, height: 32),
              ],
            ).paddingSymmetric(horizontal: 16),
            32.height,
            Text('Verify Phone Number', style: AppStyle.title)
                .paddingSymmetric(horizontal: 16),
            8.height,
            RichText(
              text: TextSpan(
                style: AppStyle.subheading,
                children: [
                  const TextSpan(
                      text: 'Please enter the 6 digit code sent to '),
                  TextSpan(
                    text: widget.phoneNumber ?? "",
                    style: AppStyle.subheading.copyWith(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic),
                  ),
                  const TextSpan(text: ' through SMS'),
                ],
              ),
            ).paddingOnly(left: 16, right: 120),
            24.height,
            Text('Edit your phone number?',
                    style: AppStyle.body.copyWith(
                        color: AppColor.buttonColor,
                        decoration: TextDecoration.underline))
                .paddingSymmetric(horizontal: 16)
                .onTap(() {
              Navigator.pop(context);
            }),
            24.height,
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: otpController,
              autoFocus: true,
              keyboardType: TextInputType.number,
              textStyle: AppStyle.title.copyWith(fontSize: 18),
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderWidth: 1,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 54,
                fieldWidth: 45,
                activeColor: AppColor.greyShade5,
                selectedColor: AppColor.buttonColor,
                inactiveColor: AppColor.greyShade5,
              ),
              onChanged: (value) async {
                if (value.length == 6) {
                  bool success = await verifyOtpWithApi(value);
                  if (success) {
                    RegistrationScreen().launch(context);
                  }
                }
              },
            ).paddingSymmetric(horizontal: 20),
            // Display test OTP if available
            // if (widget.testOtp != null && widget.testOtp!.isNotEmpty)
            //   Container(
            //     margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     decoration: BoxDecoration(
            //       color: AppColor.buttonColor.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: AppColor.buttonColor.withOpacity(0.3)),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(Icons.info_outline, 
            //              color: AppColor.buttonColor, 
            //              size: 16),
            //         8.width,
            //         Expanded(
            //           child: Text(
            //             'Test OTP: ${widget.testOtp}',
            //             style: AppStyle.body.copyWith(
            //               color: AppColor.buttonColor,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            if (isLoading)
              Center(child: CircularProgressIndicator()).paddingTop(16),
            Spacer(),
           
          ],
        ),
      ),
    );
  }
}

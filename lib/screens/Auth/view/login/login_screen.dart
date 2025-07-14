import 'package:flutter/material.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/app_primary_button.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/screens/Auth/view/login/phone_otp_verification.screen.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:flutter_arch/widget/snack_bar.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:country_code_picker/country_code_picker.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  bool isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    final phoneRegex = RegExp(r'^[0-9]{10,15}');
    if (!phoneRegex.hasMatch(value)) return 'Please enter a valid phone number';
    return null;
  }

  Future<void> _getVerificationCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      isLoading = true;
    });
    try {
      final dio = DioHttp();
      final response = await dio.phoneRequestOtp(
          context, '$_selectedCountryCode${_phoneController.text}');
      if (response.statusCode == 201) {
        MySnackBar.showSnackBar(context, response.data['message']);
        String? testOtp = response.data['otpForTesting']?.toString();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PhoneOtpVerificationScreen(
                    phoneNumber:
                        '$_selectedCountryCode${_phoneController.text}')));
      }
    } catch (e) {
      MySnackBar.showSnackBar(context, "Failed to send OTP. Please try again.");
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildPhoneInputRow() {
    return Row(
      children: [
        CountryCodePicker(
          onChanged: (country) {
            setState(() {
              _selectedCountryCode = country.dialCode ?? '+91';
            });
          },
          initialSelection: 'IN',
          favorite: ['+91', 'IN'],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
          padding: const EdgeInsets.symmetric(horizontal: 0),
        ),
        8.width,
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Mobile Number',
              hintStyle: AppStyle.body.copyWith(color: AppColor.greyShade1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.buttonColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.buttonColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  Widget _buildNoteText() {
    return RichText(
      text: TextSpan(
        text: 'Note: ',
        style: AppStyle.caption1w600.copyWith(color: AppColor.greyShade2),
        children: [
          TextSpan(
            text:
                'By proceeding, you consent to get calls, WhatsApp or SMS messages, including by automated means, from SwiftGo and its affiliates to the number provided.',
            style: AppStyle.caption1w400,
          ),
        ],
      ),
    ).paddingSymmetric(horizontal: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_back, size: 28)
                      .onTap(() => Navigator.pop(context)),
                  Image.asset(AppAssets.logoSmall, height: 32),
                ],
              ).paddingSymmetric(horizontal: 16),
              32.height,
              Text('Enter Phone number for verification', style: AppStyle.title)
                  .paddingSymmetric(horizontal: 16),
              8.height,
              Text("We'll text a code to verify your phone number",
                      style: AppStyle.subheading)
                  .paddingSymmetric(horizontal: 16),
              24.height,
              _buildPhoneInputRow(),
              const Spacer(),
              _buildNoteText(),
              16.height,
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : AppPrimaryButton(
                      text: 'Get Verification Code',
                      onTap: _getVerificationCode,
                    ).paddingSymmetric(horizontal: 16, vertical: 16),
            ],
          ),
        ),
      ),
    );
  }
}

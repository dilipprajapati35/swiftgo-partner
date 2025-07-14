import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_arch/common/app_assets.dart';
import 'package:flutter_arch/common/app_primary_button.dart';
import 'package:flutter_arch/common/style/app_style.dart';
import 'package:flutter_arch/screens/Auth/view/registration/selfie_verification.screen.dart';
import 'package:flutter_arch/screens/homepage/view/homepage.screen.dart';
import 'package:flutter_arch/screens/main_navigation/main_navigation.dart';
import 'package:flutter_arch/services/dio_http.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:flutter_arch/theme/colorTheme.dart';
import 'package:flutter_arch/widget/snack_bar.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:dio/dio.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _vehicleTypeInfo = TextEditingController();

  String? selectedGender = 'male';
  final List<String> genderOptions = ['male', 'female', 'other'];

  bool isLoading = false;
  DioHttp dio = DioHttp();
  final ScrollController _scrollController = ScrollController();

  PlatformFile? _driverLicenseFile;
  PlatformFile? _rcFile;
  PlatformFile? _insuranceFile;

  Future<void> _pickAndUploadFile({required Function(PlatformFile) onFilePicked, required Future<Response> Function(String) uploadFn}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() => onFilePicked(file));
      // Upload the file
      try {
        setState(() { isLoading = true; });
        final response = await uploadFn(file.path!);
        setState(() { isLoading = false; });
        if (response.statusCode == 200 || response.statusCode == 201) {
          MySnackBar.showSnackBar(context, 'Upload successful');
        } else {
          MySnackBar.showSnackBar(context, 'Upload failed');
        }
      } catch (e) {
        setState(() { isLoading = false; });
        MySnackBar.showSnackBar(context, 'Upload failed');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
 |   super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyShade7,
      resizeToAvoidBottomInset: true,
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
            Text('Registration', style: AppStyle.title)
                .paddingSymmetric(horizontal: 16),
            8.height,
            Text('Please enter all the details', style: AppStyle.subheading)
                .paddingSymmetric(horizontal: 16),
            17.height,
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, size: 28),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MainNavigation(),
                          ),
                        );
                      },
                    ).paddingOnly(left: 16, bottom: 8),
        
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'Enter your full name',
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Enter your email',
                    ),
                    _buildGenderDropdown(),                    
                    _buildTextField(
                      controller: _phoneNumber,
                      label: 'Phone Number',
                      hint: 'Enter Phone Number',
                    ),
                    _buildTextField(
                      controller: _vehicleTypeInfo,
                      label: 'Vehicle Type Info',
                      hint: 'Enter here',
                    ),
                    _buildFileUploadField(
                      label: "Upload Driver’s License *",
                      file: _driverLicenseFile,
                      onTap: () => _pickAndUploadFile(
                        onFilePicked: (file) => _driverLicenseFile = file,
                        uploadFn: (path) => dio.uploadLicense(context, path),
                      ),
                    ),
                    _buildFileUploadField(
                      label: "Upload RC *",
                      file: _rcFile,
                      onTap: () => _pickAndUploadFile(
                        onFilePicked: (file) => _rcFile = file,
                        uploadFn: (path) => dio.uploadRc(context, path),
                      ),
                    ),
                    _buildFileUploadField(
                      label: "Upload Vehicle Insurance *",
                      file: _insuranceFile,
                      onTap: () => _pickAndUploadFile(
                        onFilePicked: (file) => _insuranceFile = file,
                        uploadFn: (path) => dio.uploadInsurance(context, path),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 0,
              child: AppPrimaryButton(
                text: 'Register now',
                onTap: () async {
                  await _handleRegistration();
                },
              ).paddingSymmetric(horizontal: 16, vertical: 16),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (_emailController.text.isEmpty) {
      MySnackBar.showSnackBar(context, "Email are required");
      return;
    }

    if (selectedGender == null) {
      MySnackBar.showSnackBar(context, "Please select your gender");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final storage = MySecureStorage();

      final response = await dio.completeregistration(
          context,
          _fullNameController.text,
          _emailController.text,
          selectedGender ?? '',
          _phoneNumber.text,
          _vehicleTypeInfo.text);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201 && response.data['id'] != null) {
        // Save only the driver id
        await storage.writeUserId(response.data['id']);
        SelfieUploadScreen().launch(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      MySnackBar.showSnackBar(
          context, "Registration failed. Please try again.");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(label, style: AppStyle.caption1w600)
        //     .paddingOnly(left: 4, bottom: 4),
        TextFormField(
          controller: controller,
          // textFieldType: TextFieldType.NAME,
          decoration: InputDecoration(
            hintText: hint,
            labelText: label,
            floatingLabelStyle: AppStyle.caption1w600
                .copyWith(color: AppColor.greyShade1, letterSpacing: 0),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: true,
            hintStyle: AppStyle.body.copyWith(
                color: AppColor.greyTextField,
                fontSize: 16,
                height: 22 / 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w400),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.greyShade5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.greyShade5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.buttonColor, width: 1.5),
            ),
          ),
        ),
        16.height,
      ],
    ).paddingSymmetric(
      horizontal: 16,
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedGender,
          decoration: InputDecoration(
            hintText: 'Select Gender',
            labelText: 'Gender',
            floatingLabelStyle: AppStyle.caption1w600
                .copyWith(color: AppColor.greyShade1, letterSpacing: 0),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: true,
            hintStyle: AppStyle.body.copyWith(
                color: AppColor.constBlack,
                fontSize: 16,
                height: 22 / 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w400),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.greyShade5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.greyShade5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColor.buttonColor, width: 1.5),
            ),
          ),
          items: genderOptions.map((String gender) {
            // Capitalize first letter for display
            String displayGender = gender[0].toUpperCase() + gender.substring(1);
            return DropdownMenuItem<String>(
              value: gender, // Keep lowercase for backend
              child: Text(
                displayGender,
                style: AppStyle.body.copyWith(
                  fontSize: 16,
                  height: 22 / 16,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w400,
                  color: AppColor.constBlack,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedGender = value; // Store lowercase value
              _genderController.text = value ?? ''; // Store lowercase in controller
            });
          },
        ),
        16.height,
      ],
    ).paddingSymmetric(
      горизонтальный: 16,
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required PlatformFile? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Upload here",
                labelText: label,
                floatingLabelStyle: AppStyle.caption1w600
                    .copyWith(color: AppColor.greyShade1, letterSpacing: 0),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                alignLabelWithHint: true,
                hintStyle: AppStyle.body.copyWith(
                    color: AppColor.greyTextField,
                    fontSize: 16,
                    height: 22 / 16,
                    letterComparison: 0,
                    fontWeight: FontWeight.w400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColor.greyShade5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColor.greyShade5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColor.buttonColor, width: 1.5),
                ),
                suffixIcon: Icon(Icons.cloud_upload, color: AppColor.buttonColor),
              ),
              controller: TextEditingController(
                  text: file?.name ?? ""),
              style: AppStyle.body.copyWith(
                color: file == null
                    ? AppColor.greyTextField
                    : AppColor.constBlack,
              ),
            ),
          ),
        ),
        16.height,
      ],
    ).paddingSymmetric(horizontal: 16);
  }
}
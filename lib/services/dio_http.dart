import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_arch/common/api_endpoints.dart';
import 'package:flutter_arch/interceptor/dio_interceptor.dart';
import 'package:flutter_arch/screens/homepage/model/routeModel.dart';
import 'package:flutter_arch/screens/homepage/model/subscriptionPlanModel.dart';
import 'package:flutter_arch/screens/homepage/model/tripModel.dart';
import 'package:flutter_arch/screens/ride/model/rideModel.dart';
import 'package:flutter_arch/services/api_error_handler.dart';
import 'package:flutter_arch/storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_arch/screens/profile/model/user_model.dart';
import 'package:http_parser/http_parser.dart';

class DioHttp {
  final Dio _dio;
  final String _baseUrl;
  final MySecureStorage _secureStorage;

  DioHttp()
      : _dio = Dio()..interceptors.add(DioInterceptor()),
        _baseUrl = dotenv.env['BASE_URL']!,
        _secureStorage = MySecureStorage();

  Future<Response> _postRequest({
    required BuildContext context,
    required ApiEndpoint endpoint,
    required dynamic data,
    bool wrapData = true,
    Function(String)? onSuccess,
  }) async {
    final url = '$_baseUrl${endpoint.fullPath}';
    try {
      final response = await _dio.post(
        url,
        data: data is FormData
            ? data
            : jsonEncode(wrapData ? {'data': data} : data),
      );

      if (onSuccess != null && response.data['data'] is String) {
        onSuccess(response.data['data']);
      }
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  Future<Response> _getRequest({
    required BuildContext context,
    required ApiEndpoint endpoint,
    Map<String, dynamic>? queryParameters,
    String? customPath, // Add this parameter
  }) async {
    final url = customPath != null
        ? '$_baseUrl$customPath'
        : '$_baseUrl${endpoint.fullPath}';
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  Future<Response> _putRequest({
    required BuildContext context,
    required ApiEndpoint endpoint,
    required dynamic data,
    String? resourceId,
    bool isFormData = false, // Add this parameter
  }) async {
    final path = resourceId != null
        ? '${endpoint.fullPath}/$resourceId'
        : endpoint.fullPath;
    final url = '$_baseUrl$path';
    try {
      final response = await _dio.put(
        url,
        data: isFormData ? data : jsonEncode(data),
      );
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  Future<Response> _deleteRequest({
    required BuildContext context,
    required ApiEndpoint endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? resourceId,
  }) async {
    final path = resourceId != null
        ? '${endpoint.fullPath}/$resourceId'
        : endpoint.fullPath;
    final url = '$_baseUrl$path';
    try {
      final response = await _dio.delete(
        url,
        data: data != null ? jsonEncode(data) : null,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  Future<Response> kycinitiate(
      BuildContext context, String aadhaarNumber) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.kycinitiate,
      data: {"aadhaarNumber": aadhaarNumber},
      wrapData: false,
    );
  }

  Future<Response> kycverifyotp(BuildContext context, String aadhaarNumber,
      String otp, String transactionId) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.kycverifyotp,
      data: {
        "aadhaarNumber": aadhaarNumber,
        "otp": otp,
        "transactionId": transactionId
      },
      wrapData: false,
    );
  }

  Future<Response> phoneRequestOtp(
      BuildContext context, String phoneNumber) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.phonerequestotp,
      data: {"phoneNumber": phoneNumber},
      wrapData: false,
    );
  }

  Future<Response> phoneVerifyOtp(
      BuildContext context, String phoneNumber, String otp) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.phoneverifyotp,
      data: {"phoneNumber": phoneNumber, "otp": otp},
      wrapData: false,
    );
  }

  Future<Response> completeregistration(
      BuildContext context,
      String fullName,
      String email,
      String gender,
      String phoneNumber,
      String vehicleTypeInfo) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.completeregistration,
      data: {
        "fullName": fullName,
        "email": email,
        "gender": gender,
        "phoneNumber": phoneNumber,
        "vehicleTypeInfo": vehicleTypeInfo
      },
      wrapData: false,
    );
  }

  Future<List<RouteModel>> routes(BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.routes,
    );

    List<dynamic> routesJson = [];
    if (response.data is List) {
      routesJson = response.data as List;
    } else if (response.data is Map && response.data['data'] is List) {
      routesJson = response.data['data'] as List;
    }

    return routesJson
        .map((routeJson) => RouteModel.fromJson(routeJson))
        .toList();
  }

  Future<List<TripModel>> searchTrips(
    BuildContext context,
    double originLatitude,
    double originLongitude,
    double destinationLatitude,
    double destinationLongitude,
    String date,
    String timePeriod,
  ) async {
    final payload = {
      "origin": {"latitude": originLatitude, "longitude": originLongitude},
      "destination": {
        "latitude": destinationLatitude,
        "longitude": destinationLongitude
      },
      "date": date,
      "timePeriod": timePeriod
    };

    // Debug: Print the exact payload being sent
    print('API Payload: ${jsonEncode(payload)}');

    final response = await _postRequest(
      context: context,
      endpoint: ApiEndpoint.tripSearch,
      data: payload,
      wrapData: false,
    );

    List<dynamic> tripsJson = [];
    if (response.data is List) {
      tripsJson = response.data as List;
    } else if (response.data is Map && response.data['data'] is List) {
      tripsJson = response.data['data'] as List;
    }

    return tripsJson.map((tripJson) => TripModel.fromJson(tripJson)).toList();
  }

  Future<Response> getSeatLayout(BuildContext context, String tripId) async {
    // Construct the full path with the tripId (not routeId)
    final String seatLayoutPath =
        '${ApiEndpoint.trips.fullPath}/$tripId/seat-layout';

    return await _getRequest(
      context: context,
      endpoint: ApiEndpoint.trips,
      customPath: seatLayoutPath, // Pass the custom path
    );
  }

  Future<Response> makeBooking(
      BuildContext context,
      String scheduledTripId,
      String pickupStopId,
      String dropOffStopId,
      List<String> selectedSeatIds,
      String paymentMethod) async {
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.bookings,
      data: {
        "onwardScheduledTripId": scheduledTripId,
        "onwardPickupStopId": pickupStopId,
        "onwardDropOffStopId": dropOffStopId,
        "onwardSelectedSeatIds": selectedSeatIds,
        "isRoundTrip": false,
        "paymentMethod": "cash"
      },
      wrapData: false,
    );
  }

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans(
      BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.subscriptionPlans,
    );

    List<dynamic> plansJson = [];
    if (response.data is List) {
      plansJson = response.data as List;
    } else if (response.data is Map && response.data['data'] is List) {
      plansJson = response.data['data'] as List;
    }

    return plansJson
        .map((planJson) => SubscriptionPlanModel.fromJson(planJson))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllStops(BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.routes,
      customPath: '/routes/all-stops',
    );
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data['data'] is List) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    }
    return [];
  }

  Future<Response> subscribeToPlan(
    BuildContext context,
    String planId, {
    required String pickupStopId,
    required String dropOffStopId,
    required String commuteType,
  }) async {
    final url = '$_baseUrl/user-subscriptions/subscribe';
    try {
      final response = await _dio.post(
        url,
        data: {
          "planId": planId,
          "pickupStopId": pickupStopId,
          "dropOffStopId": dropOffStopId,
          "commuteType": commuteType,
        },
      );
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  Future<List<RideModel>> getMyRides(BuildContext context, String status) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.myRides,
      queryParameters: {'status': status},
    );

    List<dynamic> ridesJson = [];
    if (response.data is List) {
      ridesJson = response.data as List;
    } else if (response.data is Map && response.data['data'] is List) {
      ridesJson = response.data['data'] as List;
    }

    return ridesJson.map((rideJson) => RideModel.fromJson(rideJson)).toList();
  }

  Future<UserModel> getUserInfo(BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.me,
    );
    return UserModel.fromJson(response.data);
  }

  Future<Response> uploadLicense(BuildContext context, String filePath) async {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'pdf') {
      mimeType = 'application/pdf';
    }
    final formData = FormData.fromMap({
      'license': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    });
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.uploadLicense,
      data: formData,
      wrapData: false,
    );
  }

  Future<Response> uploadRc(BuildContext context, String filePath) async {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'pdf') {
      mimeType = 'application/pdf';
    }
    final formData = FormData.fromMap({
      'rc': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    });
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.uploadRc,
      data: formData,
      wrapData: false,
    );
  }

  Future<Response> uploadInsurance(BuildContext context, String filePath) async {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'pdf') {
      mimeType = 'application/pdf';
    }
    final formData = FormData.fromMap({
      'insurance': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    });
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.uploadInsurance,
      data: formData,
      wrapData: false,
    );
  }
  Future<Response> uploadSelfie(
      BuildContext context, String filePath) async {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'pdf') {
      mimeType = 'application/pdf';
    }
    final formData = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    });
    return await _postRequest(
      context: context,
      endpoint: ApiEndpoint.uploadSelfie,
      data: formData,
      wrapData: false,
    );
  }

  Future<Map<String, dynamic>> getDriverDashboard(BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.dashboard,
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else {
      return {};
    }
  }

  // Fetch passengers for a trip
  Future<List<Map<String, dynamic>>> getTripPassengers(BuildContext context, String tripId) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.trips, // Use trips as base, override path
      customPath: '/driver/trips/$tripId/passengers',
    );
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else if (response.data is Map && response.data['data'] is List) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    }
    return [];
  }

  // Start a trip (unlock ride)
  Future<Response> startTrip(BuildContext context, String tripId) async {
    final url = '$_baseUrl/driver/trips/$tripId/start';
    try {
      final response = await _dio.patch(url);
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  // Fetch driver earnings
  Future<Map<String, dynamic>> getDriverEarnings(BuildContext context) async {
    final response = await _getRequest(
      context: context,
      endpoint: ApiEndpoint.dashboard, // Use any valid endpoint, override with customPath
      customPath: '/driver/earnings',
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return {};
  }

  // Onboard a passenger (mark as ONGOING)
  Future<Response> onboardPassenger(BuildContext context, String bookingId) async {
    final url = '$_baseUrl/driver/bookings/$bookingId/onboard-start';
    try {
      final response = await _dio.post(url);
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }

  // Decline a passenger (mark as NO_SHOW)
  Future<Response> declinePassenger(BuildContext context, String bookingId) async {
    final url = '$_baseUrl/driver/bookings/$bookingId/decline';
    try {
      final response = await _dio.post(url);
      return response;
    } on DioException catch (err) {
      ApiErrorHandler.handleDioError(context, err);
      rethrow;
    } catch (err) {
      ApiErrorHandler.handleUnexpectedError(context, err);
      rethrow;
    }
  }
}

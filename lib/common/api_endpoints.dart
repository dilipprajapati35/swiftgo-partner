// lib/constants/api_constants.dart
enum ApiEndpoint {
  kycinitiate('/auth/driver/kyc/initiate'),
  phonerequestotp('/auth/driver/request-otp'),
  phoneverifyotp('/auth/driver/verify-otp'),
  completeregistration('/auth/driver/register'),
  routes('/routes'),
  trips('/trips'),
  tripSearch('/trips/search'),
  bookings('/bookings'),
  kycverifyotp('/auth/driver/kyc/verify'),
  subscriptionPlans('/subscription-plans'),
  myRides('/driver/trips/my-rides'),
  me("/driver/me"),
  uploadLicense('/driver/upload-license'),
  uploadRc('/driver/upload-rc'),
  uploadSelfie('/driver/upload-selfie'),
  uploadInsurance('/driver/upload-insurance'),
  dashboard('/driver/dashboard');
  

  final String path;

  const ApiEndpoint(this.path);

  String get fullPath => path;
}
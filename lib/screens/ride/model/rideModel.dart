class RideModel {
  final String tripId;
  final String rideType;
  final String dateTime;
  final String price;
  final String paymentMethod;
  final String tripInfo;
  final List<PointModel> pickupPoints;
  final List<PointModel> destinationPoints;
  final String statusText;
  final LatLngModel startCoordinates;
  final LatLngModel endCoordinates;

  RideModel({
    required this.tripId,
    required this.rideType,
    required this.dateTime,
    required this.price,
    required this.paymentMethod,
    required this.tripInfo,
    required this.pickupPoints,
    required this.destinationPoints,
    required this.statusText,
    required this.startCoordinates,
    required this.endCoordinates,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      tripId: json['tripId'] ?? '',
      rideType: json['rideType'] ?? '',
      dateTime: json['dateTime'] ?? '',
      price: json['price']?.toString() ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      tripInfo: json['tripInfo'] ?? '',
      pickupPoints: (json['pickupPoints'] as List? ?? []).map((e) => PointModel.fromJson(e)).toList(),
      destinationPoints: (json['destinationPoints'] as List? ?? []).map((e) => PointModel.fromJson(e)).toList(),
      statusText: json['statusText'] ?? '',
      startCoordinates: LatLngModel.fromJson(json['startCoordinates'] ?? {}),
      endCoordinates: LatLngModel.fromJson(json['endCoordinates'] ?? {}),
    );
  }
}

class LatLngModel {
  final double latitude;
  final double longitude;
  LatLngModel({required this.latitude, required this.longitude});
  factory LatLngModel.fromJson(Map<String, dynamic> json) {
    return LatLngModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}

class PointModel {
  final String name;
  final String address;
  PointModel({required this.name, required this.address});
  factory PointModel.fromJson(Map<String, dynamic> json) {
    return PointModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

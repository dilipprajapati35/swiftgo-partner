class RideModel {
  final String tripId;
  final String rideType;
  final String dateTime;
  final String price;
  final String paymentMethod;
  final String tripInfo;
  final List<StopModel> stops;
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
    required this.stops,
    required this.statusText,
    required this.startCoordinates,
    required this.endCoordinates,
  });

  // Helper getters for UI
  StopModel? get pickupStop => stops.isNotEmpty ? stops.first : null;
  StopModel? get destinationStop => stops.isNotEmpty ? stops.last : null;
  List<StopModel> get middleStops => stops.length > 2 ? stops.sublist(1, stops.length - 1) : [];

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      tripId: json['tripId'] ?? '',
      rideType: json['rideType'] ?? '',
      dateTime: json['dateTime'] ?? '',
      price: json['price']?.toString() ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      tripInfo: json['tripInfo'] ?? '',
      stops: (json['stops'] as List? ?? []).map((e) => StopModel.fromJson(e)).toList(),
      statusText: json['statusText'] ?? '',
      startCoordinates: LatLngModel.fromJson(json['startCoordinates'] ?? {}),
      endCoordinates: LatLngModel.fromJson(json['endCoordinates'] ?? {}),
    );
  }
}

class StopModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int sequence;
  final String type;

  StopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.sequence,
    required this.type,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      sequence: json['sequence'] ?? 0,
      type: json['type'] ?? '',
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

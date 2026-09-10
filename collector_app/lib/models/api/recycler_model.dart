class RecyclerModel {
  final String recyclerId;
  final String name;
  final String facilityAddress;
  final double latitude;
  final double longitude;
  final List<String> materialsAccepted;
  final Map<String, dynamic> offeredRates;
  final bool pickupAvailable;
  final int serviceRadiusKm;
  final bool verifiedByAdmin;
  final double? distanceKm;
  final double? matchScore;

  const RecyclerModel({
    required this.recyclerId,
    required this.name,
    required this.facilityAddress,
    required this.latitude,
    required this.longitude,
    required this.materialsAccepted,
    required this.offeredRates,
    required this.pickupAvailable,
    required this.serviceRadiusKm,
    required this.verifiedByAdmin,
    this.distanceKm,
    this.matchScore,
  });

  factory RecyclerModel.fromJson(Map<String, dynamic> json) {
    return RecyclerModel(
      recyclerId: json['recycler_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      facilityAddress: json['facility_address'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      materialsAccepted: (json['materials_accepted'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      offeredRates: (json['offered_rates'] as Map<String, dynamic>?) ?? {},
      pickupAvailable: json['pickup_available'] as bool? ?? false,
      serviceRadiusKm: json['service_radius_km'] as int? ?? 0,
      verifiedByAdmin: json['verified_by_admin'] as bool? ?? false,
      distanceKm: _toDoubleNullable(json['distance_km']),
      matchScore: _toDoubleNullable(json['match_score']),
    );
  }

  /// Returns the offered rate for a given category, or null if not accepted.
  double? rateFor(String category) {
    final v = offeredRates[category];
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class PriceModel {
  final String priceId;
  final String materialCategory;
  final String materialSubCat;
  final String locationDistrict;
  final double buyingPrice;
  final double marketPriceLow;
  final double marketPriceHigh;
  final String unit;
  final String dateRecorded;

  const PriceModel({
    required this.priceId,
    required this.materialCategory,
    required this.materialSubCat,
    required this.locationDistrict,
    required this.buyingPrice,
    required this.marketPriceLow,
    required this.marketPriceHigh,
    required this.unit,
    required this.dateRecorded,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      priceId: json['price_id'] as String? ?? '',
      materialCategory: json['material_category'] as String? ?? '',
      materialSubCat: json['material_sub_cat'] as String? ?? '',
      locationDistrict: json['location_district'] as String? ?? '',
      buyingPrice: _toDouble(json['buying_price']),
      marketPriceLow: _toDouble(json['market_price_low']),
      marketPriceHigh: _toDouble(json['market_price_high']),
      unit: json['unit'] as String? ?? 'kg',
      dateRecorded: json['date_recorded'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'price_id': priceId,
        'material_category': materialCategory,
        'material_sub_cat': materialSubCat,
        'location_district': locationDistrict,
        'buying_price': buyingPrice,
        'market_price_low': marketPriceLow,
        'market_price_high': marketPriceHigh,
        'unit': unit,
        'date_recorded': dateRecorded,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

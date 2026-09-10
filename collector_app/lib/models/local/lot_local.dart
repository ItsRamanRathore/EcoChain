import 'package:hive/hive.dart';

part 'lot_local.g.dart';

@HiveType(typeId: 1)
class LotLocal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String materialCategory;

  @HiveField(2)
  double approximateWeight;

  @HiveField(3)
  String imagePath;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  bool isSynced;

  @HiveField(6)
  String? serverId;

  @HiveField(11)
  bool? handoverCompleted;

  LotLocal({
    required this.id,
    required this.materialCategory,
    required this.approximateWeight,
    required this.imagePath,
    required this.timestamp,
    this.isSynced = false,
    this.serverId,
    this.handoverCompleted = false,
  });

  Map<String, dynamic> toApiJson() => {
    'local_id': id,
    'material_category': materialCategory,
    'approximate_weight': approximateWeight,
    'condition': 'Good',
    'collection_location': {
      'lat': 19.0760,
      'lng': 72.8777,
    },
    'sub_category': 'Mixed',
    'source_type': 'Individual',
    'quoted_price': 0.0,
    'recycler_id': '00000000-0000-0000-0000-000000000000',
  };
}

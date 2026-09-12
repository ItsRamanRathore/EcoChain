class HandoverRecord {
  final String traceId;
  final String lotId;
  final String refNumber;
  final String qrCodeData;
  final String materialCategory;
  final double weightAtCollection;
  final String recyclerName;
  final String recyclerAuthNumber;
  final String collectorDisplayName;
  final String status;
  final DateTime collectionTimestamp;

  HandoverRecord({
    required this.traceId,
    required this.lotId,
    required this.refNumber,
    required this.qrCodeData,
    required this.materialCategory,
    required this.weightAtCollection,
    required this.recyclerName,
    required this.recyclerAuthNumber,
    required this.collectorDisplayName,
    required this.status,
    required this.collectionTimestamp,
  });

  factory HandoverRecord.fromJson(Map<String, dynamic> json) => HandoverRecord(
        traceId: json['trace_id'] ?? '',
        lotId: json['lot_id'] ?? '',
        refNumber: json['ref_number'] ?? '',
        qrCodeData: json['qr_code_data'] ?? '',
        materialCategory: json['material_category'] ?? '',
        weightAtCollection: (json['weight_at_collection'] ?? 0).toDouble(),
        recyclerName: json['recycler_name'] ?? '',
        recyclerAuthNumber: json['recycler_auth_number'] ?? '',
        collectorDisplayName: json['collector_display_name'] ?? '',
        status: json['status'] ?? 'Pending',
        collectionTimestamp: DateTime.parse(json['collection_timestamp']),
      );

  Map<String, dynamic> toJson() => {
        'trace_id': traceId,
        'lot_id': lotId,
        'ref_number': refNumber,
        'qr_code_data': qrCodeData,
        'material_category': materialCategory,
        'weight_at_collection': weightAtCollection,
        'recycler_name': recyclerName,
        'recycler_auth_number': recyclerAuthNumber,
        'collector_display_name': collectorDisplayName,
        'status': status,
        'collection_timestamp': collectionTimestamp.toIso8601String(),
      };
}

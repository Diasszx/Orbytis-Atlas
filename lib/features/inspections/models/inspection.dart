import 'inspection_sync_status.dart';

final class Inspection {
  const Inspection({
    required this.clientId,
    required this.workOrderId,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.observation,
    this.condition,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.capturedAt,
    this.syncError,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      clientId: json['clientId'] as String,
      serverId: json['serverId'] as String?,
      workOrderId: json['workOrderId'] as String,
      observation: json['observation'] as String?,
      condition: json['condition'] as String?,
      photoPath: json['photoPath'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capturedAt: _parseOptionalDate(json['capturedAt']),
      syncStatus: InspectionSyncStatus.values.byName(
        json['syncStatus'] as String,
      ),
      syncError: json['syncError'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String clientId;
  final String? serverId;
  final String workOrderId;

  final String? observation;
  final String? condition;
  final String? photoPath;

  final double? latitude;
  final double? longitude;

  final DateTime? capturedAt;

  final InspectionSyncStatus syncStatus;
  final String? syncError;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      if (serverId != null) 'serverId': serverId,
      'workOrderId': workOrderId,
      if (observation != null) 'observation': observation,
      if (condition != null) 'condition': condition,
      if (photoPath != null) 'photoPath': photoPath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
      'syncStatus': syncStatus.name,
      if (syncError != null) 'syncError': syncError,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Inspection copyWith({
    String? serverId,
    String? observation,
    String? condition,
    String? photoPath,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
    InspectionSyncStatus? syncStatus,
    String? syncError,
    bool clearSyncError = false,
    DateTime? updatedAt,
  }) {
    return Inspection(
      clientId: clientId,
      serverId: serverId ?? this.serverId,
      workOrderId: workOrderId,
      observation: observation ?? this.observation,
      condition: condition ?? this.condition,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: clearSyncError ? null : syncError ?? this.syncError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is! String) {
      return null;
    }

    return DateTime.parse(value);
  }
}

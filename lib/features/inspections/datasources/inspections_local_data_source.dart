import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/inspection.dart';
import '../models/inspection_sync_status.dart';

abstract interface class InspectionsLocalDataSource {
  Future<void> saveInspection(Inspection inspection);

  Inspection? getInspectionByClientId(String clientId);

  Inspection? getDraftByWorkOrderId(String workOrderId);

  List<Inspection> getInspections();

  List<Inspection> getInspectionsByWorkOrderId(String workOrderId);

  List<Inspection> getPendingInspections();

  List<Inspection> getFailedInspections();

  Future<void> deleteInspection(String clientId);
}

final class InspectionsLocalDataSourceImpl
    implements InspectionsLocalDataSource {
  InspectionsLocalDataSourceImpl({required Box<String> box}) : _box = box;

  final Box<String> _box;

  @override
  Future<void> saveInspection(Inspection inspection) async {
    await _box.put(inspection.clientId, jsonEncode(inspection.toJson()));
  }

  @override
  Inspection? getInspectionByClientId(String clientId) {
    final value = _box.get(clientId);

    if (value == null) {
      return null;
    }

    return _decodeInspection(value);
  }

  @override
  List<Inspection> getInspections() {
    return _box.values.map(_decodeInspection).toList(growable: false);
  }

  @override
  List<Inspection> getInspectionsByWorkOrderId(String workOrderId) {
    return getInspections()
        .where((inspection) => inspection.workOrderId == workOrderId)
        .toList(growable: false);
  }

  @override
  Inspection? getDraftByWorkOrderId(String workOrderId) {
    final drafts = getInspections()
        .where(
          (inspection) =>
              inspection.workOrderId == workOrderId &&
              inspection.syncStatus == InspectionSyncStatus.draft,
        )
        .toList();

    if (drafts.isEmpty) {
      return null;
    }

    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts.first;
  }

  @override
  List<Inspection> getPendingInspections() {
    return getInspections()
        .where(
          (inspection) =>
              inspection.syncStatus == InspectionSyncStatus.pending,
        )
        .toList(growable: false);
  }

  @override
  List<Inspection> getFailedInspections() {
    return getInspections()
        .where(
          (inspection) => inspection.syncStatus == InspectionSyncStatus.failed,
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteInspection(String clientId) async {
    await _box.delete(clientId);
  }

  Inspection _decodeInspection(String value) {
    final decoded = jsonDecode(value);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached inspection data');
    }

    return Inspection.fromJson(decoded);
  }
}

import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/inspection.dart';
import '../models/inspection_sync_status.dart';

final class InspectionsLocalDataSource {
  InspectionsLocalDataSource({required Box<String> box}) : _box = box;

  final Box<String> _box;

  Future<void> saveInspection(Inspection inspection) async {
    await _box.put(inspection.clientId, jsonEncode(inspection.toJson()));
  }

  Inspection? getInspectionByClientId(String clientId) {
    final value = _box.get(clientId);

    if (value == null) {
      return null;
    }

    return _decodeInspection(value);
  }

  List<Inspection> getInspections() {
    return _box.values.map(_decodeInspection).toList(growable: false);
  }

  List<Inspection> getInspectionsByWorkOrderId(String workOrderId) {
    return getInspections()
        .where((inspection) => inspection.workOrderId == workOrderId)
        .toList(growable: false);
  }

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

  List<Inspection> getPendingInspections() {
    return getInspections()
        .where(
          (inspection) =>
              inspection.syncStatus == InspectionSyncStatus.pending,
        )
        .toList(growable: false);
  }

  List<Inspection> getFailedInspections() {
    return getInspections()
        .where(
          (inspection) => inspection.syncStatus == InspectionSyncStatus.failed,
        )
        .toList(growable: false);
  }

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

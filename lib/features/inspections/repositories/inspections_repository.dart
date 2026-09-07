import 'package:uuid/uuid.dart';

import '../datasources/inspections_local_data_source.dart';
import '../errors/inspections_exception.dart';
import '../models/inspection.dart';
import '../models/inspection_sync_status.dart';

final class InspectionsRepository {
  InspectionsRepository({
    required InspectionsLocalDataSource localDataSource,
    Uuid? uuid,
  }) : _localDataSource = localDataSource,
       _uuid = uuid ?? const Uuid();

  final InspectionsLocalDataSource _localDataSource;
  final Uuid _uuid;

  Future<Inspection> createDraft({required String workOrderId}) async {
    final now = DateTime.now();

    final inspection = Inspection(
      clientId: _uuid.v4(),
      workOrderId: workOrderId,
      syncStatus: InspectionSyncStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _localDataSource.saveInspection(inspection);

      return inspection;
    } catch (_) {
      throw const InspectionsException('Não foi possível iniciar a inspeção.');
    }
  }

  Future<void> saveInspection(Inspection inspection) async {
    try {
      await _localDataSource.saveInspection(
        inspection.copyWith(updatedAt: DateTime.now()),
      );
    } catch (_) {
      throw const InspectionsException('Não foi possível salvar a inspeção.');
    }
  }

  Inspection? getInspectionByClientId(String clientId) {
    try {
      return _localDataSource.getInspectionByClientId(clientId);
    } on FormatException {
      throw const InspectionsException(
        'Os dados locais da inspeção são inválidos.',
      );
    }
  }

  List<Inspection> getInspectionsByWorkOrderId(String workOrderId) {
    try {
      return _localDataSource.getInspectionsByWorkOrderId(workOrderId);
    } on FormatException {
      throw const InspectionsException(
        'Os dados locais das inspeções são inválidos.',
      );
    }
  }
}

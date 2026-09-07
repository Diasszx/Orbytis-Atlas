import 'package:uuid/uuid.dart';

import '../datasources/inspections_local_data_source.dart';
import '../errors/inspections_exception.dart';
import '../models/inspection.dart';
import '../models/inspection_sync_status.dart';
import '../services/inspection_photo_service.dart';
import '../services/inspection_location_service.dart';

final class InspectionsRepository {
  InspectionsRepository({
    required InspectionsLocalDataSource localDataSource,
    required InspectionPhotoService photoService,
    required InspectionLocationService locationService,
    Uuid? uuid,
  }) : _localDataSource = localDataSource,
       _photoService = photoService,
       _locationService = locationService,
       _uuid = uuid ?? const Uuid();

  final InspectionsLocalDataSource _localDataSource;
  final InspectionPhotoService _photoService;
  final InspectionLocationService _locationService;
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

  Future<Inspection> getOrCreateDraft({required String workOrderId}) async {
    try {
      final existingDraft = _localDataSource.getDraftByWorkOrderId(
        workOrderId,
      );

      if (existingDraft != null) {
        return existingDraft;
      }

      final now = DateTime.now();
      final inspection = Inspection(
        clientId: _uuid.v4(),
        workOrderId: workOrderId,
        syncStatus: InspectionSyncStatus.draft,
        createdAt: now,
        updatedAt: now,
      );

      await _localDataSource.saveInspection(inspection);
      return inspection;
    } catch (_) {
      throw const InspectionsException('Não foi possível iniciar a inspeção.');
    }
  }

  Future<Inspection> saveInspection(Inspection inspection) async {
    try {
      final updatedInspection = inspection.copyWith(updatedAt: DateTime.now());

      await _localDataSource.saveInspection(updatedInspection);

      return updatedInspection;
    } catch (_) {
      throw const InspectionsException('Não foi possível salvar a inspeção.');
    }
  }

  Future<Inspection?> capturePhoto(Inspection inspection) async {
    try {
      final photoPath = await _photoService.capturePhoto(
        clientId: inspection.clientId,
      );

      if (photoPath == null) {
        return null;
      }

      final updatedInspection = inspection.copyWith(
        photoPath: photoPath,
        updatedAt: DateTime.now(),
      );

      await _localDataSource.saveInspection(updatedInspection);
      return updatedInspection;
    } catch (_) {
      throw const InspectionsException('Não foi possível registrar a foto.');
    }
  }

  Future<Inspection> registerLocation(Inspection inspection) async {
    try {
      final position = await _locationService.getCurrentPosition();
      final updatedInspection = inspection.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        updatedAt: DateTime.now(),
      );

      await _localDataSource.saveInspection(updatedInspection);
      return updatedInspection;
    } on InspectionLocationException catch (error) {
      throw InspectionsException(error.message);
    } catch (_) {
      throw const InspectionsException(
        'Não foi possível registrar a localização.',
      );
    }
  }

  Future<Inspection> completeInspection(Inspection inspection) async {
    final observation = inspection.observation?.trim();

    if (observation == null || observation.length < 10) {
      throw const InspectionsException(
        'A observação deve ter pelo menos 10 caracteres.',
      );
    }

    if (inspection.photoPath == null) {
      throw const InspectionsException(
        'Adicione uma foto antes de concluir a inspeção.',
      );
    }

    if (inspection.latitude == null || inspection.longitude == null) {
      throw const InspectionsException(
        'Registre a localização antes de concluir a inspeção.',
      );
    }

    final now = DateTime.now();
    final completedInspection = inspection.copyWith(
      observation: observation,
      syncStatus: InspectionSyncStatus.pending,
      capturedAt: inspection.capturedAt ?? now,
      updatedAt: now,
    );

    try {
      await _localDataSource.saveInspection(completedInspection);
      return completedInspection;
    } catch (_) {
      throw const InspectionsException('Não foi possível concluir a inspeção.');
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

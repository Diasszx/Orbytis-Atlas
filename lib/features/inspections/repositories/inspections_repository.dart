import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../core/errors/network_exception.dart';
import '../datasources/inspections_local_data_source.dart';
import '../datasources/inspections_remote_data_source.dart';
import '../errors/inspections_exception.dart';
import '../models/inspection.dart';
import '../models/inspection_sync_status.dart';
import '../services/inspection_location_service.dart';
import '../services/inspection_photo_service.dart';

final class InspectionsRepository {
  InspectionsRepository({
    required this._localDataSource,
    required this._remoteDataSource,
    required this._photoService,
    required this._locationService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final InspectionsLocalDataSource _localDataSource;
  final InspectionsRemoteDataSource _remoteDataSource;
  final InspectionPhotoService _photoService;
  final InspectionLocationService _locationService;
  final Uuid _uuid;
  final Map<String, Future<Inspection>> _syncsInFlight = {};

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
      final existingDraft = _localDataSource.getDraftByWorkOrderId(workOrderId);

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

  Future<Inspection> syncInspection(String clientId) {
    return _syncsInFlight[clientId] ??= _syncAndRelease(clientId);
  }

  Future<Inspection> _syncAndRelease(String clientId) async {
    try {
      return await _syncInspection(clientId);
    } finally {
      // The caller already observes this Future; removing it only releases the key.
      unawaited(_syncsInFlight.remove(clientId));
    }
  }

  Future<Inspection> _syncInspection(String clientId) async {
    final inspection = _localDataSource.getInspectionByClientId(clientId);

    if (inspection == null) {
      throw const InspectionsException('Inspeção não encontrada.');
    }

    if (inspection.syncStatus == InspectionSyncStatus.draft) {
      throw const InspectionsException(
        'Rascunhos não podem ser sincronizados.',
      );
    }

    if (inspection.syncStatus == InspectionSyncStatus.synced) {
      return inspection;
    }

    try {
      final serverId = await _remoteDataSource.submitInspection(inspection);
      final syncedInspection = inspection.copyWith(
        serverId: serverId,
        syncStatus: InspectionSyncStatus.synced,
        clearSyncError: true,
        updatedAt: DateTime.now(),
      );

      await _localDataSource.saveInspection(syncedInspection);
      return syncedInspection;
    } on NetworkException catch (error) {
      return _handleSyncNetworkError(inspection, error);
    } on FormatException {
      final failedInspection = inspection.copyWith(
        syncStatus: InspectionSyncStatus.failed,
        syncError: 'Os dados da inspeção são inválidos.',
        updatedAt: DateTime.now(),
      );

      await _localDataSource.saveInspection(failedInspection);
      return failedInspection;
    }
  }

  Future<void> syncPendingInspections() async {
    final pendingInspections = _localDataSource.getPendingInspections();

    for (final inspection in pendingInspections) {
      final result = await syncInspection(inspection.clientId);

      if (result.syncStatus == InspectionSyncStatus.pending) {
        return;
      }
    }
  }

  Future<Inspection> _handleSyncNetworkError(
    Inspection inspection,
    NetworkException error,
  ) async {
    if (error.type == NetworkErrorType.unauthorized) {
      throw const InspectionsException(
        'Sua sessão expirou. Faça login novamente.',
      );
    }

    final isRejectedByServer =
        error.type == NetworkErrorType.badResponse &&
        error.statusCode != null &&
        error.statusCode! >= 400 &&
        error.statusCode! < 500;
    final updatedInspection = inspection.copyWith(
      syncStatus: isRejectedByServer
          ? InspectionSyncStatus.failed
          : InspectionSyncStatus.pending,
      syncError: _syncErrorMessage(error),
      updatedAt: DateTime.now(),
    );

    await _localDataSource.saveInspection(updatedInspection);
    return updatedInspection;
  }

  String _syncErrorMessage(NetworkException error) {
    return switch (error.type) {
      NetworkErrorType.timeout => 'A sincronização excedeu o tempo limite.',
      NetworkErrorType.connection =>
        'Sem conexão. A inspeção continuará aguardando sincronização.',
      NetworkErrorType.badResponse =>
        'O servidor recusou os dados da inspeção.',
      NetworkErrorType.cancelled => 'A sincronização foi cancelada.',
      NetworkErrorType.badCertificate =>
        'Não foi possível estabelecer uma conexão segura.',
      NetworkErrorType.unauthorized => 'Sua sessão expirou.',
      NetworkErrorType.unknown => 'Não foi possível sincronizar a inspeção.',
    };
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

  List<Inspection> getInspections() {
    try {
      final inspections = _localDataSource.getInspections();

      inspections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return inspections;
    } on FormatException {
      throw const InspectionsException(
        'Os dados locais das inspeções são inválidos.',
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

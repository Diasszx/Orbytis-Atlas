import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/features/inspections/datasources/inspections_local_data_source.dart';
import 'package:orbytis_atlas/features/inspections/datasources/inspections_remote_data_source.dart';
import 'package:orbytis_atlas/features/inspections/errors/inspections_exception.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/inspections/services/inspection_location_service.dart';
import 'package:orbytis_atlas/features/inspections/services/inspection_photo_service.dart';

final class MockInspectionsLocalDataSource extends Mock
    implements InspectionsLocalDataSource {}

final class MockInspectionsRemoteDataSource extends Mock
    implements InspectionsRemoteDataSource {}

final class MockInspectionPhotoService extends Mock
    implements InspectionPhotoService {}

final class MockInspectionLocationService extends Mock
    implements InspectionLocationService {}

void main() {
  late MockInspectionsLocalDataSource localDataSource;
  late MockInspectionsRemoteDataSource remoteDataSource;
  late MockInspectionPhotoService photoService;
  late MockInspectionLocationService locationService;
  late InspectionsRepository repository;

  setUpAll(() {
    registerFallbackValue(
      _buildInspection(syncStatus: InspectionSyncStatus.pending),
    );
  });

  setUp(() {
    localDataSource = MockInspectionsLocalDataSource();
    remoteDataSource = MockInspectionsRemoteDataSource();
    photoService = MockInspectionPhotoService();
    locationService = MockInspectionLocationService();
    repository = InspectionsRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      photoService: photoService,
      locationService: locationService,
    );

    when(() => localDataSource.saveInspection(any())).thenAnswer((_) async {});
  });

  group('syncInspection', () {
    test('marks pending inspection as synced when API succeeds', () async {
      final inspection = _buildInspection(syncStatus: InspectionSyncStatus.pending);
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);
      when(() => remoteDataSource.submitInspection(any())).thenAnswer(
        (_) async => 'server_001',
      );

      final result = await repository.syncInspection(inspection.clientId);

      expect(result.syncStatus, InspectionSyncStatus.synced);
      expect(result.serverId, 'server_001');

      final captured = verify(
        () => localDataSource.saveInspection(captureAny()),
      ).captured.single as Inspection;
      expect(captured.syncStatus, InspectionSyncStatus.synced);
      expect(captured.serverId, 'server_001');
    });

    test('preserves clientId when synchronizing inspection', () async {
      final inspection = _buildInspection(syncStatus: InspectionSyncStatus.pending);
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);
      when(() => remoteDataSource.submitInspection(any())).thenAnswer(
        (_) async => 'server_001',
      );

      await repository.syncInspection(inspection.clientId);

      final submittedInspection = verify(
        () => remoteDataSource.submitInspection(captureAny()),
      ).captured.single as Inspection;
      expect(submittedInspection.clientId, inspection.clientId);
    });

    test('keeps inspection pending when connection fails', () async {
      final inspection = _buildInspection(syncStatus: InspectionSyncStatus.pending);
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);
      when(() => remoteDataSource.submitInspection(any())).thenThrow(
        const NetworkException(type: NetworkErrorType.connection),
      );

      final result = await repository.syncInspection(inspection.clientId);

      expect(result.syncStatus, InspectionSyncStatus.pending);
      expect(result.syncError, isNotNull);

      final captured = verify(
        () => localDataSource.saveInspection(captureAny()),
      ).captured.single as Inspection;
      expect(captured.syncStatus, InspectionSyncStatus.pending);
    });

    test('marks inspection as failed when server rejects payload', () async {
      final inspection = _buildInspection(syncStatus: InspectionSyncStatus.pending);
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);
      when(() => remoteDataSource.submitInspection(any())).thenThrow(
        const NetworkException(
          type: NetworkErrorType.badResponse,
          statusCode: 400,
        ),
      );

      final result = await repository.syncInspection(inspection.clientId);

      expect(result.syncStatus, InspectionSyncStatus.failed);
      expect(result.syncError, isNotNull);

      final captured = verify(
        () => localDataSource.saveInspection(captureAny()),
      ).captured.single as Inspection;
      expect(captured.syncStatus, InspectionSyncStatus.failed);
    });

    test('does not synchronize draft inspection', () async {
      final inspection = _buildInspection(syncStatus: InspectionSyncStatus.draft);
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);

      expect(
        () => repository.syncInspection(inspection.clientId),
        throwsA(isA<InspectionsException>()),
      );
      verifyNever(() => remoteDataSource.submitInspection(any()));
    });

    test('does not send already synced inspection again', () async {
      final inspection = _buildInspection(
        syncStatus: InspectionSyncStatus.synced,
        serverId: 'server_001',
      );
      when(
        () => localDataSource.getInspectionByClientId(inspection.clientId),
      ).thenReturn(inspection);

      final result = await repository.syncInspection(inspection.clientId);

      expect(result.syncStatus, InspectionSyncStatus.synced);
      expect(result.serverId, 'server_001');
      verifyNever(() => remoteDataSource.submitInspection(any()));
    });
  });
}

Inspection _buildInspection({
  required InspectionSyncStatus syncStatus,
  String? serverId,
}) {
  final now = DateTime(2026, 9, 8, 10);

  return Inspection(
    clientId: 'client-001',
    serverId: serverId,
    workOrderId: 'wo_1001',
    observation: 'Poste apresenta rachadura próxima à base.',
    condition: 'regular',
    photoPath: '/inspection_photos/client-001.jpg',
    latitude: -7.1195,
    longitude: -34.8450,
    capturedAt: now,
    syncStatus: syncStatus,
    createdAt: now,
    updatedAt: now,
  );
}

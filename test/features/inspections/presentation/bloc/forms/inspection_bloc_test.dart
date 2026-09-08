import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/datasources/inspections_local_data_source.dart';
import 'package:orbytis_atlas/features/inspections/datasources/inspections_remote_data_source.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';
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
    registerFallbackValue(_buildDraft());
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

  group('InspectionBloc', () {
    blocTest<InspectionBloc, InspectionState>(
      'loads draft by clientId',
      build: () {
        final inspection = _buildDraft();
        when(
          () => localDataSource.getInspectionByClientId(inspection.clientId),
        ).thenReturn(inspection);

        return InspectionBloc(repository);
      },
      act: (bloc) => bloc.add(const InspectionRequested('client-001')),
      expect: () => [
        isA<InspectionLoading>(),
        isA<InspectionLoaded>().having(
          (state) => state.inspection.clientId,
          'clientId',
          'client-001',
        ),
      ],
    );

    blocTest<InspectionBloc, InspectionState>(
      'autosaves observation after debounce',
      build: () => InspectionBloc(repository),
      seed: () => InspectionLoaded(_buildDraft()),
      act: (bloc) => bloc.add(
        const InspectionObservationChanged(
          'Poste apresenta rachadura próxima à base.',
        ),
      ),
      wait: const Duration(milliseconds: 900),
      expect: () => [
        isA<InspectionLoaded>()
            .having(
              (state) => state.inspection.observation,
              'observation',
              'Poste apresenta rachadura próxima à base.',
            )
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              InspectionSaveStatus.unsaved,
            ),
        isA<InspectionLoaded>().having(
          (state) => state.saveStatus,
          'saveStatus',
          InspectionSaveStatus.saving,
        ),
        isA<InspectionLoaded>()
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              InspectionSaveStatus.saved,
            )
            .having(
              (state) => state.inspection.observation,
              'observation',
              'Poste apresenta rachadura próxima à base.',
            ),
      ],
      verify: (_) {
        final savedInspection = verify(
          () => localDataSource.saveInspection(captureAny()),
        ).captured.single as Inspection;
        expect(
          savedInspection.observation,
          'Poste apresenta rachadura próxima à base.',
        );
      },
    );

    blocTest<InspectionBloc, InspectionState>(
      'changes draft to pending when inspection is valid and completed',
      build: () => InspectionBloc(repository),
      seed: () => InspectionLoaded(_buildCompleteDraft()),
      act: (bloc) => bloc.add(const InspectionConclusionRequested()),
      expect: () => [
        isA<InspectionConcluding>(),
        isA<InspectionConclusionSuccess>().having(
          (state) => state.inspection.syncStatus,
          'syncStatus',
          InspectionSyncStatus.pending,
        ),
      ],
      verify: (_) {
        final savedInspection = verify(
          () => localDataSource.saveInspection(captureAny()),
        ).captured.single as Inspection;
        expect(savedInspection.syncStatus, InspectionSyncStatus.pending);
        expect(savedInspection.capturedAt, isNotNull);
      },
    );

    blocTest<InspectionBloc, InspectionState>(
      'does not complete inspection when required data is missing',
      build: () => InspectionBloc(repository),
      seed: () => InspectionLoaded(
        _buildDraft(observation: 'Observação válida para teste.'),
      ),
      act: (bloc) => bloc.add(const InspectionConclusionRequested()),
      expect: () => [
        isA<InspectionConcluding>(),
        isA<InspectionValidationFailure>().having(
          (state) => state.message,
          'message',
          contains('foto'),
        ),
      ],
      verify: (_) {
        verifyNever(() => localDataSource.saveInspection(any()));
      },
    );
  });
}

Inspection _buildDraft({String? observation}) {
  final now = DateTime(2026, 9, 8, 10);

  return Inspection(
    clientId: 'client-001',
    workOrderId: 'wo_1001',
    observation: observation,
    syncStatus: InspectionSyncStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
}

Inspection _buildCompleteDraft() {
  final now = DateTime(2026, 9, 8, 10);

  return Inspection(
    clientId: 'client-001',
    workOrderId: 'wo_1001',
    observation: 'Poste apresenta rachadura próxima à base.',
    condition: 'regular',
    photoPath: '/inspection_photos/client-001.jpg',
    latitude: -7.1195,
    longitude: -34.8450,
    syncStatus: InspectionSyncStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
}

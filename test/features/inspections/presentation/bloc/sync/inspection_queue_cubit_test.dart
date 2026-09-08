import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/sync/inspection_queue_cubit.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';

import '../../../repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;

void main() {
  late MockInspectionsLocalDataSource local;
  late MockInspectionsRemoteDataSource remote;
  late InspectionQueueCubit cubit;
  late Inspection item;
  setUpAll(
    () => registerFallbackValue(
      Inspection(
        clientId: 'a',
        workOrderId: 'os',
        syncStatus: InspectionSyncStatus.pending,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ),
  );
  setUp(() {
    local = MockInspectionsLocalDataSource();
    remote = MockInspectionsRemoteDataSource();
    item = Inspection(
      clientId: 'a',
      workOrderId: 'os',
      syncStatus: InspectionSyncStatus.pending,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => local.getInspections()).thenAnswer((_) => [item]);
    when(() => local.getPendingInspections()).thenAnswer((_) => [item]);
    when(() => local.getInspectionByClientId('a')).thenAnswer((_) => item);
    when(() => local.saveInspection(any())).thenAnswer((call) async {
      item = call.positionalArguments.first as Inspection;
    });
    cubit = InspectionQueueCubit(
      InspectionsRepository(
        localDataSource: local,
        remoteDataSource: remote,
        photoService: MockInspectionPhotoService(),
        locationService: MockInspectionLocationService(),
      ),
    );
  });
  tearDown(() => cubit.close());

  test(
    'manual queue reports success and ignores repeated taps while uploading',
    () async {
      final upload = Completer<String>();
      when(() => remote.submitInspection(any()))
          .thenAnswer((_) => upload.future);
      final run = cubit.synchronize();
      expect(cubit.state.isSyncing, isTrue);
      await cubit.synchronize();
      verify(() => remote.submitInspection(any())).called(1);
      upload.complete('server');
      await run;
      expect(cubit.state.isSyncing, isFalse);
      expect(
        cubit.state.message,
        contains('1 sincronizada(s), 0 pendente(s), 0 com falha'),
      );
    },
  );
  test('empty queue does not upload', () async {
    when(() => local.getInspections()).thenReturn([]);
    await cubit.synchronize();
    expect(cubit.state.message, contains('Nenhuma inspeção pendente'));
    verifyNever(() => remote.submitInspection(any()));
  });
  for (final rejected in [false, true]) {
    test(
      'reports pending or rejected result without claiming success: $rejected',
      () async {
        when(() => remote.submitInspection(any())).thenThrow(
          NetworkException(
            type: rejected
                ? NetworkErrorType.badResponse
                : NetworkErrorType.connection,
            statusCode: rejected ? 400 : null,
          ),
        );
        await cubit.synchronize();
        expect(cubit.state.isSyncing, isFalse);
        expect(
          cubit.state.message,
          contains(
            rejected
                ? '0 sincronizada(s), 0 pendente(s), 1 com falha'
                : '0 sincronizada(s), 1 pendente(s), 0 com falha',
          ),
        );
      },
    );
  }
}

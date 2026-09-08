import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/inspections/services/inspection_sync_coordinator.dart';

import '../repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockConnectivity connectivity;
  late InspectionsRepository repository;
  late MockInspectionsLocalDataSource local;
  late MockInspectionsRemoteDataSource remote;
  late StreamController<List<ConnectivityResult>> network;
  late InspectionSyncCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(
      Inspection(
        clientId: 'fallback',
        workOrderId: 'os',
        syncStatus: InspectionSyncStatus.pending,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });
  setUp(() {
    connectivity = MockConnectivity();
    local = MockInspectionsLocalDataSource();
    remote = MockInspectionsRemoteDataSource();
    repository = InspectionsRepository(
      localDataSource: local,
      remoteDataSource: remote,
      photoService: MockInspectionPhotoService(),
      locationService: MockInspectionLocationService(),
    );
    final item = Inspection(
      clientId: 'a',
      workOrderId: 'os',
      syncStatus: InspectionSyncStatus.pending,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => local.getPendingInspections()).thenReturn([item]);
    when(() => local.getInspectionByClientId('a')).thenReturn(item);
    when(() => local.saveInspection(any())).thenAnswer((_) async {});
    network = StreamController<List<ConnectivityResult>>();
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => network.stream);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    coordinator = InspectionSyncCoordinator(
      inspectionsRepository: repository,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await coordinator.stop();
    await network.close();
  });

  for (final fails in [false, true]) {
    test(
      'coalesces startup, network and foreground; first pass fails: $fails',
      () async {
        final first = Completer<String>();
        var calls = 0;
        when(() => local.getPendingInspections()).thenAnswer((_) {
          calls++;
          return calls == 1 ? [local.getInspectionByClientId('a')!] : [];
        });
        when(() => remote.submitInspection(any()))
            .thenAnswer((_) => first.future);
        final started = coordinator.start();
        await Future<void>.delayed(Duration.zero);
        await coordinator.start();
        network.add([ConnectivityResult.wifi]);
        network.add([ConnectivityResult.mobile]);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future<void>.delayed(Duration.zero);
        expect(calls, 1);
        if (fails) {
          first.completeError(StateError('upload failed'));
        } else {
          first.complete('server');
        }
        await started;
        expect(calls, 2);
        await Future<void>.delayed(Duration.zero);
        expect(calls, 2);
      },
    );
  }

  test(
    'stop discards a queued pass while allowing active sync to finish',
    () async {
      final first = Completer<String>();

      when(() => remote.submitInspection(any()))
          .thenAnswer((_) => first.future);
      final started = coordinator.start();
      await Future<void>.delayed(Duration.zero);
      network.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      await coordinator.stop();
      first.complete('server');
      await started;
      verify(() => local.getPendingInspections()).called(1);
    },
  );

  test('a failure without a new trigger does not retry in a loop', () async {
    when(() => local.getPendingInspections()).thenThrow(StateError('failed'));
    await coordinator.start();
    await Future<void>.delayed(Duration.zero);
    verify(() => local.getPendingInspections()).called(1);
  });
}

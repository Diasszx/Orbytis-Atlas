import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_state.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';

import '../../repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;

void main() {
  test('OS scope persists through filters, refresh and retry; general history includes all', () async {
    Inspection item(String id, String os, InspectionSyncStatus status) =>
        Inspection(
          clientId: id,
          workOrderId: os,
          syncStatus: status,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
    final failed = item('failed', 'wo_1', InspectionSyncStatus.failed);
    registerFallbackValue(failed);
    final items = [
      failed,
      item('draft', 'wo_1', InspectionSyncStatus.draft),
      item('other', 'wo_2', InspectionSyncStatus.failed),
    ];
    final local = MockInspectionsLocalDataSource();
    final remote = MockInspectionsRemoteDataSource();
    when(() => local.getInspections()).thenAnswer((_) => items.toList());
    when(() => local.getInspectionByClientId('failed')).thenReturn(failed);
    when(() => remote.submitInspection(failed))
        .thenAnswer((_) async => 'server-id');
    when(() => local.saveInspection(any())).thenAnswer((call) async {
      final saved = call.positionalArguments.first as Inspection;
      items[items.indexWhere((item) => item.clientId == saved.clientId)] =
          saved;
    });
    final repository = InspectionsRepository(
      localDataSource: local,
      remoteDataSource: remote,
      photoService: MockInspectionPhotoService(),
      locationService: MockInspectionLocationService(),
    );
    final bloc = InspectionHistoryBloc(repository, workOrderId: 'wo_1');
    Future<InspectionHistoryLoaded> load(InspectionHistoryEvent event) async {
      final expectedFilter = event is InspectionHistoryFilterChanged
          ? event.filter
          : bloc.state is InspectionHistoryLoaded
          ? (bloc.state as InspectionHistoryLoaded).filter
          : InspectionHistoryFilter.all;
      final result = bloc.stream.firstWhere(
        (state) =>
            state is InspectionHistoryLoaded && state.filter == expectedFilter,
      );
      bloc.add(event);
      return await result as InspectionHistoryLoaded;
    }

    expect(
      (await load(const InspectionHistoryRequested())).inspections.length,
      2,
    );
    expect(
      (await load(
        const InspectionHistoryFilterChanged(InspectionHistoryFilter.failed),
      )).inspections.map((item) => item.clientId),
      ['failed'],
    );
    expect(
      (await load(const InspectionHistoryRequested())).inspections.length,
      1,
    );
    final retried = bloc.stream.firstWhere(
      (state) =>
          state is InspectionHistoryLoaded && state.feedbackMessage != null,
    );
    bloc.add(const InspectionHistoryRetryRequested('failed'));
    final result = await retried as InspectionHistoryLoaded;
    expect(
      result.inspections.every((item) => item.workOrderId == 'wo_1'),
      isTrue,
    );
    expect(result.filter, InspectionHistoryFilter.failed);
    expect(result.inspections, isEmpty);
    expect(
      (await load(
        const InspectionHistoryFilterChanged(InspectionHistoryFilter.synced),
      )).inspections.map((item) => item.clientId),
      ['failed'],
    );
    final general = InspectionHistoryBloc(repository);
    final loaded = general.stream.firstWhere(
      (state) => state is InspectionHistoryLoaded,
    );
    general.add(const InspectionHistoryRequested());
    expect((await loaded as InspectionHistoryLoaded).inspections.length, 3);
    await bloc.close();
    await general.close();
    await repository.dispose();
  });
}

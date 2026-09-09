import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/pages/inspection_history_page.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/widgets/inspection_history_card.dart';

import '../../repositories/inspections_repository_test.dart'
    show MockInspectionsLocalDataSource, MockInspectionsRemoteDataSource,
        MockInspectionPhotoService, MockInspectionLocationService;

void main() {
  for (final empty in [true, false]) {
    testWidgets('history fills phone screen with one back button (empty: $empty)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final local = MockInspectionsLocalDataSource();
      when(() => local.getInspections()).thenReturn(
        empty ? [] : List.generate(10, (index) => Inspection.fromJson({
          ..._buildInspection(syncStatus: InspectionSyncStatus.synced).toJson(),
          'clientId': 'client-$index',
        })),
      );
      final bloc = InspectionHistoryBloc(InspectionsRepository(
        localDataSource: local,
        remoteDataSource: MockInspectionsRemoteDataSource(),
        photoService: MockInspectionPhotoService(),
        locationService: MockInspectionLocationService(),
      ))..add(const InspectionHistoryRequested());
      addTearDown(bloc.close);
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: Builder(builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(value: bloc, child: const InspectionHistoryPage()),
          )),
          child: const Text('Abrir histórico'),
        )),
      )));
      await tester.tap(find.text('Abrir histórico'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Inspeções'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      if (empty) {
        expect(find.text('Nenhuma inspeção encontrada'), findsOneWidget);
      } else {
        expect(tester.getSize(find.byType(ListView)).height, greaterThan(400));
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text('Abrir histórico'), findsOneWidget);
      expect(find.text('Inspeções'), findsNothing);
    });
  }

  testWidgets('shows synced status for synced inspection', (tester) async {
    final inspection = _buildInspection(syncStatus: InspectionSyncStatus.synced);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InspectionHistoryCard(inspection: inspection)),
      ),
    );

    expect(find.text('Sincronizada'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
  });

  testWidgets('shows retry action for failed inspection', (tester) async {
    final inspection = _buildInspection(syncStatus: InspectionSyncStatus.failed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionHistoryCard(inspection: inspection, onRetry: () {}),
        ),
      ),
    );

    expect(find.text('Falha na sincronização'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}

Inspection _buildInspection({required InspectionSyncStatus syncStatus}) {
  final now = DateTime(2026, 9, 8, 14);

  return Inspection(
    clientId: 'client-001',
    workOrderId: 'wo_1001',
    observation: 'Poste apresenta rachadura próxima à base.',
    photoPath: '/inspection_photos/client-001.jpg',
    latitude: -7.1195,
    longitude: -34.8450,
    syncStatus: syncStatus,
    createdAt: now,
    updatedAt: now,
  );
}

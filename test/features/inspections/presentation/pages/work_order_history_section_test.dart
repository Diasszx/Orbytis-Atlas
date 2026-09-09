import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/widgets/inspection_history_card.dart';
import 'package:orbytis_atlas/features/inspections/presentation/widgets/work_order_history_section.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';

import '../../repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;

void main() {
  testWidgets(
    'embedded history excludes drafts and other OS, expands and reacts to sync',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Inspection item(String id, String os, InspectionSyncStatus status) =>
          Inspection(
            clientId: id,
            workOrderId: os,
            syncStatus: status,
            observation: 'Observação completa da inspeção $id.',
            latitude: -7.123,
            longitude: -34.845,
            photoPath: 'missing-photo.jpg',
            capturedAt: DateTime(2026, 9, 8, 12),
            createdAt: DateTime(2026, 9, 7),
            updatedAt: DateTime(2026, 9, 10),
          );
      final completed = item('completed', 'wo_1', InspectionSyncStatus.pending);
      registerFallbackValue(completed);
      final items = [
        completed,
        item('draft', 'wo_1', InspectionSyncStatus.draft),
        item('other', 'wo_2', InspectionSyncStatus.synced),
      ];
      final local = MockInspectionsLocalDataSource();
      final remote = MockInspectionsRemoteDataSource();
      when(() => local.getInspections()).thenAnswer((_) => items.toList());
      when(() => local.getInspectionByClientId('completed'))
          .thenAnswer((_) => items.first);
      when(() => local.saveInspection(any())).thenAnswer((call) async {
        items[0] = call.positionalArguments.first as Inspection;
      });
      when(() => remote.submitInspection(any()))
          .thenAnswer((_) async => 'server-id');
      final repository = InspectionsRepository(
        localDataSource: local,
        remoteDataSource: remote,
        photoService: MockInspectionPhotoService(),
        locationService: MockInspectionLocationService(),
      );
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: repository,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkOrderHistorySection(workOrderId: 'wo_1'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InspectionHistoryCard), findsOneWidget);
      expect(find.text('Rascunho'), findsNothing);
      expect(find.text('Inspeção • 08/09/2026 às 12:00'), findsOneWidget);
      expect(
        find.text('Observação completa da inspeção completed.'),
        findsNothing,
      );
      await tester.tap(find.text('Inspeção • 08/09/2026 às 12:00'));
      await tester.pumpAndSettle();
      // File image loading uses real I/O, outside the test's fake clock.
      final imageError = find.text('Foto indisponível neste dispositivo.');
      for (
        var attempt = 0;
        attempt < 500 && imageError.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(
        find.text('Observação completa da inspeção completed.'),
        findsOneWidget,
      );
      expect(find.text('-7.123, -34.845'), findsOneWidget);
      expect(find.text('Foto indisponível neste dispositivo.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Inspeção • 08/09/2026 às 12:00'));
      await tester.pumpAndSettle();
      expect(
        find.text('Observação completa da inspeção completed.'),
        findsNothing,
      );
      await tester.tap(find.text('Inspeção • 08/09/2026 às 12:00'));
      await tester.pumpAndSettle();
      expect(
        find.text('Observação completa da inspeção completed.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Pendentes'));
      await tester.pumpAndSettle();
      await repository.syncInspection('completed');
      await tester.pumpAndSettle();
      expect(find.byType(InspectionHistoryCard), findsNothing);
      await tester.tap(find.text('Atualizar histórico'));
      await tester.pumpAndSettle();
      expect(find.byType(InspectionHistoryCard), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pendentes'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Sincronizadas'));
      await tester.pumpAndSettle();
      expect(find.byType(InspectionHistoryCard), findsOneWidget);
      expect(find.text('Sincronizada'), findsOneWidget);
      expect(
        find.text('Observação completa da inspeção completed.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Inspeção • 08/09/2026 às 12:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(repository.dispose);
    },
  );
}

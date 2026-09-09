import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/inspection_start_bloc.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_order_details_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_order_details_event.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_order_details_page.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/widgets/work_order_card.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

import '../../inspections/repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;
import '../repositories/work_orders_repository_test.dart'
    show MockWorkOrdersLocalDataSource, MockWorkOrdersRemoteDataSource;

void main() {
  final order = WorkOrder(
    id: 'os-1',
    code: 'OS-1',
    title: 'Inspeção de campo',
    description: 'Verificar equipamento',
    address: 'Rua A',
    priority: 'high',
    status: 'open',
    latitude: 0,
    longitude: 0,
    scheduledAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  Inspection inspection(String id, InspectionSyncStatus status) => Inspection(
    clientId: id,
    workOrderId: order.id,
    syncStatus: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  setUpAll(
    () => registerFallbackValue(
      inspection('fallback', InspectionSyncStatus.draft),
    ),
  );

  testWidgets('OS shows mixed states and updates after synchronization', (
    tester,
  ) async {
    final local = MockInspectionsLocalDataSource();
    final remote = MockInspectionsRemoteDataSource();
    final items = [
      inspection('pending', InspectionSyncStatus.pending),
      inspection('failed', InspectionSyncStatus.failed),
      inspection('synced', InspectionSyncStatus.synced),
    ];
    when(() => local.getInspectionsByWorkOrderId(order.id))
        .thenAnswer((_) => items.toList());
    when(() => local.getInspectionByClientId('pending'))
        .thenAnswer((_) => items.first);
    when(() => local.saveInspection(any())).thenAnswer((call) async {
      final saved = call.positionalArguments.first as Inspection;
      items[items.indexWhere((item) => item.clientId == saved.clientId)] =
          saved;
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
        child: MaterialApp(
          home: Scaffold(body: WorkOrderCard(workOrder: order)),
        ),
      ),
    );
    expect(find.text('1 inspeção aguardando envio'), findsOneWidget);
    expect(find.text('ID da OS: os-1'), findsNothing);
    expect(find.text('Finalizada'), findsOneWidget);
    expect(find.text('1 inspeção com falha no envio'), findsOneWidget);
    expect(find.text('1 inspeção sincronizada'), findsOneWidget);
    await repository.syncInspection('pending');
    await tester.pumpAndSettle();
    expect(find.text('1 inspeção aguardando envio'), findsNothing);
    expect(find.text('2 inspeções sincronizadas'), findsOneWidget);
    expect(find.text('1 inspeção com falha no envio'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(repository.dispose);
  });

  testWidgets('detail changes start to continue when a draft is persisted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final local = MockInspectionsLocalDataSource();
    final items = <Inspection>[];
    when(() => local.getInspections()).thenAnswer((_) => items.toList());
    when(() => local.getInspectionsByWorkOrderId(order.id))
        .thenAnswer((_) => items.toList());
    when(() => local.saveInspection(any())).thenAnswer((call) async {
      final saved = call.positionalArguments.first as Inspection;
      final index = items.indexWhere(
        (inspection) => inspection.clientId == saved.clientId,
      );
      if (index == -1) {
        items.add(saved);
      } else {
        items[index] = saved;
      }
    });
    final repository = InspectionsRepository(
      localDataSource: local,
      remoteDataSource: MockInspectionsRemoteDataSource(),
      photoService: MockInspectionPhotoService(),
      locationService: MockInspectionLocationService(),
    );
    final remoteOrders = MockWorkOrdersRemoteDataSource();
    final localOrders = MockWorkOrdersLocalDataSource();
    when(() => remoteOrders.getWorkOrderById(order.id))
        .thenAnswer((_) async => order);

    final details = WorkOrderDetailsBloc(
      WorkOrdersRepository(
        remoteDataSource: remoteOrders,
        localDataSource: localOrders,
      ),
    )..add(WorkOrderDetailsRequested(order.id));
    final start = InspectionStartBloc(repository);
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: details),
            BlocProvider.value(value: start),
          ],
          child: const MaterialApp(home: WorkOrderDetailsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iniciar inspeção'), findsOneWidget);
    expect(find.text('Aberta'), findsOneWidget);
    final draft = await repository.createDraft(workOrderId: order.id);
    await tester.pumpAndSettle();
    expect(find.text('Continuar inspeção'), findsOneWidget);
    expect(find.text('Em andamento'), findsOneWidget);
    expect(find.text('Iniciar inspeção'), findsNothing);
    expect(find.text('1 inspeção em rascunho'), findsOneWidget);
    await repository.saveInspection(
      draft.copyWith(syncStatus: InspectionSyncStatus.pending),
    );
    await tester.pumpAndSettle();
    expect(find.text('Finalizada'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(details.close);
    await tester.runAsync(start.close);
    await tester.runAsync(repository.dispose);
  });
}

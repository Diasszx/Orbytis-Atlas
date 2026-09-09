import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/sync/inspection_queue_cubit.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_orders_page.dart';
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
  testWidgets('search filters codes locally and combines with status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkOrder order(String id, String code, String status) => WorkOrder(
      id: id,
      code: code,
      status: status,
      title: 'Inspeção',
      description: '',
      address: 'Rua A',
      priority: 'high',
      latitude: 0,
      longitude: 0,
      scheduledAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final items = [
      order('wo_1', 'OS-2026-001', 'open'),
      order('wo_2', 'OS-2026-002', 'done'),
    ];
    final remote = MockWorkOrdersRemoteDataSource();
    final local = MockWorkOrdersLocalDataSource();
    when(() => remote.getWorkOrders(status: null))
        .thenAnswer((_) async => items);
    when(() => remote.getWorkOrders(status: 'done'))
        .thenAnswer((_) async => [items.last]);
    when(() => local.saveWorkOrders(items)).thenAnswer((_) async {});
    final orders = WorkOrdersBloc(
      WorkOrdersRepository(remoteDataSource: remote, localDataSource: local),
    );
    final inspectionLocal = MockInspectionsLocalDataSource();
    when(() => inspectionLocal.getInspectionsByWorkOrderId(any()))
        .thenReturn([]);
    final repository = InspectionsRepository(
      localDataSource: inspectionLocal,
      remoteDataSource: MockInspectionsRemoteDataSource(),
      photoService: MockInspectionPhotoService(),
      locationService: MockInspectionLocationService(),
    );
    final queue = InspectionQueueCubit(repository);
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: orders),
            BlocProvider.value(value: queue),
          ],
          child: const MaterialApp(home: WorkOrdersPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('OS-2026-001'), findsOneWidget);
    expect(find.text('ID da OS: wo_1'), findsNothing);
    await tester.enterText(find.byType(TextField), '  os-2026-001  ');
    await tester.pumpAndSettle();
    expect(find.text('OS-2026-001'), findsOneWidget);
    expect(find.text('OS-2026-002'), findsNothing);
    verify(() => remote.getWorkOrders(status: null)).called(1);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizadas').last);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma ordem encontrada'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('OS-2026-002'), findsOneWidget);
    expect(find.text('OS-2026-001'), findsNothing);
    await tester.enterText(find.byType(TextField), '002');
    await tester.pumpAndSettle();
    expect(find.text('OS-2026-002'), findsOneWidget);
    verify(() => remote.getWorkOrders(status: 'done')).called(1);
    verifyNoMoreInteractions(remote);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await orders.close();
      await queue.close();
      await repository.dispose();
    });
  });

  testWidgets('empty OS list refresh finishes and general sync is available', (
    tester,
  ) async {
    final remote = MockWorkOrdersRemoteDataSource();
    final local = MockWorkOrdersLocalDataSource();
    when(() => remote.getWorkOrders(status: null)).thenAnswer((_) async => []);
    for (final status in ['open', 'in_progress', 'done']) {
      when(() => remote.getWorkOrders(status: status))
          .thenAnswer((_) async => []);
    }
    when(() => local.saveWorkOrders([])).thenAnswer((_) async {});
    final orders = WorkOrdersBloc(
      WorkOrdersRepository(remoteDataSource: remote, localDataSource: local),
    );
    final inspections = MockInspectionsLocalDataSource();
    when(() => inspections.getInspections()).thenReturn([]);
    final queue = InspectionQueueCubit(
      InspectionsRepository(
        localDataSource: inspections,
        remoteDataSource: MockInspectionsRemoteDataSource(),
        photoService: MockInspectionPhotoService(),
        locationService: MockInspectionLocationService(),
      ),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: orders),
          BlocProvider.value(value: queue),
        ],
        child: const MaterialApp(home: WorkOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma ordem encontrada'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    verify(() => remote.getWorkOrders(status: null)).called(2);
    for (final (label, status) in [
      ('Abertas', 'open'),
      ('Em andamento', 'in_progress'),
      ('Finalizadas', 'done'),
      ('Todas', null),
    ]) {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      verify(() => remote.getWorkOrders(status: status)).called(1);
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      verify(() => remote.getWorkOrders(status: status)).called(1);
    }
    await tester.tap(find.text('Sincronizar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma inspeção pendente. Consulte as falhas no histórico.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Sair'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await orders.close();
      await queue.close();
    });
  });
}

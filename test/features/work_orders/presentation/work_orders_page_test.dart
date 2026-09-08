import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/sync/inspection_queue_cubit.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
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
  testWidgets('empty OS list refresh finishes and general sync is available', (
    tester,
  ) async {
    final remote = MockWorkOrdersRemoteDataSource();
    final local = MockWorkOrdersLocalDataSource();
    when(() => remote.getWorkOrders(status: null)).thenAnswer((_) async => []);
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

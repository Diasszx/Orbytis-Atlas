import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';
import 'package:orbytis_atlas/features/inspections/presentation/pages/inspection_page.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';

import '../../repositories/inspections_repository_test.dart'
    show
        MockInspectionsLocalDataSource,
        MockInspectionsRemoteDataSource,
        MockInspectionPhotoService,
        MockInspectionLocationService;

void main() {
  setUpAll(() {
    registerFallbackValue(
      Inspection(
        clientId: 'fallback',
        workOrderId: 'fallback',
        syncStatus: InspectionSyncStatus.draft,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  testWidgets('saving draft returns to OS and save-and-exit is absent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final local = MockInspectionsLocalDataSource();
    when(() => local.saveInspection(any())).thenAnswer((_) async {});
    final repository = InspectionsRepository(
      localDataSource: local,
      remoteDataSource: MockInspectionsRemoteDataSource(),
      photoService: MockInspectionPhotoService(),
      locationService: MockInspectionLocationService(),
    );
    final bloc = InspectionBloc(repository);
    final draft = Inspection(
      clientId: 'draft-1',
      workOrderId: 'wo_1',
      observation: 'Rascunho da inspeção',
      syncStatus: InspectionSyncStatus.draft,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final router = GoRouter(
      initialLocation: '/work-order',
      routes: [
        GoRoute(
          path: '/work-order',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/inspection'),
              child: const Text('Abrir inspeção'),
            ),
          ),
        ),
        GoRoute(
          path: '/inspection',
          builder: (_, _) =>
              BlocProvider.value(value: bloc, child: const InspectionPage()),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Abrir inspeção'));
    bloc.emit(InspectionLoaded(draft));
    await tester.pumpAndSettle();
    expect(find.text('Salvar e sair'), findsNothing);
    await tester.tap(find.text('Salvar rascunho'));
    await tester.pumpAndSettle(const Duration(milliseconds: 1100));
    expect(find.text('Abrir inspeção'), findsOneWidget);
    verify(() => local.saveInspection(any())).called(1);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(bloc.close);
    await repository.dispose();
  });

  testWidgets('completion returns to OS without starting an upload', (
    tester,
  ) async {
    final remote = MockInspectionsRemoteDataSource();
    final bloc = InspectionBloc(
      InspectionsRepository(
        localDataSource: MockInspectionsLocalDataSource(),
        remoteDataSource: remote,
        photoService: MockInspectionPhotoService(),
        locationService: MockInspectionLocationService(),
      ),
    );
    final router = GoRouter(
      initialLocation: '/inspection',
      routes: [
        GoRoute(
          path: '/inspection',
          builder: (_, _) =>
              BlocProvider.value(value: bloc, child: const InspectionPage()),
        ),
        GoRoute(
          path: '/work-orders',
          builder: (_, _) => const Scaffold(body: Text('Lista de OS')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    bloc.emit(
      InspectionConclusionSuccess(
        Inspection(
          clientId: 'a',
          workOrderId: 'os',
          syncStatus: InspectionSyncStatus.pending,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lista de OS'), findsOneWidget);
    verifyZeroInteractions(remote);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(bloc.close);
  });
}

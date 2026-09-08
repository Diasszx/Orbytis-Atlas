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

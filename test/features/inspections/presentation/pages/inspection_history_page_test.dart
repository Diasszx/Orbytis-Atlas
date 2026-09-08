import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection_sync_status.dart';
import 'package:orbytis_atlas/features/inspections/presentation/widgets/inspection_history_card.dart';

void main() {
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

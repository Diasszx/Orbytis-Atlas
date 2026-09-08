import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sync/inspection_sync_bloc.dart';
import '../bloc/sync/inspection_sync_event.dart';
import '../bloc/sync/inspection_sync_state.dart';

final class InspectionSyncButton extends StatelessWidget {
  const InspectionSyncButton({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InspectionSyncBloc, InspectionSyncState>(
      listener: (context, state) {
        final message = switch (state) {
          InspectionSyncSuccess() => 'Inspeção sincronizada com sucesso.',
          InspectionSyncPending(:final message) => message,
          InspectionSyncFailure(:final message) => message,
          InspectionSyncInitial() || InspectionSyncLoading() => null,
        };

        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final isSyncing = state is InspectionSyncLoading;

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: state is InspectionSyncSuccess || isSyncing
                ? null
                : () => context.read<InspectionSyncBloc>().add(
                      InspectionSyncRequested(clientId),
                    ),
            icon: state is InspectionSyncSuccess
                ? const Icon(Icons.cloud_done_outlined)
                : isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(
              state is InspectionSyncSuccess
                  ? 'Sincronizado'
                  : isSyncing
                  ? 'Sincronizando...'
                  : 'Sincronizar agora',
            ),
          ),
        );
      },
    );
  }
}

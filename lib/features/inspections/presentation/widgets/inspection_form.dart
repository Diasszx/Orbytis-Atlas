import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';

final class InspectionForm extends StatelessWidget {
  const InspectionForm({
    super.key,
    required this.inspection,
    this.saveStatus = InspectionSaveStatus.saved,
    this.isSaving = false,
    this.isGettingLocation = false,
    this.errorMessage,
  });

  final Inspection inspection;
  final InspectionSaveStatus saveStatus;
  final bool isSaving;
  final bool isGettingLocation;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersisting = isSaving || saveStatus == InspectionSaveStatus.saving;
    final isBusy = isPersisting || isGettingLocation;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Dados da inspeção',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registre as informações encontradas durante o atendimento.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _SaveStatusIndicator(saveStatus: saveStatus),
        ),
        const SizedBox(height: 24),
        TextFormField(
          initialValue: inspection.observation,
          enabled: !isBusy,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Observação',
            hintText: 'Descreva o que foi encontrado...',
            alignLabelWithHint: true,
          ),
          onChanged: (value) {
            context.read<InspectionBloc>().add(
              InspectionObservationChanged(value),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Foto',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (inspection.photoPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(inspection.photoPath!),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                alignment: Alignment.center,
                child: const Text('Não foi possível carregar a foto.'),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: isBusy
              ? null
              : () => context.read<InspectionBloc>().add(
                    const InspectionPhotoRequested(),
                  ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(
            inspection.photoPath == null
                ? 'Adicionar foto'
                : 'Tirar outra foto',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Localização',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (inspection.latitude != null && inspection.longitude != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localização registrada',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latitude: ${inspection.latitude!.toStringAsFixed(6)}\n'
                        'Longitude: ${inspection.longitude!.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: isBusy
              ? null
              : () => context.read<InspectionBloc>().add(
                    const InspectionLocationRequested(),
                  ),
          icon: isGettingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            isGettingLocation
                ? 'Obtendo localização...'
                : inspection.latitude == null
                ? 'Registrar localização'
                : 'Atualizar localização',
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => context.read<InspectionBloc>().add(
                    const InspectionSaveAndExitRequested(),
                  ),
            icon: isPersisting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isPersisting ? 'Salvando...' : 'Salvar e sair'),
          ),
        ),
      ],
    );
  }
}

final class _SaveStatusIndicator extends StatelessWidget {
  const _SaveStatusIndicator({required this.saveStatus});

  final InspectionSaveStatus saveStatus;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (saveStatus) {
        InspectionSaveStatus.unsaved => const Text(
          'Alterações pendentes',
          key: ValueKey('unsaved'),
        ),
        InspectionSaveStatus.saving => const Row(
          key: ValueKey('saving'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Salvando...'),
          ],
        ),
        InspectionSaveStatus.saved => const Row(
          key: ValueKey('saved'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 18),
            SizedBox(width: 6),
            Text('Salvo'),
          ],
        ),
        InspectionSaveStatus.error => const Row(
          key: ValueKey('error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 18),
            SizedBox(width: 6),
            Text('Erro ao salvar'),
          ],
        ),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_event.dart';

final class InspectionForm extends StatelessWidget {
  const InspectionForm({
    super.key,
    required this.inspection,
    this.isSaving = false,
    this.errorMessage,
  });

  final Inspection inspection;
  final bool isSaving;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        const SizedBox(height: 24),
        TextFormField(
          initialValue: inspection.observation,
          enabled: !isSaving,
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
            onPressed: isSaving
                ? null
                : () {
                    context.read<InspectionBloc>().add(
                      const InspectionDraftSaved(),
                    );
                  },
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isSaving ? 'Salvando...' : 'Salvar rascunho'),
          ),
        ),
      ],
    );
  }
}

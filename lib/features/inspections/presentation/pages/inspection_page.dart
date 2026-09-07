import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';

import '../../../../app/widgets/orbytis_header.dart';
import '../widgets/inspection_form.dart';

final class InspectionPage extends StatelessWidget {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 28;

  const InspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Stack(
            children: [
              const OrbytisHeader(title: 'Inspeção', height: _headerHeight),
              Positioned.fill(
                top: _headerHeight - _panelOverlap,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: BlocBuilder<InspectionBloc, InspectionState>(
                    builder: (context, state) {
                      return switch (state) {
                        InspectionInitial() || InspectionLoading() =>
                          const Center(child: CircularProgressIndicator()),
                        InspectionLoaded(:final inspection) => InspectionForm(
                          inspection: inspection,
                        ),
                        InspectionSaving(:final inspection) => InspectionForm(
                          inspection: inspection,
                          isSaving: true,
                        ),
                        InspectionGettingLocation(:final inspection) =>
                          InspectionForm(
                            inspection: inspection,
                            isGettingLocation: true,
                          ),
                        InspectionSaveFailure(
                          :final inspection,
                          :final message,
                        ) =>
                          InspectionForm(
                            inspection: inspection,
                            errorMessage: message,
                          ),
                        InspectionFailure(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(message, textAlign: TextAlign.center),
                          ),
                        ),
                      };
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

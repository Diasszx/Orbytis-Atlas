import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/orbytis_header.dart';
import '../widgets/inspection_form.dart';

final class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

final class _InspectionPageState extends State<InspectionPage> {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 28;

  bool _showSavedOverlay = false;

  Future<void> _showSaveSuccess() async {
    setState(() => _showSavedOverlay = true);

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      context.pop();
    }
  }

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
                  child: BlocConsumer<InspectionBloc, InspectionState>(
                    listener: (context, state) {
                      if (state is InspectionSaveAndExitSuccess) {
                        _showSaveSuccess();
                      }
                    },
                    builder: (context, state) {
                      return switch (state) {
                        InspectionInitial() || InspectionLoading() =>
                          const Center(child: CircularProgressIndicator()),
                        InspectionLoaded(
                          :final inspection,
                          :final saveStatus,
                          :final saveError,
                        ) =>
                          InspectionForm(
                            inspection: inspection,
                            saveStatus: saveStatus,
                            errorMessage: saveError,
                          ),
                        InspectionSaving(:final inspection) => InspectionForm(
                          inspection: inspection,
                          isSaving: true,
                          saveStatus: InspectionSaveStatus.saving,
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
                            saveStatus: InspectionSaveStatus.error,
                            errorMessage: message,
                          ),
                        InspectionSaveAndExitSuccess(:final inspection) =>
                          InspectionForm(
                            inspection: inspection,
                            saveStatus: InspectionSaveStatus.saved,
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
              if (_showSavedOverlay)
                const Positioned.fill(child: _SaveSuccessOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SaveSuccessOverlay extends StatelessWidget {
  const _SaveSuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: ColoredBox(
        color: AppColors.purple,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Salvo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

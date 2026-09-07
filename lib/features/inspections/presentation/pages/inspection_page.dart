import 'package:flutter/material.dart';

import '../../../../app/widgets/orbytis_header.dart';

final class InspectionPage extends StatelessWidget {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 28;

  const InspectionPage({required this.clientId, super.key});

  final String clientId;

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
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Inspeção iniciada',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os dados da inspeção antes de concluir o atendimento.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
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

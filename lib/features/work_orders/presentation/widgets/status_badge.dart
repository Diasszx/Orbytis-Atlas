import 'package:flutter/material.dart';

final class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, label) = switch (status) {
      'open' => (Icons.radio_button_unchecked, 'Aberta'),
      'in_progress' => (Icons.timelapse, 'Em andamento'),
      'done' => (Icons.check_circle_outline, 'Finalizada'),
      _ => (Icons.help_outline, status),
    };

    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: theme.colorScheme.primaryContainer,
      side: BorderSide.none,
    );
  }
}

import 'package:flutter/material.dart';

final class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final (icon, label, backgroundColor, foregroundColor) = switch (priority) {
      'high' => (
        Icons.priority_high,
        'Prioridade alta',
        Colors.red.shade100,
        Colors.red.shade800,
      ),
      'medium' => (
        Icons.remove,
        'Prioridade média',
        Colors.amber.shade100,
        Colors.amber.shade900,
      ),
      'low' => (
        Icons.keyboard_arrow_down,
        'Prioridade baixa',
        Colors.green.shade100,
        Colors.green.shade800,
      ),
      _ => (
        Icons.info_outline,
        priority,
        Colors.grey.shade200,
        Colors.grey.shade800,
      ),
    };

    return Chip(
      avatar: Icon(icon, size: 18, color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
    );
  }
}

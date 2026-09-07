import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<void> slideTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 800),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation =
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

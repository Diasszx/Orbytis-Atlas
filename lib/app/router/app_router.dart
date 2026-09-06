import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_orders_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';

final class AppRouter {
  AppRouter({required AuthBloc authBloc})
    : router = GoRouter(
        initialLocation: '/login',
        redirect: (context, state) {
          final authState = authBloc.state;

          final isAuthenticated = authState is AuthAuthenticated;
          final isGoingToLogin = state.matchedLocation == '/login';

          if (!isAuthenticated && !isGoingToLogin) {
            return '/login';
          }

          if (isAuthenticated && isGoingToLogin) {
            return 'work-orders';
          }

          return null;
        },
        routes: [
          GoRoute(path: '/', redirect: (_, _) => '/work-orders'),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/work-orders',
            builder: (context, state) => const WorkOrdersPage(),
          ),
        ],
      );

  final GoRouter router;
}

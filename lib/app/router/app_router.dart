import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_orders_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';

final class AppRouter {
  AppRouter();

  final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/work-orders',
        builder: (context, state) => const WorkOrdersPage(),
      ),
    ],
  );
}

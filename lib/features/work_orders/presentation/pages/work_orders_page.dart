import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/orbytis_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/work_orders_bloc.dart';
import '../bloc/work_orders_event.dart';
import '../bloc/work_orders_state.dart';
import '../widgets/work_order_card.dart';

final class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

final class _WorkOrdersPageState extends State<WorkOrdersPage> {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 75;

  @override
  void initState() {
    super.initState();

    context.read<WorkOrdersBloc>().add(const WorkOrdersRequested());
  }

  Future<void> _refresh() async {
    final bloc = context.read<WorkOrdersBloc>();

    final refreshCompleted = bloc.stream.firstWhere(
      (state) =>
          state is WorkOrdersLoaded ||
          state is WorkOrdersEmpty ||
          state is WorkOrdersFailure,
    );

    bloc.add(const WorkOrdersRefreshed());

    await refreshCompleted;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Sair da conta?'),
              content: const Text(
                'Você precisará entrar novamente para acessar sua conta.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Sair'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted || !shouldLogout) {
      return;
    }

    context.read<AuthBloc>().add(const AuthLogoutRequested());
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
              const OrbytisHeader(
                title: 'Ordens de serviço',
                height: _headerHeight,
              ),

              Positioned(
                top: 12,
                right: 16,
                child: IconButton(
                  tooltip: 'Sair',
                  onPressed: _confirmLogout,
                  color: AppColors.white,
                  icon: const Icon(Icons.logout),
                ),
              ),

              // O painel inicia no fim do header. A pequena sobreposição mantém
              // a transição arredondada sem limitar visualmente a lista.
              Positioned.fill(
                top: _headerHeight - _panelOverlap,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BlocBuilder<WorkOrdersBloc, WorkOrdersState>(
                    builder: (context, state) {
                      return switch (state) {
                        WorkOrdersInitial() || WorkOrdersLoading() =>
                          const Center(child: CircularProgressIndicator()),

                        WorkOrdersEmpty() => _EmptyState(onRefresh: _refresh),

                        WorkOrdersFailure(:final message) => _FailureState(
                          message: message,
                          onRetry: () {
                            context.read<WorkOrdersBloc>().add(
                              const WorkOrdersRequested(),
                            );
                          },
                        ),

                        WorkOrdersLoaded(:final workOrders) => RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: workOrders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return WorkOrderCard(
                                workOrder: workOrders[index],
                              );
                            },
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

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.assignment_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma ordem encontrada',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puxe a tela para baixo para tentar novamente.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar as ordens',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/orbytis_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../inspections/presentation/bloc/sync/inspection_queue_cubit.dart';
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
  String? _selectedStatus;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    bloc.add(WorkOrdersRefreshed(status: _selectedStatus));

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
                right: 64,
                child: IconButton(
                  tooltip: 'Histórico de inspeções',
                  onPressed: () => context.push('/inspections'),
                  color: AppColors.white,
                  icon: const Icon(Icons.history),
                ),
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child:
                            BlocConsumer<
                              InspectionQueueCubit,
                              InspectionQueueState
                            >(
                              listener: (context, state) {
                                if (state.message case final String message) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              },
                              builder: (context, state) => SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: state.isSyncing
                                      ? null
                                      : () => context
                                            .read<InspectionQueueCubit>()
                                            .synchronize(),
                                  icon: state.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.sync),
                                  label: Text(
                                    state.isSyncing
                                        ? 'Sincronizando...'
                                        : 'Sincronizar',
                                  ),
                                ),
                              ),
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: DropdownButtonFormField<String>(
                          initialValue: '',
                          decoration: const InputDecoration(
                            labelText: 'Status da OS',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Todas')),
                            DropdownMenuItem(
                              value: 'open',
                              child: Text('Abertas'),
                            ),
                            DropdownMenuItem(
                              value: 'in_progress',
                              child: Text('Em andamento'),
                            ),
                            DropdownMenuItem(
                              value: 'done',
                              child: Text('Finalizadas'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value == '' ? null : value;
                            });
                            context.read<WorkOrdersBloc>().add(
                              WorkOrdersRequested(status: _selectedStatus),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          }),
                          decoration: InputDecoration(
                            labelText: 'Pesquisar por código da OS',
                            hintText: 'Ex.: OS-2026-001',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar pesquisa',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<WorkOrdersBloc, WorkOrdersState>(
                          builder: (context, state) {
                            final matchingOrders = state is WorkOrdersLoaded
                                ? state.workOrders
                                      .where(
                                        (order) => order.code
                                            .toLowerCase()
                                            .contains(_searchQuery),
                                      )
                                      .toList()
                                : null;
                            if (matchingOrders != null &&
                                matchingOrders.isEmpty) {
                              return _EmptyState(
                                onRefresh: _refresh,
                                message: 'Nenhuma OS corresponde ao código pesquisado. Altere a pesquisa ou o filtro de status.',
                              );
                            }
                            return switch (state) {
                              WorkOrdersInitial() ||
                              WorkOrdersLoading() => const Center(
                                child: CircularProgressIndicator(),
                              ),

                              WorkOrdersEmpty() => _EmptyState(
                                onRefresh: _refresh,
                              ),

                              WorkOrdersFailure(:final message) =>
                                _FailureState(
                                  message: message,
                                  onRetry: () {
                                    context.read<WorkOrdersBloc>().add(
                                      WorkOrdersRequested(
                                        status: _selectedStatus,
                                      ),
                                    );
                                  },
                                ),

                              WorkOrdersLoaded() => RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: matchingOrders!.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return WorkOrderCard(
                                      workOrder: matchingOrders[index],
                                    );
                                  },
                                ),
                              ),
                            };
                          },
                        ),
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

final class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onRefresh,
    this.message = 'Puxe a tela para baixo para tentar novamente.',
  });

  final Future<void> Function() onRefresh;
  final String message;

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
            message,
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

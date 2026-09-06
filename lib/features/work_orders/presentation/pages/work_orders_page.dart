import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/orbytis_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

final class WorkOrdersPage extends StatelessWidget {
  const WorkOrdersPage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
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

    if (!context.mounted || !shouldLogout) {
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
        child: Stack(
          children: [
            const OrbytisHeader(title: 'Ordens de serviço'),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                tooltip: 'Sair',
                onPressed: () => _confirmLogout(context),
                color: AppColors.white,
                icon: const Icon(Icons.logout),
              ),
            ),
            Positioned(
              top: 150,
              left: 16,
              right: 16,
              bottom: 0,
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
                    const SizedBox(height: 8),
                    Icon(
                      Icons.assignment_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma ordem carregada',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As ordens de serviço aparecerão aqui '
                      'quando forem carregadas.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

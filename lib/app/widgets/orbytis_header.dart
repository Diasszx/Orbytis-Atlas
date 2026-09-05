import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class OrbytisHeader extends StatelessWidget {
  final String title;

  const OrbytisHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // Fundo com degradê
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.header),
              ),
            ),

            // Círculo decorativo esquerdo
            Positioned(
              top: -80,
              left: -70,
              child: _DecorativeCircle(
                size: 220,
                color: AppColors.lavender.withValues(alpha: 0.16),
              ),
            ),

            // Círculo decorativo direito
            Positioned(
              top: -100,
              right: -60,
              child: _DecorativeCircle(
                size: 210,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            // Outro círculo menor
            Positioned(
              top: 70,
              right: 40,
              child: _DecorativeCircle(
                size: 100,
                color: AppColors.violet.withValues(alpha: 0.15),
              ),
            ),

            // Conteúdo
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glassmorphism Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPrimary.withOpacity(0.12),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Green animated background
class BackgroundMesh extends StatelessWidget {
  const BackgroundMesh({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgPrimary,
            ),
          ),

          // Top Left Green Glow
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPrimary.withOpacity(0.18),
              ),
            ),
          ),

          // Bottom Right Green Glow
          Positioned(
            bottom: -150,
            right: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSecondary.withOpacity(0.15),
              ),
            ),
          ),

          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 120,
              sigmaY: 120,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
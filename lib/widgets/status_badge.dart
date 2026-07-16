import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusKind {
  loading,
  live,
  error,
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final StatusKind kind;
  final String text;

  const StatusBadge({
    super.key,
    required this.kind,
    required this.text,
  });

  Color get _color {
    switch (kind) {
      case StatusKind.loading:
        return AppColors.warning;

      case StatusKind.live:
        return AppColors.success;

      case StatusKind.error:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind == StatusKind.loading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
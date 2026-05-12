import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum AlertType { info, warning, danger, success }

class AlertCard extends StatelessWidget {
  final String    title;
  final String    message;
  final AlertType type;

  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
  });

  Color get _color {
    switch (type) {
      case AlertType.warning: return AppTheme.amber;
      case AlertType.danger:  return AppTheme.rose;
      case AlertType.success: return AppTheme.emerald;
      default:                return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.warning: return Icons.warning_amber_rounded;
      case AlertType.danger:  return Icons.error_outline_rounded;
      case AlertType.success: return Icons.check_circle_outline_rounded;
      default:                return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _color)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

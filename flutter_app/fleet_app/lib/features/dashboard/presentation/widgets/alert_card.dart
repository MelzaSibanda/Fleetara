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
      case AlertType.warning: return AppTheme.warning;
      case AlertType.danger:  return AppTheme.error;
      case AlertType.success: return AppTheme.success;
      default:                return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.warning: return Icons.warning_amber;
      case AlertType.danger:  return Icons.error_outline;
      case AlertType.success: return Icons.check_circle_outline;
      default:                return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: _color)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

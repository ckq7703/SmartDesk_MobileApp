import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class TicketHelper {
  static Color getStatusColor(String? status) {
    switch (status) {
      case '1':
        return AppColors.primary;
      case '2':
        return AppColors.warning;
      case '3':
        return const Color(0xFF8B5CF6);
      case '4':
        return const Color(0xFFFBBF24);
      case '5':
        return AppColors.success;
      case '6':
        return AppColors.textSecondary;
      default:
        return AppColors.textHint;
    }
  }

  static String getStatusText(String? status) {
    switch (status) {
      case '1':
        return 'Mới';
      case '2':
        return 'Đã gán';
      case '3':
        return 'Đang xử lý';
      case '4':
        return 'Chờ';
      case '5':
        return 'Đã giải quyết';
      case '6':
        return 'Đã đóng';
      default:
        return 'Không xác định';
    }
  }

  static Color getPriorityColor(String? priority) {
    switch (priority) {
      case '1':
      case '2':
        return AppColors.success;
      case '3':
        return AppColors.primary;
      case '4':
        return AppColors.warning;
      case '5':
      case '6':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  static String getPriorityText(String? priority) {
    switch (priority) {
      case '1':
        return 'rất thấp';
      case '2':
        return 'thấp';
      case '3':
        return 'bình thường';
      case '4':
        return 'cao';
      case '5':
        return 'rất cao';
      case '6':
        return 'khẩn cấp';
      default:
        return 'không xác định';
    }
  }

  static IconData getTypeIcon(String? type) {
    switch (type) {
      case '1':
        return Icons.bug_report;
      case '2':
        return Icons.help_outline;
      default:
        return Icons.confirmation_number;
    }
  }
}

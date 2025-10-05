import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/ticket_helper.dart';
import '../../domain/models/ticket_model.dart';

class TicketListItem extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const TicketListItem({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case '1':
        return 'Rất thấp';
      case '2':
        return 'Thấp';
      case '3':
        return 'Bình thường';
      case '4':
        return 'Cao';
      case '5':
        return 'Rất cao';
      case '6':
        return 'Khẩn cấp';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${ticket.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TicketHelper.getStatusColor(ticket.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      TicketHelper.getStatusText(ticket.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatRelativeTime(ticket.dateCreation),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (ticket.priority != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: TicketHelper.getPriorityColor(ticket.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPriorityLabel(ticket.priority),
                      style: TextStyle(
                        fontSize: 13,
                        color: TicketHelper.getPriorityColor(ticket.priority),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

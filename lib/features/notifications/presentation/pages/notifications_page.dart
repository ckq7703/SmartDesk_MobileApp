import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../tickets/presentation/pages/ticket_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  final String baseUrl;
  final String sessionToken;

  const NotificationsPage({
    super.key,
    required this.baseUrl,
    required this.sessionToken,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('📄 [NOTIF PAGE] initState called');
    _loadNotifications();

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (_notifications.length <= 1) {
        print('⏳ [NOTIF PAGE] Retry load after delay');
        await _loadNotifications();
      }
    });
  }


  Future<void> _loadNotifications() async {
    print('📄 [NOTIF PAGE] Loading notifications...');
    setState(() => _isLoading = true);

    try {
      final notifications = await NotificationService.getNotifications();
      print('📄 [NOTIF PAGE] Loaded ${notifications.length} notifications');

      if (notifications.isNotEmpty) {
        print('📄 [NOTIF PAGE] First notification:');
        print('   - Title: ${notifications[0]['title']}');
        print('   - Body: ${notifications[0]['body']}');
        print('   - Timestamp: ${notifications[0]['timestamp']}');
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        print('📄 [NOTIF PAGE] UI updated with ${_notifications.length} notifications');
      }
    } catch (e, st) {
      print('❌ [NOTIF PAGE] Error loading notifications: $e');
      print('❌ Stack trace:\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    print('📄 [NOTIF PAGE] Marking notification as read: $notificationId');
    await NotificationService.markAsRead(notificationId);
    await _loadNotifications();
    NotificationService.instance.notifyBadgeUpdate();
  }

  Future<void> _clearAll() async {
    print('📄 [NOTIF PAGE] Clear all requested');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('📄 [NOTIF PAGE] Clearing all notifications...');
      await NotificationService.clearAllNotifications();
      await _loadNotifications();
      NotificationService.instance.notifyBadgeUpdate();
      print('📄 [NOTIF PAGE] All notifications cleared');
    } else {
      print('📄 [NOTIF PAGE] Clear cancelled');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            final notifId = notification['id'] as String;

            return Dismissible(
              key: ValueKey('notif_$notifId'),
              direction: DismissDirection.endToStart, // kéo từ phải sang trái
              background: _buildDismissBackground(),
              confirmDismiss: (direction) async {
                return await _confirmDeleteDialog(notification);
              },
              onDismissed: (direction) async {
                await NotificationService.deleteNotificationById(notifId);
                setState(() {
                  _notifications.removeAt(index);
                });
                await NotificationService.instance.notifyBadgeUpdate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa thông báo')),
                );
              },
              child: _buildNotificationItem(notification),
            );
          },
        ),

      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final timestamp = DateTime.parse(notification['timestamp']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? AppColors.borderColor : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _markAsRead(notification['id']);
            _navigateToTicketDetail(notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'No title',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? 'No body',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.formatRelativeTime(timestamp.toIso8601String()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 60,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có thông báo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thông báo mới sẽ hiển thị tại đây',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete, color: AppColors.error),
          SizedBox(width: 8),
          Text(
            'Xóa',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(Map<String, dynamic> notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thông báo này?'),
        content: Text(
          notification['title'] ?? 'Không có tiêu đề',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _navigateToTicketDetail(Map<String, dynamic> notification) {
    final data = notification['data'] as Map<String, dynamic>?;

    if (data == null || !data.containsKey('ticketid')) {
      print('❌ Không có ticketId trong notification data');
      return;
    }

    final ticketId = data['ticketid'].toString();
    final ticketTitle = notification['title'] ?? data['name'] ?? 'Chi tiết Ticket';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailPage(
          baseUrl: widget.baseUrl,
          sessionToken: widget.sessionToken,
          ticketId: ticketId,
          ticketTitle: ticketTitle,
        ),
      ),
    );
  }



}



class DateFormatter {
  static String formatRelativeTime(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) {
        return 'Vừa xong';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes} phút trước';
      } else if (diff.inDays < 1) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateString.split(' ').first;
    }
  }
}

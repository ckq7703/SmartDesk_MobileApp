import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chính sách bảo mật',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chính sách bảo mật',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật lần cuối: 01/10/2025',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Thông tin chúng tôi thu thập',
              content:
              'Chúng tôi thu thập các thông tin sau:\n\n'
                  '• Thông tin cá nhân: Họ tên, địa chỉ email, số điện thoại\n'
                  '• Thông tin tài khoản: Tên đăng nhập, mật khẩu\n'
                  '• Thông tin sử dụng: Lịch sử tạo ticket, phản hồi\n'
                  '• Thông tin thiết bị: Loại thiết bị, hệ điều hành, IP address',
            ),
            _buildSection(
              title: '2. Mục đích sử dụng thông tin',
              content:
              'Thông tin của bạn được sử dụng để:\n\n'
                  '• Cung cấp và cải thiện dịch vụ\n'
                  '• Xử lý các yêu cầu hỗ trợ\n'
                  '• Gửi thông báo về tình trạng ticket\n'
                  '• Đảm bảo an ninh tài khoản\n'
                  '• Phân tích và cải thiện trải nghiệm người dùng',
            ),
            _buildSection(
              title: '3. Bảo mật thông tin',
              content:
              'Chúng tôi cam kết bảo vệ thông tin của bạn bằng:\n\n'
                  '• Mã hóa dữ liệu khi truyền tải\n'
                  '• Lưu trữ an toàn trên máy chủ được bảo mật\n'
                  '• Kiểm soát truy cập nghiêm ngặt\n'
                  '• Cập nhật các biện pháp bảo mật thường xuyên',
            ),
            _buildSection(
              title: '4. Chia sẻ thông tin',
              content:
              'Chúng tôi không bán, cho thuê hoặc chia sẻ thông tin cá nhân của bạn với bên thứ ba, trừ khi:\n\n'
                  '• Có sự đồng ý của bạn\n'
                  '• Theo yêu cầu pháp luật\n'
                  '• Bảo vệ quyền lợi của chúng tôi\n'
                  '• Với các đối tác dịch vụ được ủy quyền',
            ),
            _buildSection(
              title: '5. Quyền của người dùng',
              content:
              'Bạn có quyền:\n\n'
                  '• Truy cập và cập nhật thông tin cá nhân\n'
                  '• Yêu cầu xóa tài khoản và dữ liệu\n'
                  '• Từ chối nhận thông báo marketing\n'
                  '• Khiếu nại về việc xử lý dữ liệu',
            ),
            _buildSection(
              title: '6. Liên hệ',
              content:
              'Nếu có thắc mắc về chính sách bảo mật, vui lòng liên hệ:\n\n'
                  'Email: support@smartpro.vn\n'
                  'Điện thoại: (028) 39 306 767',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chính sách này có thể được cập nhật theo thời gian. Vui lòng kiểm tra thường xuyên.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
